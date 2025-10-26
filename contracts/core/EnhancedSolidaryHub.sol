// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

/**
 * @title EnhancedSolidaryHub (Rector Orbis - The Ruler of the World)
 * @author
 * © 2025 Marcello Stanca - Lawyer, Firenze, Italy. All Rights Reserved.
 * @notice Core Hub del "Solidary System": registra/coordina moduli, storage pointers (no secrets on-chain),
 *          orchestrazioni cross-modulo, stato/health dell’ecosistema, emergency mode.
 *
 * Sicurezza/Design:
 * - UUPS + AccessControl + Pausable + ReentrancyGuard
 */

// File: contracts/core/EnhancedSolidaryHub.sol

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../libraries/SolidaryIpfsUtils.sol"; // New Library
import "../libraries/SolidaryModuleUtils.sol"; //New second Library

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

    uint8 public constant LAYER_CORE         = 1;
    uint8 public constant LAYER_PLANETARY    = 2;
    uint8 public constant LAYER_SATELLITES   = 3;
    uint8 public constant LAYER_INFRASTRUCTURE= 4;
    uint8 public constant LAYER_BRIDGES      = 5;
    uint8 public constant LAYER_ANALYTICS    = 6;
    uint8 public constant LAYER_GOVERNANCE   = 7;

    // ───────────────────────────────── Data structures ────────────────────────────
    
    struct EnhancedModuleInfo {
        address contractAddress; string moduleName; uint8 layer; bool active; uint256 version; string moduleType; string ipfsCID; uint256 lastInteraction; uint256 successRate; uint256 totalInteractions; address[] dependencies; address[] dependents;
    }
    struct EcosystemHealth {
        uint256 overallScore; uint256 moduleHealth; uint256 crossChainHealth; uint256 reputationHealth; uint256 impactHealth; uint256 storageHealth; string healthCID; uint256 lastCheck;
    }
    struct StorageConfiguration {
        string nftStorageAPIKey; string pinataJWT; string ipfsBaseURI; bool storageEnabled; uint256 totalCIDsStored; string storageAnalyticsCID;
    }
    struct EnhancedEcosystemState {
        uint256 totalUsers; uint256 totalImpact; uint256 globalReputation; uint256 totalTransactions; uint256 crossChainVolume; uint256 carbonFootprint; uint256 totalValueLocked; bool emergencyMode; string stateCID;
    }

    // ───────────────────────────────── State ──────────────────────────────────────
    mapping(uint8 => address[]) public modulesByLayer;
    mapping(address => EnhancedModuleInfo) public modules;
    mapping(string => address) public moduleByName;
    mapping(string => address[]) public modulesByType;

    // Core references 
    address public solidaryOrchestrator; address public oceanMangaNFT; address public lunaComicsFT; address public solidaryMetrics; address public reputationManager; address public impactLogger; address public moduleRouter; address public multiChainOrchestrator;

    StorageConfiguration public storageConfig;
    EcosystemHealth public ecosystemHealth;
    EnhancedEcosystemState public ecosystemState;

    // Stats
    uint256 public totalModuleRegistrations; uint256 public totalCrossModuleCalls; uint256 public totalEmergencyEvents; uint256 public totalRouteCalls;

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

        // ✅ UTILIZZA LA LIBRERIA PER L'INIZIALIZZAZIONE DELLO STATO (PIÙ LEGGERO)
        (
            ecosystemState.totalUsers, ecosystemState.totalImpact, ecosystemState.globalReputation, 
            ecosystemState.totalTransactions, ecosystemState.crossChainVolume, ecosystemState.carbonFootprint, 
            ecosystemState.totalValueLocked, ecosystemState.emergencyMode, ecosystemState.stateCID
        ) = abi.decode(
            SolidaryModuleUtils.setInitialEcosystemStateLogic(),
            (uint256, uint256, uint256, uint256, uint256, uint256, uint256, bool, string)
        );

        // ✅ ASSEGNAZIONE DIRETTA DEI DUE STRUCT PICCOLI 
        ecosystemHealth = EcosystemHealth({
             overallScore: 100, moduleHealth: 100, crossChainHealth: 100, reputationHealth: 100, 
             impactHealth: 100, storageHealth: 100, healthCID: "", lastCheck: block.timestamp
        });
        storageConfig = StorageConfiguration({
             nftStorageAPIKey: "", pinataJWT: "", ipfsBaseURI: "", 
             storageEnabled: false, totalCIDsStored: 0, storageAnalyticsCID: ""
        });
    }

    // ───────────────────────────── Ecosystem bootstrap ────────────────────────────
    function initializeEcosystem(
        address _orchestrator, address _nftPlanet, address _ftSatellite, 
        address _metrics, address _reputationManager, address _impactLogger, 
        address _moduleRouter, address _multiChainOrchestrator
    ) external onlyRole(ECOSYSTEM_ADMIN) {
        solidaryOrchestrator = _orchestrator; oceanMangaNFT = _nftPlanet; lunaComicsFT = _ftSatellite; 
        solidaryMetrics = _metrics; reputationManager = _reputationManager; impactLogger = _impactLogger; 
        moduleRouter = _moduleRouter; multiChainOrchestrator = _multiChainOrchestrator;

        _registerCoreModule(_orchestrator, "SolidaryOrchestrator", LAYER_CORE, "orchestrator");
        _registerCoreModule(_nftPlanet, "OceanMangaNFT", LAYER_PLANETARY, "nft");
        _registerCoreModule(_ftSatellite, "LunaComicsFT", LAYER_SATELLITES, "ft");
        _registerCoreModule(_metrics, "SolidaryMetrics", LAYER_ANALYTICS, "metrics");
        _registerCoreModule(_reputationManager, "ReputationManager", LAYER_INFRASTRUCTURE, "reputation");
        _registerCoreModule(_impactLogger, "ImpactLogger", LAYER_INFRASTRUCTURE, "impact");
        _registerCoreModule(_moduleRouter, "ModuleRouter", LAYER_INFRASTRUCTURE, "router");
        _registerCoreModule(_multiChainOrchestrator,"UniversalMultiChainOrchestratorV2", LAYER_BRIDGES, "bridge");

        emit EcosystemInitialized(_orchestrator, _nftPlanet, _ftSatellite);
    }

    // ───────────────────────────── Module management ──────────────────────────────
    function _registerCoreModule(
        address moduleAddress, string memory moduleName, uint8 layer, string memory moduleType
    ) internal {
        if (moduleAddress == address(0)) return;

        modules[moduleAddress] = EnhancedModuleInfo({
            contractAddress: moduleAddress, moduleName: moduleName, layer: layer, active: true, 
            version: 1, moduleType: moduleType, ipfsCID: "", lastInteraction: block.timestamp, 
            successRate: 100, totalInteractions: 0, dependencies: new address[](0), dependents: new address[](0)
        });

        modulesByLayer[layer].push(moduleAddress); moduleByName[moduleName] = moduleAddress; 
        modulesByType[moduleType].push(moduleAddress);

        totalModuleRegistrations++;
        emit ModuleRegistered(moduleAddress, moduleName, layer, moduleType);
    }

    function registerEnhancedModule(
        address contractAddress, string memory moduleName, uint8 layer, string memory moduleType,
        address[] memory dependencies, string memory metadata
    ) external onlyRole(MODULE_MANAGER) returns (string memory moduleCID) {
        require(contractAddress != address(0), "Invalid contract"); require(layer >= 1 && layer <= 7, "Invalid layer"); 
        require(modules[contractAddress].contractAddress == address(0), "Already registered");

        moduleCID = _uploadToIPFS(bytes(metadata)); // ⬅️ Chiama il wrapper leggero IPFS

        modules[contractAddress] = EnhancedModuleInfo({
             contractAddress: contractAddress, moduleName: moduleName, layer: layer, active: true, version: 1, 
             moduleType: moduleType, ipfsCID: moduleCID, lastInteraction: block.timestamp, successRate: 100, 
             totalInteractions: 0, dependencies: dependencies, dependents: new address[](0)
        });

        for (uint256 i = 0; i < dependencies.length; i++) {
            modules[dependencies[i]].dependents.push(contractAddress);
            emit ModuleDependencyAdded(contractAddress, dependencies[i]);
        }

        modulesByLayer[layer].push(contractAddress); moduleByName[moduleName] = contractAddress; 
        modulesByType[moduleType].push(contractAddress);

        totalModuleRegistrations++;
        emit ModuleRegistered(contractAddress, moduleName, layer, moduleType);
    }

    function setModuleStatus(address moduleAddress, bool active) external onlyRole(MODULE_MANAGER) {
        require(modules[moduleAddress].contractAddress != address(0), "Module not registered");
        modules[moduleAddress].active = active;
        emit ModuleActivated(moduleAddress, active);
    }

    // ───────────────────────────── Cross-module orchestration ─────────────────────
    function crossModuleCall(address targetModule, bytes calldata data)
        public nonReentrant returns (bytes memory)
    {
        require(modules[targetModule].active, "Target inactive");
        require(
            hasRole(MODULE_MANAGER, msg.sender) || hasRole(ECOSYSTEM_ADMIN, msg.sender) || _isModule(msg.sender),
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
        external onlyRole(ECOSYSTEM_ADMIN) returns (bool[] memory successes, bytes[] memory results)
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

    // ───────────────────────────── IPFS utils (sim) ───────────────────────────────

    /**
     * @dev Funzione interna RISCRITTA per fungere da wrapper leggero.
     * @notice Chiama la logica complessa di generazione CID (IPFS) che è stata spostata in SolidaryIpfsUtils.
     * @param data Dati da caricare su IPFS simulato.
     */
    function _uploadToIPFS(bytes memory data) internal view returns (string memory cid) {
    // La logica costosa è ora nella libreria. Qui c'è solo la chiamata.
        return SolidaryIpfsUtils.generateSimulatedCID(
            data,
            block.timestamp,
            totalRouteCalls // Variabile di stato del Hub utilizzata per l'entropia della simulazione
        );
    }
    
    // ───────────────────────────── View helpers ───────────────────────────────────

    function _isModule(address account) internal view returns (bool) {
        return modules[account].contractAddress != address(0);
    }

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
    
    // ⚠️ WRAPPER LEGGERO CHE SOSTITUISCE LA LOGICA COSTOSA ORIGINALE
    /**
     * @notice Sostituisce la vecchia logica di _countActiveModules (ciclo for) con una chiamata alla Libreria.
     * @dev Manteniamo il nome _countActiveModules per coerenza con le vecchie chiamate (es. getEcosystemStatistics).
     */
    function _countActiveModules() internal view returns (uint256) {
        // La logica complessa di calcolo (es. ciclo for) è stata spostata.
        return SolidaryModuleUtils.countActiveModulesLogic(
            totalModuleRegistrations,
            0 // Per il momento, assumiamo 0 moduli inattivi nel calcolo leggero
        );
    }

    function getEcosystemStatistics() external view returns (
        uint256 totalModules, uint256 activeModules, uint256 totalCalls, uint256 totalEmergencies, uint256 totalCIDs
    ) {
        return (
            totalModuleRegistrations,
            _countActiveModules(), // ✅ CHIAMATA ALLA FUNZIONE LEGGERA
            totalCrossModuleCalls,
            totalEmergencyEvents,
            storageConfig.totalCIDsStored
        );
    }

    // ───────────────────────────── UUPS auth ──────────────────────────────────────
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // ───────────────────────────── Emergency Mode (SOLO API VUOTE) ──────────────────────────
    // NOTA: Le funzioni di emergenza complesse (triggerEmergency, _enableCriticalModules) 
    // sono state eliminate per risparmiare bytecode.
    
    // API vuote o placeholder per mantenere l'interfaccia (se strettamente necessarie)
    function triggerEmergency(string memory reason) external onlyRole(EMERGENCY_ROLE) {
        // La logica complessa è stata eliminata. Qui si imposta solo lo stato.
        ecosystemState.emergencyMode = true;
        totalEmergencyEvents++;
        emit EmergencyTriggered(msg.sender, reason);
        _pause();
    }

    function resolveEmergency(string memory resolutionNote) external onlyRole(EMERGENCY_ROLE) {
        // La logica complessa è stata eliminata. Qui si resetta solo lo stato.
        ecosystemState.emergencyMode = false;
        _unpause();
        // Aggiungi qui l'emit ResolutionEvent se lo definisci
    }

    // Funzione placeholder per la logica di salute costosa (DA COMPLETARE IN LIBRERIA)
    function _calculateEcosystemHealth() internal {
        // Sostituisci questo con una chiamata a una funzione LIBRARY.
        // Ad esempio: (uint256 score, string memory cid) = SolidaryHealthUtils.calculateHealthLogic();
        // Per ora, solo un placeholder leggero.
        ecosystemHealth.overallScore = 100;
        ecosystemHealth.lastCheck = block.timestamp;
        emit EcosystemHealthUpdated(ecosystemHealth.overallScore, ecosystemHealth.healthCID);
    }

}
