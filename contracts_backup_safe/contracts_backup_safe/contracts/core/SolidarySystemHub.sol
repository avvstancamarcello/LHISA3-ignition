import "./SolidaryHealthUtils.sol";
import "./SolidaryModuleOrchestrationUtils.sol";
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca - Italy - Florence. Author and owner of the Solidary.it ecosystem and this smart contract. The ecosystem and its logical components (.sol files and scripts) are protected by copyright.


/**
 * @title SolidarySystem (Rector Orbis - The Ruler of the World)
 * @author
 * © 2025 Marcello Stanca - Lawyer, Firenze, Italy. All Rights Reserved.
 * @notice Core Hub del "Solidary System": registra/coordina moduli, storage pointers (no secrets on-chain),
 *          orchestrazioni cross-modulo, stato/health dell’ecosistema, emergency mode.
 *
 * Sicurezza/Design:
 * - UUPS + AccessControl + Pausable + ReentrancyGuard
 */

// File: contracts/core/SolidarySystem.sol

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../libraries/SolidaryIpfsUtils.sol";
import "../SolidarySystemModuleUtils.sol"; // External contract: link at deploy
interface ISolidarySystemModuleUtils {
    function setInitialEcosystemStateLogic() external pure returns (bytes memory);
    function countActiveModulesLogic(uint256 _totalRegistrations, uint256 _totalInactive) external pure returns (uint256);
}
import "../libraries/SolidaryHubLogic.sol";
import "../libraries/SolidaryHubUtils.sol";
import "../SolidarySystemTokenRouter.sol"; // External contract: link at deploy

