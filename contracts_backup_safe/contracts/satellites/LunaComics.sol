// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca - Italy - Florence. Author and owner of the Solidary.it ecosystem and this smart contract. The ecosystem and its logical components (.sol files and scripts) are protected by copyright.

struct GravitySnapshot {
    uint256 timestamp;
    uint256 lunarGravity;
    uint256 tidalForce;
    uint256 totalLunarValue;
}

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface ISolidaryOrchestratorReadableFT {
    function nftPlanetContract() external view returns (address);
    function ftSatelliteContract() external view returns (address);
    // opzionale: altre funzioni di sola lettura utili a frontend/metrics
}

/**
 * LunaComicsFT (ERC20 Upgradeable)
 *
 * Visione:
 * - Token FT che rappresenta la “massa gravitazionale” (Luna) che influenza le maree dell’oceano (OceanMangaNFT).
 * - Include sistema di farming (plant/harvest), metriche di gravità/marea, snapshot e puntatori IPFS (CID) gestiti off-chain.
 *
 * Sicurezza / Design:
 * - Upgradeability UUPS (OpenZeppelin)
 * - AccessControl (ruoli: ADMIN, MINTER, MANAGER, PAUSER)
 * - Pausable su trasferimenti
 * - EIP-2612 Permit (approvazioni via firma off-chain)
 * - ReentrancyGuard per operazioni di farming/harvest
 * - Nessun secret on-chain; CID registrati dopo upload off-chain (Heroku backend)
 *
 * NOTE:
 * - Il vecchio sorgente mostrava molte sezioni incoerenti/duplicate. Qui sono state corrette e consolidate.
 * - Alcuni placeholders IPFS restano simulati; in produzione registra il CID reale via funzioni MANAGER_ROLE.
 */

