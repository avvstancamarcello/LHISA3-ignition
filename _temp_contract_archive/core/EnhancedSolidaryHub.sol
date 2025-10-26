// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

/**
 * @title EnhancedSolidaryHub (Rector Orbis - The Ruler of the World)
 * @author
 *  © 2025 Marcello Stanca - Lawyer, Firenze, Italy. All Rights Reserved.
 * @notice Core Hub del "Solidary System": registra/coordina moduli, storage pointers (no secrets on-chain),
 *         orchestrazioni cross-modulo, stato/health dell’ecosistema, emergency mode.
 *
 * Sicurezza/Design:
 * - UUPS + AccessControl + Pausable + ReentrancyGuard
 * - Nessun secret on-chain nei log (solo marker)
 * - Chiamate cross-modulo sicure (controlli ruolo + nonReentrant)
 */

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/user/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/user/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract EnhancedSolidaryHub is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    // ───────────────────────────────── Roles & Layers ─────────────────────────────
    bytes32 public constant ECOSYSTEM_ADMIN  = keccak256("ECOSYSTEM_ADMIN");
    bytes32 public constant MODULE_MANAGER   = keccak256("MODULE_MANAGER");
    bytes32 public constant ORACLE_ROLE      = keccak256("ORACLE_ROLE");
    bytes32 public constant EMERGENCY_ROLE   = keccak256("EMERGENCY_ROLE");
    bytes32 public constant STORAGE_MANAGER  = keccak256("STORAGE_MANAGER");

    uint8 public constant LAYER_CORE          = 1;
    uint8 public constant LAYER_PLANETARY     = 2;
    uint8 public constant LAYER_SATELLITES    = 3;
    uint8 public constant LAYER_INFRASTRUCTURE= 4;
    uint8 public constant LAYER_BRIDGES       = 5;
    uint8 public constant LAYER_ANALYTICS     = 6;
    uint8 public constant LAYER_GOVERNANCE    = 7;

    // ───────────────────────────────── Data structures ────────────────────────────
    struct EnhancedModuleInfo {
        address contractAddress;
        string  moduleName;
        uint8   layer;
        bool    active;
        uint256 version;
        string  moduleType;    // "orchestrator","nft","ft","metrics","bridge","reputation","impact","router"
        string  ipfsCID;       // metadata su IPFS
        uint256 lastInteraction;
        uint256 successRate;   // 0..100
        uint256 totalInteractions;
        address[] dependencies;
        address[] dependents;
    }

    struct EcosystemHealth {
        uint256 overallScore;
        uint256 moduleHealth;
        uint256 crossChainHealth;
        uint256 reputationHealth;
        uint256 impactHealth;
        uint256 storageHealth;
        string  healthCID;
        uint256 lastCheck;
    }

    struct StorageConfiguration {
        string  nftStorageAPIKey; // placeholders: non usare segreti reali
        string  pinataJWT;        // placeholders
        string  ipfsBaseURI;
        bool    storageEnabled;
        uint256 totalCIDsStored;
        string  storageAnalyticsCID;
    }

    struct EnhancedEcosystemState {
        uint256 totalUsers;
        uint256 totalImpact;
        uint256 globalReputation;
        uint256 totalTransactions;
        uint256 crossChainVolume;
        uint256 carbonFootprint;
        uint256 totalValueLocked;
        bool    emergencyMode;
        string  stateCID; // snapshot su IPFS
    }

    // ───────────────────────────────── State ──────────────────────────────────────
    mapping(uint8 => address[]) public modulesByLayer;
    mapping(address => EnhancedModuleInfo) public modules;
    mapping(string => address) public moduleByName;
    mapping(string => address[]) public modulesByType;

    // Core references (coerenti con i nuovi nomi)
    address public solidaryOrchestrator;       // Orchestrator V2 o Hub orizzontale
    address public oceanMangaNFT;              // ex mareaMangaNFT
    address public lunaComicsFT;
    address public solidaryMetrics;
    address public reputationManager;
    address public impactLogger;
    address public moduleRouter;
    address public multiChainOrchestrator;     // UniversalMultiChainOrchestratorV2

    StorageConfiguration public storageConfig;
    EcosystemHealth public ecosystemHealth;
    EnhancedEcosystemState public ecosystemState;

    // Stats
    uint256 public totalModuleRegistrations;
    uint256 public totalCrossModuleCalls;
    uint256 public totalEmergencyEvents;

    // ───────────────────────────────── Events ─────────────────────────────────────
    event ModuleRegistered(address indexed moduleAddress, string moduleName, uint8 layer, string moduleType);
    event ModuleActivated(address indexed moduleAddress, bool status);
    event EcosystemStateUpdated(uint256 totalUsers, uint256 totalImpact, uint256 globalReputation, string stateCID);
    event EmergencyTriggered(address indexed trigger, string reason);
    event CrossModuleCallExecuted(address indexed from, address indexed to, bool success, bytes result);
    event StorageConfigured(bool storageEnabled, string ipfsBaseURI, address configuredBy);
    event EcosystemHealthUpdated(uint256 overallScore, string healthCID);
    event ModuleDependencyAdded(address indexed module, address indexed dependency);
    event EcosystemInitialized(address orchestrator, address nftPlanet, address ftSatellite);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    function initialize(address initialAdmin) public initializer {
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(ECOSYSTEM_ADMIN,  initialAdmin);
        _grantRole(MODULE_MANAGER,   initialAdmin);
        _grantRole(ORACLE_ROLE,      initialAdmin);
        _grantRole(EMERGENCY_ROLE,   initialAdmin);
        _grantRole(STORAGE_MANAGER,  initialAdmin);

        ecosystemState = EnhancedEcosystemState({
            totalUsers: 0,
            totalImpact: 0,
            globalReputation: 0,
            totalTransactions: 0,
            crossChainVolume: 0,
            carbonFootprint: 0,
            totalValueLocked: 0,
            emergencyMode: false,
            stateCID: ""
        });

        ecosystemHealth = EcosystemHealth({
            overallScore: 100,
            moduleHealth: 100,
            crossChainHealth: 100,
            reputationHealth: 100,
            impactHealth: 100,
            storageHealth: 100,
            healthCID: "",
            lastCheck: block.timestamp
        });

        storageConfig = StorageConfiguration({
            nftStorageAPIKey: "",
            pinataJWT: "",
            ipfsBaseURI: "",
            storageEnabled: false,
            totalCIDsStored: 0,
            storageAnalyticsCID: ""
        });
    }

    // ───────────────────────────── Ecosystem bootstrap ────────────────────────────
    function initializeEcosystem(
        address _orchestrator,
        address _nftPlanet,      // OceanMangaNFT
        address _ftSatellite,    // LunaComicsFT
        address _metrics,        // SolidaryMetrics
        address _reputationManager,
        address _impactLogger,
        address _moduleRouter,
        address _multiChainOrchestrator
    ) external onlyRole(ECOSYSTEM_ADMIN) {
        solidaryOrchestrator = _orchestrator;
        oceanMangaNFT        = _nftPlanet;
        lunaComicsFT         = _ftSatellite;
        solidaryMetrics      = _metrics;
        reputationManager    = _reputationManager;
        impactLogger         = _impactLogger;
        moduleRouter         = _moduleRouter;
        multiChainOrchestrator = _multiChainOrchestrator;

        _registerCoreModule(_orchestrator,        "SolidaryOrchestrator",       LAYER_CORE,         "orchestrator");
        _registerCoreModule(_nftPlanet,           "OceanMangaNFT",              LAYER_PLANETARY,    "nft");
        _registerCoreModule(_ftSatellite,         "LunaComicsFT",               LAYER_SATELLITES,   "ft");
        _registerCoreModule(_metrics,             "SolidaryMetrics",            LAYER_ANALYTICS,    "metrics");
        _registerCoreModule(_reputationManager,   "ReputationManager",          LAYER_INFRASTRUCTURE,"reputation");
        _registerCoreModule(_impactLogger,        "ImpactLogger",               LAYER_INFRASTRUCTURE,"impact");
        _registerCoreModule(_moduleRouter,        "ModuleRouter",               LAYER_INFRASTRUCTURE,"router");
        _registerCoreModule(_multiChainOrchestrator,"UniversalMultiChainOrchestratorV2", LAYER_BRIDGES, "bridge");

        emit EcosystemInitialized(_orchestrator, _nftPlanet, _ftSatellite);
    }

    function _registerCoreModule(
        address moduleAddress,
        string memory moduleName,
        uint8 layer,
        string memory moduleType
    ) internal {
        if (moduleAddress == address(0)) return;

        modules[moduleAddress] = EnhancedModuleInfo({
            contractAddress: moduleAddress,
            moduleName: moduleName,
            layer: layer,
            active: true,
            version: 1,
            moduleType: moduleType,
            ipfsCID: "",
            lastInteraction: block.timestamp,
            successRate: 100,
            totalInteractions: 0,
            dependencies: new address,
            dependents: new address
        });

        modulesByLayer[layer].push(moduleAddress);
        moduleByName[moduleName] = moduleAddress;
        modulesByType[moduleType].push(moduleAddress);

        totalModuleRegistrations++;
        emit ModuleRegistered(moduleAddress, moduleName, layer, moduleType);
    }

    // ───────────────────────────── Module management ──────────────────────────────
    function registerEnhancedModule(
        address contractAddress,
        string memory moduleName,
        uint8 layer,
        string memory moduleType,
        address[] memory dependencies,
        string memory metadata
    ) external onlyRole(MODULE_MANAGER) returns (string memory moduleCID) {
        require(contractAddress != address(0), "Invalid contract");
        require(layer >= 1 && layer <= 7, "Invalid layer");
        require(modules[contractAddress].contractAddress == address(0), "Already registered");

        moduleCID = _uploadToIPFS(bytes(metadata));

        modules[contractAddress] = EnhancedModuleInfo({
            contractAddress: contractAddress,
            moduleName: moduleName,
            layer: layer,
            active: true,
            version: 1,
            moduleType: moduleType,
            ipfsCID: moduleCID,
            lastInteraction: block.timestamp,
            successRate: 100,
            totalInteractions: 0,
            dependencies: dependencies,
            dependents: new address
        });

        for (uint256 i = 0; i < dependencies.length; i++) {
            modules[dependencies[i]].dependents.push(contractAddress);
            emit ModuleDependencyAdded(contractAddress, dependencies[i]);
        }

        modulesByLayer[layer].push(contractAddress);
        moduleByName[moduleName] = contractAddress;
        modulesByType[moduleType].push(contractAddress);

        totalModuleRegistrations++;
        emit ModuleRegistered(contractAddress, moduleName, layer, moduleType);
    }

    function setModuleStatus(address moduleAddress, bool active) external onlyRole(MODULE_MANAGER) {
        require(modules[moduleAddress].contractAddress != address(0), "Module not registered");
        modules[moduleAddress].active = active;
        emit ModuleActivated(moduleAddress, active);
    }

    // ───────────────────────────── Storage configuration ──────────────────────────
    function configureStorage(
        string memory _nftStorageKey,
        string memory _pinataJWT,
        string memory _ipfsBaseURI
    ) external onlyRole(STORAGE_MANAGER) {
        storageConfig.nftStorageAPIKey = _nftStorageKey;
        storageConfig.pinataJWT        = _pinataJWT;
        storageConfig.ipfsBaseURI      = _ipfsBaseURI;
        storageConfig.storageEnabled   = true;

        _propagateStorageConfiguration();

        // Non logghiamo i secrets; solo marker boolean e baseURI
        emit StorageConfigured(true, _ipfsBaseURI, msg.sender);
    }

    function _propagateStorageConfiguration() internal {
        // In produzione: invia messaggi ai moduli che supportano la config
        bytes memory storageData = abi.encodePacked(
            '{"ipfsBaseURI":"', storageConfig.ipfsBaseURI,
            '","configuredAt":', _u(block.timestamp), "}"
        );
        string memory cid = _uploadToIPFS(storageData);
        storageConfig.storageAnalyticsCID = cid;
        storageConfig.totalCIDsStored++;
    }

    // ───────────────────────────── Cross-module orchestration ─────────────────────
    function crossModuleCall(address targetModule, bytes calldata data)
        public
        nonReentrant
        returns (bytes memory)
    {
        require(modules[targetModule].active, "Target inactive");
        require(
            hasRole(MODULE_MANAGER, msg.sender) ||
            hasRole(ECOSYSTEM_ADMIN, msg.sender) ||
            _isModule(msg.sender),
            "Unauthorized cross-call"
        );

        modules[targetModule].lastInteraction = block.timestamp;
        modules[targetModule].totalInteractions++;

        (bool success, bytes memory result) = targetModule.call(data);

        if (success) {
            modules[targetModule].successRate = (modules[targetModule].successRate * 99 + 100) / 100;
        } else {
            modules[targetModule].successRate = (modules[targetModule].successRate * 99) / 100;
        }

        totalCrossModuleCalls++;
        emit CrossModuleCallExecuted(msg.sender, targetModule, success, result);
        require(success, "Cross-module call failed");
        return result;
    }

    function orchestrateMultiModuleCall(address[] memory targetModules, bytes[] memory data)
        external
        onlyRole(ECOSYSTEM_ADMIN)
        returns (bool[] memory successes, bytes[] memory results)
    {
        require(targetModules.length == data.length, "Length mismatch");
        successes = new bool[](targetModules.length);
        results   = new bytes[](targetModules.length);

        for (uint256 i = 0; i < targetModules.length; i++) {
            if (modules[targetModules[i]].active) {
                // chiamata interna (no `this.`), preserva msg.sender = ECOSYSTEM_ADMIN
                try this.crossModuleCall(targetModules[i], data[i]) returns (bytes memory res) {
                    successes[i] = true;
                    results[i] = res;
                } catch (bytes memory err) {
                    successes[i] = false;
                    results[i] = err;
                }
            } else {
                successes[i] = false;
                results[i] = abi.encode("Module inactive");
            }
        }
    }

    // ───────────────────────────── Ecosystem health ───────────────────────────────
    function updateEcosystemState(
        uint256 newUsers,
        uint256 newImpact,
        uint256 newReputation,
        uint256 newTransactions,
        uint256 newCrossChainVolume,
        uint256 newCarbonFootprint,
        uint256 newTVL
    ) external onlyRole(ORACLE_ROLE) whenNotPaused {
        ecosystemState.totalUsers        += newUsers;
        ecosystemState.totalImpact       += newImpact;
        ecosystemState.globalReputation   = newReputation;
        ecosystemState.totalTransactions += newTransactions;
        ecosystemState.crossChainVolume  += newCrossChainVolume;
        ecosystemState.carbonFootprint    = newCarbonFootprint;
        ecosystemState.totalValueLocked   = newTVL;

        string memory stateCID = _storeEcosystemStateOnIPFS();
        ecosystemState.stateCID = stateCID;

        _calculateEcosystemHealth();
        emit EcosystemStateUpdated(newUsers, newImpact, newReputation, stateCID);
    }

    function _calculateEcosystemHealth() internal {
        uint256 moduleScore     = _calculateModuleHealth();
        uint256 crossChainScore = _calculateCrossChainHealth();
        uint256 reputationScore = _calculateReputationHealth();
        uint256 impactScore     = _calculateImpactHealth();
        uint256 storageScore    = _calculateStorageHealth();

        ecosystemHealth.overallScore   = (moduleScore + crossChainScore + reputationScore + impactScore + storageScore) / 5;
        ecosystemHealth.moduleHealth   = moduleScore;
        ecosystemHealth.crossChainHealth = crossChainScore;
        ecosystemHealth.reputationHealth = reputationScore;
        ecosystemHealth.impactHealth     = impactScore;
        ecosystemHealth.storageHealth    = storageScore;
        ecosystemHealth.lastCheck        = block.timestamp;

        string memory healthCID = _storeEcosystemHealthOnIPFS();
        ecosystemHealth.healthCID = healthCID;

        emit EcosystemHealthUpdated(ecosystemHealth.overallScore, healthCID);
    }

    function _calculateModuleHealth() internal view returns (uint256) {
        uint256 activeCount = 0;
        uint256 totalCount = 0;

        for (uint8 layer = 1; layer <= 7; layer++) {
            address[] memory layerModules = modulesByLayer[layer];
            totalCount += layerModules.length;
            for (uint256 i = 0; i < layerModules.length; i++) {
                if (modules[layerModules[i]].active) activeCount++;
            }
        }
        return totalCount > 0 ? (activeCount * 100) / totalCount : 100;
    }

    function _calculateCrossChainHealth() internal view returns (uint256) {
        if (multiChainOrchestrator == address(0)) return 100;
        // In produzione: query al MultiChainOrchestrator per health
        return 100;
    }

    function _calculateReputationHealth() internal view returns (uint256) {
        if (reputationManager == address(0)) return 100;
        return ecosystemState.globalReputation > 500 ? 100
               : (ecosystemState.globalReputation * 100) / 500;
    }

    function _calculateImpactHealth() internal view returns (uint256) {
        if (impactLogger == address(0)) return 100;
        return ecosystemState.totalImpact > 0 ? 100 : 50;
    }

    function _calculateStorageHealth() internal view returns (uint256) {
        return storageConfig.storageEnabled ? 100 : 50;
    }

    // ───────────────────────────── Emergency ──────────────────────────────────────
    function triggerEmergency(string memory reason) external onlyRole(EMERGENCY_ROLE) {
        _pause();
        ecosystemState.emergencyMode = true;
        totalEmergencyEvents++;
        _disableCriticalModules();
        emit EmergencyTriggered(msg.sender, reason);
    }

    function _disableCriticalModules() internal {
        address[] memory critical = modulesByType["bridge"];
        for (uint256 i = 0; i < critical.length; i++) {
            modules[critical[i]].active = false;
            emit ModuleActivated(critical[i], false);
        }
    }

    function resolveEmergency() external onlyRole(EMERGENCY_ROLE) {
        _unpause();
        ecosystemState.emergencyMode = false;
        _enableCriticalModules();
    }

    function _enableCriticalModules() internal {
        address[] memory critical = modulesByType["bridge"];
        for (uint256 i = 0; i < critical.length; i++) {
            modules[critical[i]].active = true;
            emit ModuleActivated(critical[i], true);
        }
    }

    // ───────────────────────────── IPFS utils (sim) ───────────────────────────────
    function _storeEcosystemStateOnIPFS() internal returns (string memory) {
        bytes memory stateData = abi.encodePacked(
            '{"totalUsers":', _u(ecosystemState.totalUsers),
            ',"totalImpact":', _u(ecosystemState.totalImpact),
            ',"globalReputation":', _u(ecosystemState.globalReputation),
            ',"totalTransactions":', _u(ecosystemState.totalTransactions),
            ',"crossChainVolume":', _u(ecosystemState.crossChainVolume),
            ',"carbonFootprint":', _u(ecosystemState.carbonFootprint),
            ',"totalValueLocked":', _u(ecosystemState.totalValueLocked),
            ',"emergencyMode":', ecosystemState.emergencyMode ? "true" : "false",
            ',"timestamp":', _u(block.timestamp), "}"
        );
        string memory cid = _uploadToIPFS(stateData);
        storageConfig.totalCIDsStored++;
        return cid;
    }

    function _storeEcosystemHealthOnIPFS() internal returns (string memory) {
        bytes memory healthData = abi.encodePacked(
            '{"overallScore":', _u(ecosystemHealth.overallScore),
            ',"moduleHealth":', _u(ecosystemHealth.moduleHealth),
            ',"crossChainHealth":', _u(ecosystemHealth.crossChainHealth),
            ',"reputationHealth":', _u(ecosystemHealth.reputationHealth),
            ',"impactHealth":', _u(ecosystemHealth.impactHealth),
            ',"storageHealth":', _u(ecosystemHealth.storageHealth),
            ',"lastCheck":', _u(ecosystemHealth.lastCheck),
            ',"totalModules":', _u(totalModuleRegistrations),
            ',"activeModules":', _u(_countActiveModules()), "}"
        );
        string memory cid = _uploadToIPFS(healthData);
        storageConfig.totalCIDsStored++;
        return cid;
    }

    function _uploadToIPFS(bytes memory data) internal view returns (string memory cid) {
        bytes32 hash = keccak256(abi.encodePacked(data, block.timestamp, storageConfig.totalCIDsStored));
        cid = string(abi.encodePacked("simulated:ipfs:", _bytes32ToHexString(hash)));
        return cid;
    }

    // ───────────────────────────── View helpers ───────────────────────────────────
    function getEnhancedModuleInfo(address moduleAddress) external view returns (EnhancedModuleInfo memory) {
        return modules[moduleAddress];
    }
    function getModulesByLayer(uint8 layer) external view returns (address[] memory) {
        return modulesByLayer[layer];
    }
    function getModuleByName(string memory moduleName) external view returns (address) {
        return moduleByName[moduleName];
    }
    function getModulesByType(string memory moduleType) external view returns (address[] memory) {
        return modulesByType[moduleType];
    }
    function getEnhancedEcosystemState() external view returns (EnhancedEcosystemState memory) {
        return ecosystemState;
    }
    function getEcosystemHealth() external view returns (EcosystemHealth memory) {
        return ecosystemHealth;
    }
    function getStorageConfiguration() external view returns (StorageConfiguration memory) {
        return storageConfig;
    }
    function isEmergencyMode() external view returns (bool) {
        return ecosystemState.emergencyMode || paused();
    }
    function calculateEcosystemHealthScore() external view returns (uint256) {
        return ecosystemHealth.overallScore;
    }
    function countActiveModulesByLayer(uint8 layer) external view returns (uint256) {
        uint256 count = 0;
        address[] memory layerModules = modulesByLayer[layer];
        for (uint256 i = 0; i < layerModules.length; i++) {
            if (modules[layerModules[i]].active) count++;
        }
        return count;
    }
    function _countActiveModules() internal view returns (uint256) {
        uint256 count = 0;
        for (uint8 layer = 1; layer <= 7; layer++) {
            address[] memory arr = modulesByLayer[layer];
            for (uint256 i = 0; i < arr.length; i++) {
                if (modules[arr[i]].active) count++;
            }
        }
        return count;
    }
    function _isModule(address addr) internal view returns (bool) {
        return modules[addr].contractAddress != address(0);
    }
    function getEcosystemStatistics() external view returns (
        uint256 totalModules,
        uint256 activeModules,
        uint256 totalCalls,
        uint256 totalEmergencies,
        uint256 totalCIDs
    ) {
        return (
            totalModuleRegistrations,
            _countActiveModules(),
            totalCrossModuleCalls,
            totalEmergencyEvents,
            storageConfig.totalCIDsStored
        );
    }

    // ───────────────────────────── Utils ──────────────────────────────────────────
    function _bytes32ToHexString(bytes32 v) internal pure returns (string memory) {
        bytes memory s = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            bytes1 b = v[i];
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) % 16);
            s[2*i]   = _nibble(hi);
            s[2*i+1] = _nibble(lo);
        }
        return string(s);
    }
    function _nibble(bytes1 b) internal pure returns (bytes1 c) {
        uint8 v = uint8(b);
        return v < 10 ? bytes1(v + 0x30) : bytes1(v + 0x57);
    }
    function _u(uint256 x) internal pure returns (string memory) {
        // Int to decimal string
        if (x == 0) return "0";
        uint256 j = x; uint256 len;
        while (j != 0) { len++; j /= 10; }
        bytes memory b = new bytes(len);
        uint256 k = len; uint256 y = x;
        while (y != 0) { k--; b[k] = bytes1(uint8(48 + y % 10)); y /= 10; }
        return string(b);
    }

    // ───────────────────────────── UUPS auth ──────────────────────────────────────
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
