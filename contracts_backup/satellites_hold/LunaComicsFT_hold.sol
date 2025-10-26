// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

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

contract LunaComicsFT is
    Initializable,
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    ERC20PausableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for address;

    // ===== Ruoli =====
    bytes32 public constant MINTER_ROLE  = keccak256("MINTER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE  = keccak256("PAUSER_ROLE");

    // ===== Orchestrator & NFT collegati (solo puntatori) =====
    ISolidaryOrchestratorReadableFT public orchestrator;
    address public oceanMangaNFT; // ex mareaMangaNFT

    // ===== Costanti narrative =====
    string  public constant SATELLITE_NAME = "LunaComicsFT";
    uint256 public constant LUNAR_MASS     = 73420000000000000000000000; // 7.342e22 (senza floating) a solo scopo illustrativo

    // ===== Stato “fisico” =====
    uint256 public lunarGravity;       // scala 1e18
    uint256 public tidalForce;         // scala 1e18 (o unità coerenti con uso)
    uint256 public lastGravityUpdate;  // timestamp
    uint256 public peakGravity;        // massimo storico di lunarGravity
    uint256 public totalLunarValue;    // totalSupply() * lunarGravity / 1e18

    // ===== Farming =====
    struct FTFarm {
        uint256 plantedTokens;
        uint256 plantTime;
        uint256 harvestTime;
        uint256 yieldMultiplier; // 1e18 = 1.0x
        bool    isHarvested;
        uint256 farmId;
    }

    // Per utente: array di farm (come nel tuo sorgente)
    mapping(address => FTFarm[]) public userFarms;
    // Farm globali indirizzate per id
    mapping(uint256 => address) public farmOwner;
    mapping(uint256 => FTFarm)  public farms;

    uint256 public totalFarms;
    uint256 public totalTokensPlanted;
    uint256 public totalHarvested;

    // ===== Gravity snapshots / analytics =====
    struct GravitySnapshot {
        uint256 timestamp;
        uint256 lunarGravity;
        uint256 tidalForce;
        uint256 totalLunarValue;
    }
    GravitySnapshot[] private gravityHistory;

    // ===== CID storage =====
    // Dati piantagione e raccolto per farm
    mapping(uint256 => string) public farmDataCIDs;            // farmId -> CID (plant data)
    mapping(address => string[]) public userYieldHistoryCIDs;  // per utente, lista CID (harvest & co.)
    uint256 public totalYieldCalculations;

    // Ulteriori bucket CID (già introdotti nella versione precedente)
    mapping(uint256 => string) public gravityCIDs;  // indice -> CID (registrazione manuale)
    mapping(uint256 => string) public auctionCIDs;  // indice -> CID (registrazione manuale)
    string public tokenomicsCID;                    // documento generale
    uint256 public gravityCIDCount;
    uint256 public auctionCIDCount;

    // ===== Eventi =====
    event OrchestratorUpdated(address indexed orchestrator);
    event OceanMangaNFTUpdated(address indexed nft);
    event TokensPlanted(address indexed farmer, uint256 amount, uint256 farmId, uint256 harvestTime);
    event TokensHarvested(address indexed farmer, uint256 farmId, uint256 planted, uint256 harvested);
    event GravitationalShift(uint256 newGravity, uint256 newTidalForce, uint256 totalValue);
    event GravitySnapshotTaken(uint256 timestamp, uint256 lunarGravity, uint256 tidalForce, uint256 totalValue);
    event GravityCIDRegistered(uint256 indexed index, string cid);
    event AuctionCIDRegistered(uint256 indexed index, string cid);
    event TokenomicsCIDSet(string cid);
    event FarmDataStored(uint256 indexed farmId, string cid, uint256 amount, uint256 durationDays);
    event HarvestDataStored(uint256 indexed farmId, string cid, uint256 planted, uint256 harvested);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    /**
     * @param admin         address con DEFAULT_ADMIN_ROLE
     * @param name_         "LunaComics"
     * @param symbol_       "LUNA"
     * @param initialSupply supply iniziale (mintata a treasury)
     * @param treasury      destinatario della supply iniziale
     */
    function initialize(
        address admin,
        string calldata name_,
        string calldata symbol_,
        uint256 initialSupply,
        address treasury
    ) public initializer {
        __ERC20_init(name_, symbol_);
        __ERC20Permit_init(name_);
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

    // ========= Admin / Config =========

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

    function pause() external onlyRole(PAUSER_ROLE)   { _pause(); }
    function unpause() external onlyRole(PAUSER_ROLE) { _unpause(); }

    // ========= Mint / Burn di base =========

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
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

    // ========= Farming =========

    /**
     * Pianta token per una durata (7..30 giorni), bruciandoli e creando una farm.
     * Raccoglierai più tardi in base al multiplier calcolato.
     */
    function plantTokens(uint256 amount, uint256 durationDays) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(durationDays >= 7 && durationDays <= 30, "Duration 7-30 days");

        _burn(msg.sender, amount);

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

    function _markUserFarmHarvested(address user, uint256 farmId) internal {
        FTFarm[] storage arr = userFarms[user];
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i].farmId == farmId) {
                arr[i].isHarvested = true;
                break;
            }
        }
    }

    // ========= Gravità / maree =========

    /** Applicazione delle maree dal contratto NFT (OceanMangaNFT) */
    function applyTidalForce(uint256 nftMass, uint256 ftLinked) external whenNotPaused {
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

    function _storeFarmData(uint256 farmId, uint256 amount, uint256 durationDays) internal {
        // Crea un “payload” e genera un CID simulato (in prod: fai upload off-chain e poi registra CID reale)
        bytes32 h = keccak256(abi.encodePacked(
            "plant:", farmId, msg.sender, amount, durationDays, block.timestamp, lunarGravity, tidalForce
        ));
        string memory cid = _simulatedCID(h);
        farmDataCIDs[farmId] = cid;
        userYieldHistoryCIDs[msg.sender].push(cid);
        emit FarmDataStored(farmId, cid, amount, durationDays);
    }

    function _storeHarvestData(uint256 farmId, uint256 planted, uint256 harvested) internal {
        bytes32 h = keccak256(abi.encodePacked(
            "harvest:", farmId, planted, harvested, lunarGravity, block.timestamp
        ));
        string memory cid = _simulatedCID(h);
        userYieldHistoryCIDs[msg.sender].push(cid);
        totalYieldCalculations++;
        emit HarvestDataStored(farmId, cid, planted, harvested);
    }

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

    // ========= Helpers =========

    function _simulatedCID(bytes32 h) internal pure returns (string memory) {
        // Pseudo-CID leggibile (prefisso fittizio)
        return string(abi.encodePacked("simulated:ipfs:", StringsUpgradeable.toHexString(uint256(h), 32)));
    }

    // Override richiesto per Pausable
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20Upgradeable, ERC20PausableUpgradeable)
    {
        super._update(from, to, value);
    }
}
