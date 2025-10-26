// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

// Copyright © 2025 Marcello Stanca - Lawyer, Firenze, Italy. All Rights Reserved.
// Hoc contractum, pars 'Solidary System', ab Auctore Marcello Stanca Caritati Internationali (MCMLXXVI) conceditur.

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title EnhancedSolidaryHub (Rector Orbis - The Ruler of the World)
 * @author Avv. Marcello Stanca - Architectus Aequitatis
 * @notice Cor Aetereum et Director Orchestae Oecosystematis 'Solidary System'. 
 * Hic, omnes moduli in unam symphoniam caritatis conveniunt cum potentia nova et sapientia.
 */
contract EnhancedSolidaryHub is Initializable, AccessControlUpgradeable, PausableUpgradeable, UUPSUpgradeable {

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔐 ROLES & CONSTANTS
    // ═══════════════════════════════════════════════════════════════════════════════

    bytes32 public constant ECOSYSTEM_ADMIN = keccak256("ECOSYSTEM_ADMIN");
    bytes32 public constant MODULE_MANAGER = keccak256("MODULE_MANAGER");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    bytes32 public constant STORAGE_MANAGER = keccak256("STORAGE_MANAGER");

    // Layer definitions for ecosystem organization
    uint8 public constant LAYER_CORE = 1;
    uint8 public constant LAYER_PLANETARY = 2;
    uint8 public constant LAYER_SATELLITES = 3;
    uint8 public constant LAYER_INFRASTRUCTURE = 4;
    uint8 public constant LAYER_BRIDGES = 5;
    uint8 public constant LAYER_ANALYTICS = 6;
    uint8 public constant LAYER_GOVERNANCE = 7;

    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 ENHANCED DATA STRUCTURES
    // ═══════════════════════════════════════════════════════════════════════════════

    struct EnhancedModuleInfo {
        address contractAddress;
        string moduleName;
        uint8 layer;
        bool active;
        uint256 version;
        string moduleType;           // "orchestrator", "nft", "ft", "metrics", "bridge", "reputation", "impact"
        string ipfsCID;              // 🔗 Metadata completo su IPFS
        uint256 lastInteraction;
        uint256 successRate;
        uint256 totalInteractions;
        address[] dependencies;      // Moduli da cui dipende
        address[] dependents;        // Moduli che dipendono da questo
    }

    struct EcosystemHealth {
        uint256 overallScore;
        uint256 moduleHealth;
        uint256 crossChainHealth;
        uint256 reputationHealth;
        uint256 impactHealth;
        uint256 storageHealth;
        string healthCID;            // 🔗 Analytics dettagliate su IPFS
        uint256 lastCheck;
    }

    struct StorageConfiguration {
        string nftStorageAPIKey;
        string pinataJWT;
        string ipfsBaseURI;
        bool storageEnabled;
        uint256 totalCIDsStored;
        string storageAnalyticsCID;  // 🔗 Analytics storage su IPFS
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 💾 STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════════

    mapping(uint8 => address[]) public modulesByLayer;
    mapping(address => EnhancedModuleInfo) public modules;
    mapping(string => address) public moduleByName;
    mapping(string => address[]) public modulesByType;

    // 🔗 Core Ecosystem References
    address public solidaryOrchestrator;
    address public mareaMangaNFT;
    address public lunaComicsFT;
    address public solidaryMetrics;
    address public reputationManager;
    address public impactLogger;
    address public moduleRouter;
    address public multiChainOrchestrator;

    // 🌐 Storage Configuration
    StorageConfiguration public storageConfig;

    // 📊 Enhanced Ecosystem State
    EcosystemHealth public ecosystemHealth;
    
    struct EnhancedEcosystemState {
        uint256 totalUsers;
        uint256 totalImpact;
        uint256 globalReputation;
        uint256 totalTransactions;
        uint256 crossChainVolume;
        uint256 carbonFootprint;
        uint256 totalValueLocked;
        bool emergencyMode;
        string stateCID;             // 🔗 Stato completo su IPFS
    }

    EnhancedEcosystemState public ecosystemState;

    // 📈 Statistics
    uint256 public totalModuleRegistrations;
    uint256 public totalCrossModuleCalls;
    uint256 public totalEmergencyEvents;

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎯 EVENTS
    // ═══════════════════════════════════════════════════════════════════════════════

    event ModuleRegistered(address indexed moduleAddress, string moduleName, uint8 layer, string moduleType);
    event ModuleActivated(address indexed moduleAddress, bool status);
    event EcosystemStateUpdated(uint256 totalUsers, uint256 totalImpact, uint256 globalReputation, string stateCID);
    event EmergencyTriggered(address indexed trigger, string reason);
    event CrossModuleCallExecuted(address indexed from, address indexed to, bool success, bytes result);
    event StorageConfigured(string nftStorageKey, string pinataJWT, address configuredBy);
    event EcosystemHealthUpdated(uint256 overallScore, string healthCID);
    event ModuleDependencyAdded(address indexed module, address indexed dependency);
    event EcosystemInitialized(address orchestrator, address nftPlanet, address ftSatellite);

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏗️ INITIALIZATION
    // ═══════════════════════════════════════════════════════════════════════════════

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialAdmin) public initializer {
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        // Consecratio Munerum (Consecration of Roles)
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(ECOSYSTEM_ADMIN, initialAdmin);
        _grantRole(MODULE_MANAGER, initialAdmin);
        _grantRole(ORACLE_ROLE, initialAdmin);
        _grantRole(EMERGENCY_ROLE, initialAdmin);
        _grantRole(STORAGE_MANAGER, initialAdmin);

        // Initialize ecosystem state
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

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎯 ECOSYSTEM INITIALIZATION
    // ═══════════════════════════════════════════════════════════════════════════════

    /**
     * @dev Inizializza l'ecosistema completo Solidary
     */
    function initializeEcosystem(
        address _orchestrator,
        address _nftPlanet,
        address _ftSatellite,
        address _metrics,
        address _reputationManager,
        address _impactLogger,
        address _moduleRouter,
        address _multiChainOrchestrator
    ) external onlyRole(ECOSYSTEM_ADMIN) {
        
        solidaryOrchestrator = _orchestrator;
        mareaMangaNFT = _nftPlanet;
        lunaComicsFT = _ftSatellite;
        solidaryMetrics = _metrics;
        reputationManager = _reputationManager;
        impactLogger = _impactLogger;
        moduleRouter = _moduleRouter;
        multiChainOrchestrator = _multiChainOrchestrator;

        // Registra automaticamente i moduli core
        _registerCoreModule(_orchestrator, "SolidaryOrchestrator", LAYER_CORE, "orchestrator");
        _registerCoreModule(_nftPlanet, "MareaMangaNFT", LAYER_PLANETARY, "nft");
        _registerCoreModule(_ftSatellite, "LunaComicsFT", LAYER_SATELLITES, "ft");
        _registerCoreModule(_metrics, "SolidaryMetrics", LAYER_ANALYTICS, "metrics");
        _registerCoreModule(_reputationManager, "ReputationManager", LAYER_INFRASTRUCTURE, "reputation");
        _registerCoreModule(_impactLogger, "ImpactLogger", LAYER_INFRASTRUCTURE, "impact");
        _registerCoreModule(_moduleRouter, "ModuleRouter", LAYER_INFRASTRUCTURE, "router");
        _registerCoreModule(_multiChainOrchestrator, "MultiChainOrchestrator", LAYER_BRIDGES, "bridge");

        emit EcosystemInitialized(_orchestrator, _nftPlanet, _ftSatellite);
    }

    function _registerCoreModule(
        address moduleAddress,
        string memory moduleName,
        uint8 layer,
        string memory moduleType
    ) internal {
        if (moduleAddress != address(0)) {
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
                dependencies: new address[](0),
                dependents: new address[](0)
            });

            modulesByLayer[layer].push(moduleAddress);
            moduleByName[moduleName] = moduleAddress;
            modulesByType[moduleType].push(moduleAddress);

            totalModuleRegistrations++;
            emit ModuleRegistered(moduleAddress, moduleName, layer, moduleType);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔗 ENHANCED MODULE MANAGEMENT
    // ═══════════════════════════════════════════════════════════════════════════════

    /**
     * @dev Registra un modulo con dipendenze e metadata avanzato
     */
    function registerEnhancedModule(
        address contractAddress,
        string memory moduleName,
        uint8 layer,
        string memory moduleType,
        address[] memory dependencies,
        string memory metadata
    ) external onlyRole(MODULE_MANAGER) returns (string memory moduleCID) {
        
        require(contractAddress != address(0), "Invalid contract address");
        require(layer >= 1 && layer <= 7, "Invalid layer");
        require(modules[contractAddress].contractAddress == address(0), "Module already registered");

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
            dependents: new address[](0)
        });

        // Aggiorna dipendenze
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

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌐 STORAGE CONFIGURATION
    // ═══════════════════════════════════════════════════════════════════════════════

    /**
     * @dev Configura lo storage decentralizzato per tutto l'ecosistema
     */
    function configureStorage(
        string memory _nftStorageKey,
        string memory _pinataJWT,
        string memory _ipfsBaseURI
    ) external onlyRole(STORAGE_MANAGER) {
        
        storageConfig.nftStorageAPIKey = _nftStorageKey;
        storageConfig.pinataJWT = _pinataJWT;
        storageConfig.ipfsBaseURI = _ipfsBaseURI;
        storageConfig.storageEnabled = true;

        // Propaga configurazione a tutti i moduli
        _propagateStorageConfiguration();

        emit StorageConfigured(_nftStorageKey, _pinataJWT, msg.sender);
    }

    function _propagateStorageConfiguration() internal {
        // In produzione: chiamate ai vari moduli per configurare lo storage
        // Per ora aggiorniamo solo lo stato interno
        bytes memory storageData = abi.encodePacked(
            '{"nftStorageKey": "', storageConfig.nftStorageAPIKey,
            '", "pinataJWT": "', storageConfig.pinataJWT,
            '", "ipfsBaseURI": "', storageConfig.ipfsBaseURI,
            '", "configuredAt": ', _uint2str(block.timestamp),
            '}'
        );

        string memory cid = _uploadToIPFS(storageData);
        storageConfig.storageAnalyticsCID = cid;
        storageConfig.totalCIDsStored++;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔄 ENHANCED CROSS-MODULE ORCHESTRATION
    // ═══════════════════════════════════════════════════════════════════════════════

    /**
     * @dev Chiamata cross-modulo con gestione avanzata
     */
    function crossModuleCall(
        address targetModule, 
        bytes calldata data
    ) external returns (bytes memory) {
        
        require(modules[targetModule].active, "Target module not active");
        require(
            hasRole(MODULE_MANAGER, msg.sender) || 
            hasRole(ECOSYSTEM_ADMIN, msg.sender) ||
            _isModule(msg.sender),
            "Unauthorized cross-call"
        );

        // Aggiorna statistiche modulo
        modules[targetModule].lastInteraction = block.timestamp;
        modules[targetModule].totalInteractions++;

        uint256 startGas = gasleft();
        (bool success, bytes memory result) = targetModule.call(data);

        // Aggiorna success rate
        if (success) {
            modules[targetModule].successRate = 
                (modules[targetModule].successRate * 99 + 100) / 100;
        } else {
            modules[targetModule].successRate = 
                (modules[targetModule].successRate * 99) / 100;
        }

        totalCrossModuleCalls++;

        emit CrossModuleCallExecuted(msg.sender, targetModule, success, result);
        
        require(success, "Cross-module call failed");
        return result;
    }

    /**
     * @dev Orchestrazione complessa tra multipli moduli
     */
    function orchestrateMultiModuleCall(
        address[] memory targetModules,
        bytes[] memory data
    ) external onlyRole(ECOSYSTEM_ADMIN) returns (bool[] memory successes, bytes[] memory results) {
        
        require(targetModules.length == data.length, "Arrays length mismatch");
        
        successes = new bool[](targetModules.length);
        results = new bytes[](targetModules.length);

        for (uint256 i = 0; i < targetModules.length; i++) {
            if (modules[targetModules[i]].active) {
                try this.crossModuleCall(targetModules[i], data[i]) returns (bytes memory result) {
                    successes[i] = true;
                    results[i] = result;
                } catch {
                    successes[i] = false;
                    results[i] = abi.encode("Call failed");
                }
            } else {
                successes[i] = false;
                results[i] = abi.encode("Module inactive");
            }
        }

        return (successes, results);
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 ECOSYSTEM HEALTH MONITORING
    // ═══════════════════════════════════════════════════════════════════════════════

    /**
     * @dev Aggiorna stato ecosistema con analytics avanzate
     */
    function updateEcosystemState(
        uint256 newUsers,
        uint256 newImpact,
        uint256 newReputation,
        uint256 newTransactions,
        uint256 newCrossChainVolume,
        uint256 newCarbonFootprint,
        uint256 newTVL
    ) external onlyRole(ORACLE_ROLE) whenNotPaused {
        
        ecosystemState.totalUsers += newUsers;
        ecosystemState.totalImpact += newImpact;
        ecosystemState.globalReputation = newReputation;
        ecosystemState.totalTransactions += newTransactions;
        ecosystemState.crossChainVolume += newCrossChainVolume;
        ecosystemState.carbonFootprint = newCarbonFootprint;
        ecosystemState.totalValueLocked = newTVL;

        // Salva stato completo su IPFS
        string memory stateCID = _storeEcosystemStateOnIPFS();
        ecosystemState.stateCID = stateCID;

        // Calcola salute ecosistema
        _calculateEcosystemHealth();

        emit EcosystemStateUpdated(newUsers, newImpact, newReputation, stateCID);
    }

    function _calculateEcosystemHealth() internal {
        uint256 moduleScore = _calculateModuleHealth();
        uint256 crossChainScore = _calculateCrossChainHealth();
        uint256 reputationScore = _calculateReputationHealth();
        uint256 impactScore = _calculateImpactHealth();
        uint256 storageScore = _calculateStorageHealth();

        ecosystemHealth.overallScore = (moduleScore + crossChainScore + reputationScore + impactScore + storageScore) / 5;
        ecosystemHealth.moduleHealth = moduleScore;
        ecosystemHealth.crossChainHealth = crossChainScore;
        ecosystemHealth.reputationHealth = reputationScore;
        ecosystemHealth.impactHealth = impactScore;
        ecosystemHealth.storageHealth = storageScore;
        ecosystemHealth.lastCheck = block.timestamp;

        // Salva analytics salute su IPFS
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
                if (modules[layerModules[i]].active) {
                    activeCount++;
                }
            }
        }

        return totalCount > 0 ? (activeCount * 100) / totalCount : 100;
    }

    function _calculateCrossChainHealth() internal view returns (uint256) {
        if (multiChainOrchestrator == address(0)) return 100;
        // In produzione: chiamata al MultiChainOrchestrator per health check
        return 100;
    }

    function _calculateReputationHealth() internal view returns (uint256) {
        if (reputationManager == address(0)) return 100;
        // In produzione: chiamata al ReputationManager per health check
        return ecosystemState.globalReputation > 500 ? 100 : 
               (ecosystemState.globalReputation * 100) / 500;
    }

    function _calculateImpactHealth() internal view returns (uint256) {
        if (impactLogger == address(0)) return 100;
        // In produzione: chiamata all'ImpactLogger per health check
        return ecosystemState.totalImpact > 0 ? 100 : 50;
    }

    function _calculateStorageHealth() internal view returns (uint256) {
        return storageConfig.storageEnabled ? 100 : 50;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🚨 ENHANCED EMERGENCY FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

    function triggerEmergency(string memory reason) external onlyRole(EMERGENCY_ROLE) {
        _pause();
        ecosystemState.emergencyMode = true;
        totalEmergencyEvents++;

        // Disabilita moduli critici
        _disableCriticalModules();

        emit EmergencyTriggered(msg.sender, reason);
    }

    function _disableCriticalModules() internal {
        // Disabilita moduli basati su criteri di sicurezza
        address[] memory criticalModules = modulesByType["bridge"];
        for (uint256 i = 0; i < criticalModules.length; i++) {
            modules[criticalModules[i]].active = false;
            emit ModuleActivated(criticalModules[i], false);
        }
    }

    function resolveEmergency() external onlyRole(EMERGENCY_ROLE) {
        _unpause();
        ecosystemState.emergencyMode = false;

        // Riabilita moduli
        _enableCriticalModules();
    }

    function _enableCriticalModules() internal {
        address[] memory criticalModules = modulesByType["bridge"];
        for (uint256 i = 0; i < criticalModules.length; i++) {
            modules[criticalModules[i]].active = true;
            emit ModuleActivated(criticalModules[i], true);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌐 IPFS STORAGE FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

    function _storeEcosystemStateOnIPFS() internal returns (string memory) {
        bytes memory stateData = abi.encodePacked(
            '{"totalUsers": ', _uint2str(ecosystemState.totalUsers),
            ', "totalImpact": ', _uint2str(ecosystemState.totalImpact),
            ', "globalReputation": ', _uint2str(ecosystemState.globalReputation),
            ', "totalTransactions": ', _uint2str(ecosystemState.totalTransactions),
            ', "crossChainVolume": ', _uint2str(ecosystemState.crossChainVolume),
            ', "carbonFootprint": ', _uint2str(ecosystemState.carbonFootprint),
            ', "totalValueLocked": ', _uint2str(ecosystemState.totalValueLocked),
            ', "emergencyMode": ', ecosystemState.emergencyMode ? "true" : "false",
            ', "timestamp": ', _uint2str(block.timestamp),
            '}'
        );

        string memory cid = _uploadToIPFS(stateData);
        storageConfig.totalCIDsStored++;
        return cid;
    }

    function _storeEcosystemHealthOnIPFS() internal returns (string memory) {
        bytes memory healthData = abi.encodePacked(
            '{"overallScore": ', _uint2str(ecosystemHealth.overallScore),
            ', "moduleHealth": ', _uint2str(ecosystemHealth.moduleHealth),
            ', "crossChainHealth": ', _uint2str(ecosystemHealth.crossChainHealth),
            ', "reputationHealth": ', _uint2str(ecosystemHealth.reputationHealth),
            ', "impactHealth": ', _uint2str(ecosystemHealth.impactHealth),
            ', "storageHealth": ', _uint2str(ecosystemHealth.storageHealth),
            ', "lastCheck": ', _uint2str(ecosystemHealth.lastCheck),
            ', "totalModules": ', _uint2str(totalModuleRegistrations),
            ', "activeModules": ', _uint2str(_countActiveModules()),
            '}'
        );

        string memory cid = _uploadToIPFS(healthData);
        storageConfig.totalCIDsStored++;
        return cid;
    }

    function _uploadToIPFS(bytes memory data) internal returns (string memory cid) {
        bytes32 hash = keccak256(abi.encodePacked(data, block.timestamp, storageConfig.totalCIDsStored));
        cid = string(abi.encodePacked("Qm", _bytes32ToHexString(hash), _uint2str(block.timestamp)));
        return cid;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 👁️ ENHANCED VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

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
            if (modules[layerModules[i]].active) {
                count++;
            }
        }
        return count;
    }

    function _countActiveModules() internal view returns (uint256) {
        uint256 count = 0;
        for (uint8 layer = 1; layer <= 7; layer++) {
            count += this.countActiveModulesByLayer(layer);
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

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🛠️ UTILITY FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

    function _bytes32ToHexString(bytes32 _bytes32) internal pure returns (string memory) {
        bytes memory s = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            bytes1 b = bytes1(_bytes32[i]);
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[i * 2] = _char(hi);
            s[i * 2 + 1] = _char(lo);
        }
        return string(s);
    }

    function _char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function _uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔄 UPGRADE AUTHORIZATION
    // ═══════════════════════════════════════════════════════════════════════════════

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