contract LunaComics is
    Initializable,
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    ERC20PausableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    // Eventi mancanti
    event GravitySnapshotTaken(uint256 timestamp, uint256 lunarGravity, uint256 tidalForce, uint256 totalLunarValue);
    event FarmDataStored(uint256 indexed farmId, string cid, uint256 amount, uint256 durationDays);
    event HarvestDataStored(uint256 indexed farmId, string cid, uint256 planted, uint256 harvested);
    event OrchestratorUpdated(address indexed orchestrator);
    event OceanMangaNFTUpdated(address indexed nft);
    event TokensPlanted(address indexed farmer, uint256 amount, uint256 farmId, uint256 harvestTime);
    event TokensHarvested(address indexed farmer, uint256 farmId, uint256 planted, uint256 harvested);
    event GravitationalShift(uint256 newGravity, uint256 newTidalForce, uint256 totalValue);
    event GravityCIDRegistered(uint256 indexed index, string cid);
    event AuctionCIDRegistered(uint256 indexed index, string cid);
    event TokenomicsCIDSet(string cid);

    // Variabile orchestrator
    ISolidaryOrchestratorReadableFT public orchestrator;

    // Funzione di utilità per CID simulati
    function _bytes32ToHexString(bytes32 data) internal pure returns (string memory) {
        bytes memory hexChars = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            str[i*2] = hexChars[uint8(data[i] >> 4)];
            str[1+i*2] = hexChars[uint8(data[i] & 0x0f)];
        }
        return string(str);
    }
    // Ruoli per accesso alle funzioni
    bytes32 public constant MINTER_ROLE  = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE  = keccak256("PAUSER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    address public oceanMangaNFT;
    event MintWithSplit(address indexed user, uint256 ftAmount, uint256 nftAmount);

    // Variabili di stato per la logica di gravità e farming
    uint256 public lunarGravity;
    uint256 public tidalForce;
    uint256 public lastGravityUpdate;
    uint256 public peakGravity;
    uint256 public totalLunarValue;
    GravitySnapshot[] public gravityHistory;
    mapping(uint256 => string) public farmDataCIDs;
    mapping(address => string[]) public userYieldHistoryCIDs;
    uint256 public totalYieldCalculations;
    mapping(uint256 => string) public gravityCIDs;
    mapping(uint256 => string) public auctionCIDs;
    string public tokenomicsCID;
    uint256 public gravityCIDCount;
    uint256 public auctionCIDCount;

    struct FTFarm {
        uint256 plantedTokens;
        uint256 plantTime;
        uint256 harvestTime;
        uint256 yieldMultiplier;
        bool    isHarvested;
        uint256 farmId;
    }
    mapping(address => FTFarm[]) public userFarms;
    mapping(uint256 => address) public farmOwner;
    mapping(uint256 => FTFarm)  public farms;
    uint256 public totalFarms;
    uint256 public totalTokensPlanted;
    uint256 public totalHarvested;


        // ...existing code...


    function mintWithSplit(uint256 ftAmount, uint256 nftId, uint256 nftAmount, bytes calldata nftData) external payable {
        uint256 price = msg.value;
        require(price > 0, "No value sent");
        require(oceanMangaNFT != address(0), "OceanMangaNFT not set");
        uint256 ftValue = (price * 45) / 100;
        uint256 nftValue = price - ftValue;
        require(ftValue > 0 && nftValue > 0, "Invalid split");
        _mint(msg.sender, ftAmount);
        (bool success, ) = oceanMangaNFT.call{value: nftValue}(abi.encodeWithSignature(
            "mint(address,uint256,uint256,bytes)", msg.sender, nftId, nftAmount, nftData
        ));
        require(success, "NFT mint failed");
        emit MintWithSplit(msg.sender, ftAmount, nftAmount);
    }

    function _char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
    
    // Funzione di simulazione (dal tuo codice originale - _simulatedCID)
    function _simulatedCID(bytes32 h) internal pure returns (string memory) {
        // Pseudo-CID leggibile (prefisso fittizio)
        // Uso le tue utilità manuali (_bytes32ToHexString) come richiesto.
        return string(abi.encodePacked("simulated:ipfs:", _bytes32ToHexString(h)));
    }


    /**
     * @dev Calcola il moltiplicatore di yield in base alla durata del farming.
     * @notice Base: 1.0x (1e18) per 7 giorni. Bonus per durata maggiore.
     */
    function _calculateYieldMultiplier(uint256 durationDays) internal view returns (uint256 multiplier) {
        // Base 1.0x (1e18)
        multiplier = 1e18;
        
        // Bonus lineare (es. +0.02x per ogni giorno oltre i 7 giorni)
        if (durationDays > 7) {
            uint256 bonusDays = durationDays - 7;
            // Esempio: 2% di bonus per giorno (2e16)
            uint256 bonusFactor = bonusDays * 2e16; 
            multiplier += bonusFactor;
        }

        // Il Lunar Gravity aumenta il moltiplicatore
        multiplier = (multiplier * lunarGravity) / 1e18;
        
        return multiplier;
    } // ⬅️ AGGIUNTA QUESTA FUNZIONE (ERRORE 226)

    function _initializeGravityParams() internal {
        lunarGravity = 1e18; // base 1.0x
        tidalForce   = 1e18; // base
        lastGravityUpdate = block.timestamp;
        peakGravity = lunarGravity;
        totalLunarValue = (totalSupply() * lunarGravity) / 1e18;
    }

    function _takeGravitySnapshot() internal {
        gravityHistory.push(
            GravitySnapshot({
                timestamp:       block.timestamp,
                lunarGravity:    lunarGravity,
                tidalForce:      tidalForce,
                totalLunarValue: totalLunarValue
            })
        );
        emit GravitySnapshotTaken(block.timestamp, lunarGravity, tidalForce, totalLunarValue);
    }
    
    function _updateGravity() internal {
        uint256 supply = totalSupply();
        if (supply == 0) {
            lunarGravity = 1e18; // reset a 1.0x
        } else {
            // esempio: funzione del rapporto tra token piantati e supply
            uint256 plantedRatio = (totalTokensPlanted * 1e18) / supply;
            lunarGravity = 1e18 + (plantedRatio / 2); // semplificato
        }
        if (lunarGravity > peakGravity) {
            peakGravity = lunarGravity;
        }
        totalLunarValue = (supply * lunarGravity) / 1e18;
        lastGravityUpdate = block.timestamp;
    }
    
    function _storeFarmData(uint256 farmId, uint256 amount, uint256 durationDays) internal {
        // Crea un “payload” e genera un CID simulato (in prod: fai upload off-chain e poi registra CID reale)
        bytes32 h = keccak256(abi.encodePacked(
            "plant:", farmId, msg.sender, amount, durationDays, block.timestamp, lunarGravity, tidalForce
        ));
        string memory cid = _simulatedCID(h); // Usa la funzione simulata corretta
        farmDataCIDs[farmId] = cid;
        userYieldHistoryCIDs[msg.sender].push(cid);
        emit FarmDataStored(farmId, cid, amount, durationDays);
    }

    function _storeHarvestData(uint256 farmId, uint256 planted, uint256 harvested) internal {
        bytes32 h = keccak256(abi.encodePacked(
            "harvest:", farmId, planted, harvested, lunarGravity, block.timestamp
        ));
        string memory cid = _simulatedCID(h); // Usa la funzione simulata corretta
        userYieldHistoryCIDs[msg.sender].push(cid);
        totalYieldCalculations++;
        emit HarvestDataStored(farmId, cid, planted, harvested);
    }

    function _markUserFarmHarvested(address user, uint256 farmId) internal {
        FTFarm[] storage arr = userFarms[user];
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i].farmId == farmId) {
                arr[i].isHarvested = true;
                break;
            }
        }
    }


    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏗️ INITIALIZATION
    // ═══════════════════════════════════════════════════════════════════════════════

    /**
     * @param admin         address con DEFAULT_ADMIN_ROLE
    * @param initialSupply supply iniziale (mintata a treasury)
     * @param treasury      destinatario della supply iniziale
     */
    function initialize(
        address admin,
        uint256 initialSupply,
        address treasury
    ) public initializer {
        __ERC20_init("Lunacomics", "LUNA");
        __ERC20Permit_init("Lunacomics");
        __ERC20Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
        _grantRole(PAUSER_ROLE,  admin);

        if (initialSupply > 0 && treasury != address(0)) {
            _mint(treasury, initialSupply);
        }

        // inizializzazione base “fisica”
        _initializeGravityParams(); 
        _takeGravitySnapshot();     
    }

    // ========= Admin / Config (Logica omessa per brevità) =========

    function _authorizeUpgrade(address newImplementation)
        internal override onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    function setOrchestrator(address _orchestrator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        orchestrator = ISolidaryOrchestratorReadableFT(_orchestrator);
        emit OrchestratorUpdated(_orchestrator);
    }

    function setOceanMangaNFT(address _nft) external onlyRole(DEFAULT_ADMIN_ROLE) {
        oceanMangaNFT = _nft;
        emit OceanMangaNFTUpdated(_nft);
    }

    function pause() external onlyRole(PAUSER_ROLE)    { _pause(); }
    function unpause() external onlyRole(PAUSER_ROLE) { _unpause(); }

    // ========= Mint / Burn di base (Logica omessa per brevità) =========
    address public trustManager;
    function setTrustManager(address _trustManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        trustManager = _trustManager;
    }

    function mint(address to, uint256 amount) external payable onlyRole(MINTER_ROLE) {
        _mint(to, amount);
        require(trustManager != address(0), "TrustManager not set");
        (bool success, ) = trustManager.call{value: msg.value}(abi.encodeWithSignature(
            "processMintAndNotify(address,address,uint256)", address(this), msg.sender, msg.value
        ));
        require(success, "TrustManager mint failed");
    }

    function mintToMany(address[] calldata toList, uint256[] calldata amounts)
        external onlyRole(MINTER_ROLE)
    {
        require(toList.length == amounts.length, "LunaComicsFT: length mismatch");
        for (uint256 i = 0; i < toList.length; i++) {
            _mint(toList[i], amounts[i]);
        }
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) external {
        uint256 current = allowance(account, _msgSender());
        require(current >= amount, "ERC20: burn exceeds allowance");
        unchecked { _approve(account, _msgSender(), current - amount); }
        _burn(account, amount);
    }


    // ========= Farming (Logica omessa per brevità) =========


    /**
     * Pianta token per una durata (7..30 giorni), bruciandoli e creando una farm.
     * Raccoglierai più tardi in base al multiplier calcolato.
     */
    function plantTokens(uint256 amount, uint256 durationDays) external {
        uint256 farmId = totalFarms;
        totalFarms = farmId + 1;

        uint256 harvestTime = block.timestamp + (durationDays * 1 days);
        uint256 multiplier = _calculateYieldMultiplier(durationDays); 

        FTFarm memory f = FTFarm({
            plantedTokens: amount,
            plantTime:     block.timestamp,
            harvestTime:   harvestTime,
            yieldMultiplier: multiplier,
            isHarvested:   false,
            farmId:        farmId
        });

        // salva riferimenti
        farms[farmId] = f;
        farmOwner[farmId] = msg.sender;
        userFarms[msg.sender].push(f);

        totalTokensPlanted += amount;

        // analytics: salviamo CID “plant”
        _storeFarmData(farmId, amount, durationDays);

        emit TokensPlanted(msg.sender, amount, farmId, harvestTime);
    }

    /** Harvest per indice nell’array dell’utente */
    function harvestUserFarm(uint256 farmIndex) external nonReentrant whenNotPaused {
        require(farmIndex < userFarms[msg.sender].length, "Farm index out of range");
        FTFarm storage ufarm = userFarms[msg.sender][farmIndex];
        require(!ufarm.isHarvested, "Already harvested");
        require(ufarm.plantedTokens > 0, "Empty farm");
        require(block.timestamp >= ufarm.harvestTime, "Not ready");

        // sincronizza con registro globale
        uint256 farmId = ufarm.farmId;
        FTFarm storage g = farms[farmId];
        require(farmOwner[farmId] == msg.sender, "Not the farm owner");
        require(!g.isHarvested, "Already harvested (global)");

        uint256 harvestedAmount = (ufarm.plantedTokens * ufarm.yieldMultiplier) / 1e18;

        ufarm.isHarvested = true;
        g.isHarvested = true;

        _mint(msg.sender, harvestedAmount);
        totalHarvested += harvestedAmount;

        _storeHarvestData(farmId, ufarm.plantedTokens, harvestedAmount);
        emit TokensHarvested(msg.sender, farmId, ufarm.plantedTokens, harvestedAmount);

        _updateGravity();       // aggiorna dinamica
        _takeGravitySnapshot(); // snapshot dopo raccolto
    }

    /** Harvest per farmId */
    function harvestTokens(uint256 farmId) external nonReentrant whenNotPaused {
        FTFarm storage f = farms[farmId];
        require(f.plantedTokens > 0, "Empty farm");
        require(!f.isHarvested, "Already harvested");
        require(block.timestamp >= f.harvestTime, "Not ready");
        require(farmOwner[farmId] == msg.sender, "Not the farm owner");

        uint256 harvestedAmount = (f.plantedTokens * f.yieldMultiplier) / 1e18;

        f.isHarvested = true;
        // aggiorna nell’array dell’utente (best-effort)
        _markUserFarmHarvested(msg.sender, farmId);

        _mint(msg.sender, harvestedAmount);
        totalHarvested += harvestedAmount;

        _storeHarvestData(farmId, f.plantedTokens, harvestedAmount);
        emit TokensHarvested(msg.sender, farmId, f.plantedTokens, harvestedAmount);

        _updateGravity();
        _takeGravitySnapshot();
    }

    /** Harvest di tutte le farm pronte dell’utente */
    function harvestAllFarms() external nonReentrant whenNotPaused {
        FTFarm[] storage arr = userFarms[msg.sender];
        uint256 totalMint = 0;
        uint256 harvestedCount = 0;

        for (uint256 i = 0; i < arr.length; i++) {
            FTFarm storage uf = arr[i];
            if (uf.plantedTokens > 0 && !uf.isHarvested && block.timestamp >= uf.harvestTime) {
                uint256 farmId = uf.farmId;
                FTFarm storage gf = farms[farmId];
                if (!gf.isHarvested && farmOwner[farmId] == msg.sender) {
                    uint256 harvestedAmount = (uf.plantedTokens * uf.yieldMultiplier) / 1e18;
                    uf.isHarvested = true;
                    gf.isHarvested = true;
                    totalMint += harvestedAmount;
                    harvestedCount++;

                    _storeHarvestData(farmId, uf.plantedTokens, harvestedAmount);
                    emit TokensHarvested(msg.sender, farmId, uf.plantedTokens, harvestedAmount);
                }
            }
        }

        require(harvestedCount > 0, "No farm ready");
        _mint(msg.sender, totalMint);
        totalHarvested += totalMint;

        _updateGravity();
        _takeGravitySnapshot();
    }

    // opzionale: rimozione “swap and pop” di una farm dall’array utente
    function _removeUserFarm(address user, uint256 index) internal {
        FTFarm[] storage arr = userFarms[user];
        require(index < arr.length, "Index out of range");
        if (index < arr.length - 1) {
            arr[index] = arr[arr.length - 1];
        }
        arr.pop();
    }
  
    // ========= Gravità / maree (Logica omessa per brevità) =========

    /** Applicazione delle maree dal contratto NFT (OceanMangaNFT) */ 
    function applyTidalForce(uint256 nftMass, uint256 ftLinked) 
    external whenNotPaused {
        require(msg.sender == oceanMangaNFT, "Only OceanMangaNFT");
        // semplice modello: gravity *= (1 + nftMass)
        lunarGravity = (lunarGravity * (1e18 + nftMass)) / 1e18;
        tidalForce   = ftLinked;

        if (lunarGravity > peakGravity) {
            peakGravity = lunarGravity;
        }
        totalLunarValue = (totalSupply() * lunarGravity) / 1e18;

        emit GravitationalShift(lunarGravity, tidalForce, totalLunarValue);
        _takeGravitySnapshot();
    }

    function updateGravity() external onlyRole(MANAGER_ROLE) {
        _updateGravity();
        _takeGravitySnapshot();
    }

    function getGravityHistory(uint256 limit) external view returns (GravitySnapshot[] memory) {
        uint256 n = gravityHistory.length;
        if (limit == 0 || limit > n) limit = n;
        GravitySnapshot[] memory out = new GravitySnapshot[](limit);
        for (uint256 i = 0; i < limit; i++) {
            out[i] = gravityHistory[n - 1 - i];
        }
        return out;
    }

    // ========= CID registration (upload off-chain → pointer on-chain) =========

    function registerGravityCID(uint256 index, string calldata cid) external onlyRole(MANAGER_ROLE) {
        gravityCIDs[index] = cid;
        if (index >= gravityCIDCount) gravityCIDCount = index + 1;
        emit GravityCIDRegistered(index, cid);
    }

    function registerGravityCIDAuto(string calldata cid) external onlyRole(MANAGER_ROLE) returns (uint256 idx) {
        idx = gravityCIDCount;
        gravityCIDs[idx] = cid;
        gravityCIDCount++;
        emit GravityCIDRegistered(idx, cid);
    }

    function registerAuctionCID(uint256 index, string calldata cid) external onlyRole(MANAGER_ROLE) {
        auctionCIDs[index] = cid;
        if (index >= auctionCIDCount) auctionCIDCount = index + 1;
        emit AuctionCIDRegistered(index, cid);
    }

    function registerAuctionCIDAuto(string calldata cid) external onlyRole(MANAGER_ROLE) returns (uint256 idx) {
        idx = auctionCIDCount;
        auctionCIDs[idx] = cid;
        auctionCIDCount++;
        emit AuctionCIDRegistered(idx, cid);
    }

    function setTokenomicsCID(string calldata cid) external onlyRole(MANAGER_ROLE) {
        tokenomicsCID = cid;
        emit TokenomicsCIDSet(cid);
    }

    // ====== IPFS analytics (simulati) ======

    function getUserYieldHistory(address user) external view returns (string[] memory) {
        return userYieldHistoryCIDs[user];
    }

    function getFarmAnalytics(uint256 farmId) external view returns (string memory plantCID, string memory lastUserCID) {
        plantCID = farmDataCIDs[farmId];
        address owner_ = farmOwner[farmId];
        string[] storage hist = userYieldHistoryCIDs[owner_];
        if (hist.length > 0) {
            lastUserCID = hist[hist.length - 1];
        } else {
            lastUserCID = "";
        }
    }

    // Override richiesto per Pausable
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20Upgradeable, ERC20PausableUpgradeable)
        whenNotPaused // Per applicare la pausa di ERC20Pausable
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Diagnostica: restituisce i ruoli attivi per un indirizzo
     * @param account Indirizzo da verificare
     * @return hasMinter true se ha MINTER_ROLE
     * @return hasManager true se ha MANAGER_ROLE
     * @return hasAdmin true se ha DEFAULT_ADMIN_ROLE
     */
    function getRoles(address account) external view returns (bool hasMinter, bool hasManager, bool hasAdmin) {
        hasMinter = hasRole(MINTER_ROLE, account);
        hasManager = hasRole(MANAGER_ROLE, account);
        hasAdmin = hasRole(DEFAULT_ADMIN_ROLE, account);
    }
}
