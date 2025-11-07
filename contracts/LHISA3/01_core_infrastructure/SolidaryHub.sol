// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca Lawyer - ITALY Florence
// Canto I - Hub del Paradiso Solidale - Divina Commedia della Solidarietà Blockchain

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title SolidaryHub
 * @dev Contratto orchestratore centrale per l'ecosistema planetario Solidary
 * @notice Coordina l'interazione tra tutti i 50 smart contract dell'ecosistema
 */
contract SolidaryHub is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔐 ROLES & PERMISSIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    bytes32 public constant ECOSYSTEM_ADMIN = keccak256("ECOSYSTEM_ADMIN");
    bytes32 public constant MODULE_MANAGER = keccak256("MODULE_MANAGER");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    struct ModuleInfo {
        address contractAddress;
        string moduleName;
        uint8 layer; // 1-7 according to architecture
        bool active;
        uint256 version;
    }
    
    // Mapping dei moduli per layer
    mapping(uint8 => address[]) public modulesByLayer;
    mapping(address => ModuleInfo) public modules;
    mapping(string => address) public moduleByName;
    
    // Stato globale dell'ecosistema
    struct EcosystemState {
        uint256 totalUsers;
        uint256 totalImpact;
        uint256 globalReputation;
        bool emergencyMode;
    }
    
    EcosystemState public ecosystemState;
    
    // Eventi
    event ModuleRegistered(address indexed moduleAddress, string moduleName, uint8 layer);
    event ModuleActivated(address indexed moduleAddress, bool status);
    event EcosystemStateUpdated(uint256 totalUsers, uint256 totalImpact);
    event EmergencyTriggered(address indexed trigger, string reason);
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏗️ CONSTRUCTOR & INITIALIZER
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(address admin) public initializer {
        __AccessControl_init();
        __Pausable_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ECOSYSTEM_ADMIN, admin);
        _grantRole(MODULE_MANAGER, admin);
        _grantRole(EMERGENCY_ROLE, admin);
        
        ecosystemState = EcosystemState({
            totalUsers: 0,
            totalImpact: 0,
            globalReputation: 0,
            emergencyMode: false
        });
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔗 MODULE MANAGEMENT
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Registra un nuovo modulo nell'ecosistema
     * @param contractAddress Indirizzo del contratto modulo
     * @param moduleName Nome identificativo del modulo
     * @param layer Layer architetturale (1-7)
     */
    function registerModule(
        address contractAddress,
        string memory moduleName,
        uint8 layer
    ) external onlyRole(MODULE_MANAGER) {
        require(contractAddress != address(0), "Invalid contract address");
        require(layer >= 1 && layer <= 7, "Invalid layer");
        require(modules[contractAddress].contractAddress == address(0), "Module already registered");
        
        modules[contractAddress] = ModuleInfo({
            contractAddress: contractAddress,
            moduleName: moduleName,
            layer: layer,
            active: true,
            version: 1
        });
        
        modulesByLayer[layer].push(contractAddress);
        moduleByName[moduleName] = contractAddress;
        
        emit ModuleRegistered(contractAddress, moduleName, layer);
    }
    
    /**
     * @dev Attiva/disattiva un modulo
     */
    function setModuleStatus(address moduleAddress, bool active) 
        external onlyRole(MODULE_MANAGER) {
        require(modules[moduleAddress].contractAddress != address(0), "Module not registered");
        modules[moduleAddress].active = active;
        emit ModuleActivated(moduleAddress, active);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌐 ECOSYSTEM ORCHESTRATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Aggiorna lo stato globale dell'ecosistema
     */
    function updateEcosystemState(
        uint256 newUsers,
        uint256 newImpact,
        uint256 newReputation
    ) external onlyRole(ORACLE_ROLE) whenNotPaused {
        ecosystemState.totalUsers += newUsers;
        ecosystemState.totalImpact += newImpact;
        ecosystemState.globalReputation = newReputation;
        
        emit EcosystemStateUpdated(ecosystemState.totalUsers, ecosystemState.totalImpact);
    }
    
    /**
     * @dev Esegue una chiamata cross-module
     */
    function crossModuleCall(
        address targetModule,
        bytes calldata data
    ) external returns (bytes memory) {
        require(modules[targetModule].active, "Target module not active");
        require(hasRole(MODULE_MANAGER, msg.sender), "Unauthorized cross-call");
        
        (bool success, bytes memory result) = targetModule.call(data);
        require(success, "Cross-module call failed");
        
        return result;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🚨 EMERGENCY FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Attiva modalità emergenza globale
     */
    function triggerEmergency(string memory reason) 
        external onlyRole(EMERGENCY_ROLE) {
        _pause();
        ecosystemState.emergencyMode = true;
        emit EmergencyTriggered(msg.sender, reason);
    }
    
    /**
     * @dev Disattiva modalità emergenza
     */
    function resolveEmergency() external onlyRole(EMERGENCY_ROLE) {
        _unpause();
        ecosystemState.emergencyMode = false;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 👁️ VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Ottiene informazioni su un modulo
     */
    function getModuleInfo(address moduleAddress) 
        external view returns (ModuleInfo memory) {
        return modules[moduleAddress];
    }
    
    /**
     * @dev Ottiene tutti i moduli di un layer
     */
    function getModulesByLayer(uint8 layer) 
        external view returns (address[] memory) {
        return modulesByLayer[layer];
    }
    
    /**
     * @dev Ottiene l'indirizzo di un modulo per nome
     */
    function getModuleByName(string memory moduleName) 
        external view returns (address) {
        return moduleByName[moduleName];
    }
    
    /**
     * @dev Ottiene lo stato dell'ecosistema
     */
    function getEcosystemState() external view returns (EcosystemState memory) {
        return ecosystemState;
    }
    
    /**
     * @dev Verifica se l'ecosistema è in modalità emergenza
     */
    function isEmergencyMode() external view returns (bool) {
        return ecosystemState.emergencyMode || paused();
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // ⚡ UTILITY FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Calcola l'health score dell'ecosistema
     */
    function calculateEcosystemHealth() external view returns (uint256) {
        if (ecosystemState.totalUsers == 0) return 0;
        
        // Formula: (impatto_totale + reputazione_globale) / utenti_totali
        return (ecosystemState.totalImpact + ecosystemState.globalReputation) / ecosystemState.totalUsers;
    }
    
    /**
     * @dev Conta i moduli attivi per layer
     */
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
}