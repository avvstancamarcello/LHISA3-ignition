// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/**
 * Orchestrator.sol
 *
 * Punto di verità e di collegamento tra:
 * - OceanMangaNFT (ERC-1155): "nftPlanetContract"
 * - LunaComicsFT  (ERC-20):  "ftSatelliteContract"
 * - SolidaryMetrics (lettura di metriche aggregate)
 *
 * Espone le API attese da SolidaryMetrics:
 * - nftPlanetContract()
 * - ftSatelliteContract()
 * - totalQuantumLinks()
 * - totalStellarValue()
 * - getStorageConfig()
 *
 * NOTE importanti:
 * - Evita di memorizzare segreti on-chain in produzione.
 *   Le variabili nftStorageAPIKey / pinataJWT sono da intendersi come "placeholder/puntatori".
 *   Per l'upload reale usa backend (es. Heroku) e poi registra i CID nei contratti.
 */

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// --- Interfacce minime per interazione ---

interface ILunaComicsFTReadable {
    function totalSupply() external view returns (uint256);
    function lunarGravity() external view returns (uint256);
}

interface IOceanMangaNFTReadable {
    // placeholder per eventuali funzioni future di sola lettura
}

contract Orchestrator is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    // Ruoli
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE"); // per configurazioni
    bytes32 public constant MANAGER_ROLE  = keccak256("MANAGER_ROLE");  // per registri operativi (quantum link)

    // Moduli collegati
    address private _nftPlanetContract;   // OceanMangaNFT
    address private _ftSatelliteContract; // LunaComicsFT
    address private _metricsContract;     // SolidaryMetrics (opzionale, solo tracking)

    // Configurazione storage (placeholder: NON usare segreti on-chain in produzione)
    string private nftStorageAPIKey; // ⚠️ non inserire segreti reali on-chain
    string private pinataJWT;        // ⚠️ non inserire segreti reali on-chain

    // Quantum Links registry (minimale)
    struct QuantumLink {
        address user;
        uint256 tokenId;
        uint256 ftAmount;    // quantità FT associata a questo link
        uint256 timestamp;
    }

    QuantumLink[] private _quantumLinks;  // elenco append-only
    uint256 private _totalStellarValueOverride; // opzionale: override manuale

    // Eventi
    event NFTPlanetLinked(address indexed nft);
    event FTSatelliteLinked(address indexed ft);
    event MetricsLinked(address indexed metrics);
    event StorageConfigured(bool setNftStorageKey, bool setPinataJwt);
    event QuantumLinkRecorded(uint256 indexed linkId, address indexed user, uint256 tokenId, uint256 ftAmount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @param admin admin principale (DEFAULT_ADMIN_ROLE & GOVERNOR_ROLE)
     * @param nftContract indirizzo OceanMangaNFT (può essere address(0) e settato dopo)
     * @param ftContract  indirizzo LunaComicsFT  (può essere address(0) e settato dopo)
     */
    function initialize(address admin, address nftContract, address ftContract) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(GOVERNOR_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);

        if (nftContract != address(0)) {
            _nftPlanetContract = nftContract;
            emit NFTPlanetLinked(nftContract);
        }
        if (ftContract != address(0)) {
            _ftSatelliteContract = ftContract;
            emit FTSatelliteLinked(ftContract);
        }
    }

    // ========= Upgradeability auth =========
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // ========= Setup collegamenti =========

    function linkNFTPlanet(address nftContract) external onlyRole(GOVERNOR_ROLE) {
        _nftPlanetContract = nftContract;
        emit NFTPlanetLinked(nftContract);
    }

    function linkFTSatellite(address ftContract) external onlyRole(GOVERNOR_ROLE) {
        _ftSatelliteContract = ftContract;
        emit FTSatelliteLinked(ftContract);
    }

    function linkMetrics(address metricsContract) external onlyRole(GOVERNOR_ROLE) {
        _metricsContract = metricsContract;
        emit MetricsLinked(metricsContract);
    }

    // ========= API lette da SolidaryMetrics =========

    function nftPlanetContract() external view returns (address) {
        return _nftPlanetContract;
    }

    function ftSatelliteContract() external view returns (address) {
        return _ftSatelliteContract;
    }

    /**
     * totalQuantumLinks
     * - ritorna il numero totale di legami NFT↔FT registrati
     * - i legami sono registrati tramite `recordQuantumLink(...)`
     */
    function totalQuantumLinks() external view returns (uint256) {
        return _quantumLinks.length;
    }

    /**
     * totalStellarValue
     * - se è collegato il FT (LunaComicsFT), calcola: totalSupply * lunarGravity / 1e18
     * - se FT non collegato, o se vuoi usare un override manuale, ritorna override se > 0
     */
    function totalStellarValue() external view returns (uint256) {
        if (_totalStellarValueOverride > 0) {
            return _totalStellarValueOverride;
        }
        address ft = _ftSatelliteContract;
        if (ft == address(0)) return 0;

        uint256 supply = ILunaComicsFTReadable(ft).totalSupply();
        uint256 gravity = ILunaComicsFTReadable(ft).lunarGravity(); // getter pubblico
        // safe: se gravity == 0, torna 0
        if (gravity == 0) return 0;
        return (supply * gravity) / 1e18;
    }

    /**
     * getStorageConfig
     * - restituisce le stringhe di configurazione storage (⚠️ placeholders: non usare secrets reali on-chain)
     * - manteniamo la firma per compatibilità con SolidaryMetrics
     */
    function getStorageConfig() external view returns (string memory, string memory) {
        return (nftStorageAPIKey, pinataJWT);
    }

    // ========= Operatività: Quantum Link registry =========

    /**
     * Registra un legame NFT↔FT (append-only).
     * - Esempio: quando un certo tokenId NFT viene “agganciato” a una quantità FT.
     * - MANAGER_ROLE: backend Heroku o operatori fidati.
     */
    function recordQuantumLink(address user, uint256 tokenId, uint256 ftAmount)
        external
        onlyRole(MANAGER_ROLE)
        returns (uint256 linkId)
    {
        QuantumLink memory ql = QuantumLink({
            user: user,
            tokenId: tokenId,
            ftAmount: ftAmount,
            timestamp: block.timestamp
        });
        _quantumLinks.push(ql);
        linkId = _quantumLinks.length - 1;
        emit QuantumLinkRecorded(linkId, user, tokenId, ftAmount);
    }

    /**
     * Ritorna un link per indice (per debugging/analytics frontend)
     */
    function getQuantumLink(uint256 index) external view returns (
        address user,
        uint256 tokenId,
        uint256 ftAmount,
        uint256 timestamp
    ) {
        require(index < _quantumLinks.length, "Index out of range");
        QuantumLink memory ql = _quantumLinks[index];
        return (ql.user, ql.tokenId, ql.ftAmount, ql.timestamp);
    }

    function quantumLinksCount() external view returns (uint256) {
        return _quantumLinks.length;
    }

    // ========= Configurazioni varie =========

    /**
     * Impostazione (facoltativa) di valori override e storage pointers.
     * ⚠️ Evita secrets on-chain: usa questi campi come placeholder / indicatore di stato.
     */
    function configureStorage(string calldata _nftStorageKey, string calldata _pinataJWT)
        external
        onlyRole(GOVERNOR_ROLE)
    {
        nftStorageAPIKey = _nftStorageKey;
        pinataJWT = _pinataJWT;
        emit StorageConfigured(bytes(_nftStorageKey).length > 0, bytes(_pinataJWT).length > 0);
    }

    /**
     * Facoltativo: set manuale di un override del valore stellare totale
     * (in caso di manutenzione o metrica custom temporanea).
     * Passa 0 per disattivare l’override.
     */
    function setTotalStellarValueOverride(uint256 valueOrZero)
        external
        onlyRole(GOVERNOR_ROLE)
    {
        _totalStellarValueOverride = valueOrZero;
    }

    // ========= Helpers di comodo =========

    function getSolarSystemInfo() external view returns (
        address nftPlanet,
        address ftSatellite,
        uint256 quantumLinks,
        uint256 stellarValue,
        uint256 harmonyLevel, // placeholder per estensioni future
        uint256 systemAge,    // uptime approssimato (placeholder)
        string memory storageAPIKey,
        address metricsAddr
    ) {
        nftPlanet = _nftPlanetContract;
        ftSatellite = _ftSatelliteContract;
        quantumLinks = _quantumLinks.length;
        // stellarValue calcolato come in totalStellarValue()
        if (_totalStellarValueOverride > 0) {
            stellarValue = _totalStellarValueOverride;
        } else {
            if (ftSatellite != address(0)) {
                uint256 supply = ILunaComicsFTReadable(ftSatellite).totalSupply();
                uint256 gravity = ILunaComicsFTReadable(ftSatellite).lunarGravity();
                if (gravity > 0) {
                    stellarValue = (supply * gravity) / 1e18;
                }
            }
        }
        harmonyLevel = 0; // per estensioni future
        systemAge = 0;    // per estensioni future
        storageAPIKey = nftStorageAPIKey;
        metricsAddr = _metricsContract;
    }
}