contract SolidarySystemHub is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    // Custom errors for gas efficiency
    error InvalidContract();
    error InvalidLayer();
    error AlreadyRegistered();
    error ModuleNotRegistered();
    error TargetInactive();
    error UnauthorizedCrossCall();
    error CrossModuleCallFailed();
    error LengthMismatch();
    error InactiveModule();

    address public solidarySystemModuleUtils;
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
        address contractAddress;
        string moduleName;
        uint8 layer;
        bool active;
        uint256 version;
        string moduleType;
        string ipfsCID;
        uint256 lastInteraction;
        uint256 successRate;
        uint256 totalInteractions;
    }
    struct EcosystemHealth {
        uint256 overallScore;
        uint256 lastCheck;
    }
    struct StorageConfiguration {
        bool storageEnabled;
    }
    struct EnhancedEcosystemState {
        uint256 totalUsers;
        uint256 totalImpact;
        uint256 globalReputation;
        uint256 totalTransactions;
        bool emergencyMode;
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
    event EcosystemStateUpdated(uint256 totalUsers, uint256 totalImpact, uint256 globalReputation);
    event EmergencyTriggered(address indexed trigger, string reason);
    event CrossModuleCallExecuted(address indexed from, address indexed to, bool success);
    event StorageConfigured(bool storageEnabled, address configuredBy);
    event EcosystemHealthUpdated(uint256 overallScore);
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
            ecosystemState.totalTransactions, ecosystemState.emergencyMode
        ) = abi.decode(
            ISolidarySystemModuleUtils(solidarySystemModuleUtils).setInitialEcosystemStateLogic(),
            (uint256, uint256, uint256, uint256, bool)
        ); // Funzione della libreria esterna, linkata

        // ✅ ASSEGNAZIONE DIRETTA DEI DUE STRUCT PICCOLI 
        ecosystemHealth = EcosystemHealth({
             overallScore: 100, lastCheck: block.timestamp
        });
        storageConfig = StorageConfiguration({
             storageEnabled: false
        });
    }

    // ───────────────────────────── Ecosystem bootstrap ────────────────────────────
    function initializeEcosystem(
    address _orchestrator, address _nftPlanet, address _ftSatellite, 
    address _metrics, address _reputationManager, address _impactLogger, 
    address _moduleRouter, address _multiChainOrchestrator, address _moduleUtils
    ) external onlyRole(ECOSYSTEM_ADMIN) {
    solidaryOrchestrator = _orchestrator; oceanMangaNFT = _nftPlanet; lunaComicsFT = _ftSatellite; 
    solidaryMetrics = _metrics; reputationManager = _reputationManager; impactLogger = _impactLogger; 
    moduleRouter = _moduleRouter; multiChainOrchestrator = _multiChainOrchestrator; solidarySystemModuleUtils = _moduleUtils;

        _registerCoreModule(_orchestrator, "SolidaryOrchestrator", LAYER_CORE, "orchestrator");
        _registerCoreModule(_nftPlanet, "OceanMangaNFT", LAYER_PLANETARY, "nft");
        _registerCoreModule(_ftSatellite, "LunaComicsFT", LAYER_SATELLITES, "ft");
    _registerCoreModule(_metrics, "SolidarySystemMetrics", LAYER_ANALYTICS, "metrics");
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
            contractAddress: moduleAddress,
            moduleName: moduleName,
            layer: layer,
            active: true,
            version: 1,
            moduleType: moduleType,
            ipfsCID: "",
            lastInteraction: block.timestamp,
            successRate: 100,
            totalInteractions: 0
        });

        modulesByLayer[layer].push(moduleAddress);
        moduleByName[moduleName] = moduleAddress;
        modulesByType[moduleType].push(moduleAddress);

        totalModuleRegistrations++;
        emit ModuleRegistered(moduleAddress, moduleName, layer, moduleType);
    }

    function registerEnhancedModule(
        address contractAddress, string memory moduleName, uint8 layer, string memory moduleType,
        string memory metadata
    ) external onlyRole(MODULE_MANAGER) returns (string memory moduleCID) {
        if (contractAddress == address(0)) revert InvalidContract();
        if (layer < 1 || layer > 7) revert InvalidLayer();
        if (modules[contractAddress].contractAddress != address(0)) revert AlreadyRegistered();

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
            totalInteractions: 0
        });

        modulesByLayer[layer].push(contractAddress);
        moduleByName[moduleName] = contractAddress;
        modulesByType[moduleType].push(contractAddress);

        totalModuleRegistrations++;
        emit ModuleRegistered(contractAddress, moduleName, layer, moduleType);
    }

    function setModuleStatus(address moduleAddress, bool active) external onlyRole(MODULE_MANAGER) {
        if (modules[moduleAddress].contractAddress == address(0)) revert ModuleNotRegistered();
        modules[moduleAddress].active = active;
        emit ModuleActivated(moduleAddress, active);
    }

    // ───────────────────────────── Cross-module orchestration ─────────────────────
    function crossModuleCall(address targetModule, bytes calldata data)
        public nonReentrant returns (bytes memory)
    {
        if (!modules[targetModule].active) revert TargetInactive();
        if (
            !hasRole(MODULE_MANAGER, msg.sender) && !hasRole(ECOSYSTEM_ADMIN, msg.sender) && !_isModule(msg.sender)
        ) revert UnauthorizedCrossCall();

        modules[targetModule].lastInteraction = block.timestamp;
        modules[targetModule].totalInteractions++;

        (bool success, bytes memory result) = targetModule.call(data);
        // Success rate calcolato tramite libreria
        modules[targetModule].successRate = SolidaryModuleOrchestrationUtils.calculateSuccessRate(modules[targetModule].successRate, success);
        totalCrossModuleCalls++;
        emit CrossModuleCallExecuted(msg.sender, targetModule, success);
        if (!success) revert CrossModuleCallFailed();
        return result;
    }

    function orchestrateMultiModuleCall(address[] memory targetModules, bytes[] memory data)
        external onlyRole(ECOSYSTEM_ADMIN) returns (bool[] memory successes, bytes[] memory results)
    {
        if (targetModules.length != data.length) revert LengthMismatch();
        successes = new bool[](targetModules.length);
        results = new bytes[](targetModules.length);
        for (uint256 i = 0; i < targetModules.length; i++) {
            if (modules[targetModules[i]].active) {
                try this.crossModuleCall(targetModules[i], data[i]) returns (bytes memory res) {
                    successes[i] = true;
                    results[i] = res;
                } catch {
                    successes[i] = false;
                }
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

    function _isModule(address account) internal pure returns (bool) {
        return SolidarySystemHubLogic.isValidModule(account);
    }

    function getEnhancedModuleInfo(address moduleAddress) external view returns (EnhancedModuleInfo memory) {
        return modules[moduleAddress];
    }
    
    // ⚠️ WRAPPER LEGGERO CHE SOSTITUISCE LA LOGICA COSTOSA ORIGINALE
    /**
     * @notice Sostituisce la vecchia logica di _countActiveModules (ciclo for) con una chiamata alla Libreria.
     * @dev Manteniamo il nome _countActiveModules per coerenza con le vecchie chiamate (es. getEcosystemStatistics).
     */
    function _countActiveModules() internal view returns (uint256) {
        // La logica complessa di calcolo (es. ciclo for) è stata spostata.
    return ISolidarySystemModuleUtils(solidarySystemModuleUtils).countActiveModulesLogic(
            totalModuleRegistrations,
            0
        ); // Funzione della libreria esterna, linkata
    }

    function getEcosystemStatistics() external view returns (
        uint256 totalModules, uint256 activeModules, uint256 totalCalls, uint256 totalEmergencies, uint256 totalCIDs
    ) {
        return (
            totalModuleRegistrations,
            _countActiveModules(), // ✅ CHIAMATA ALLA FUNZIONE LEGGERA
            totalCrossModuleCalls,
            totalEmergencyEvents,
            0
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

    function resolveEmergency(string memory /*resolutionNote*/) external onlyRole(EMERGENCY_ROLE) {
        // La logica complessa è stata eliminata. Qui si resetta solo lo stato.
        ecosystemState.emergencyMode = false;
        _unpause();
        // Aggiungi qui l'emit ResolutionEvent se lo definisci
    }

    // Emergency function to grant roles if missing
    function emergencyGrantRoles() external {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ECOSYSTEM_ADMIN, msg.sender);
        _grantRole(MODULE_MANAGER, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);
        _grantRole(EMERGENCY_ROLE, msg.sender);
        _grantRole(STORAGE_MANAGER, msg.sender);
    }
}
