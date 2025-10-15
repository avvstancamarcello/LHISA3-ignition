// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

// Copyright © 2025 Avv. Marcello Stanca - Firenze, Italia. All Rights Reserved.
//
// Hoc contractum, pars 'Solidary System', ab Auctore Marcello Stanca Caritati Internationali (MCMLXXVI) gratis conceditur.
// (This smart contract, part of the 'Solidary System', is granted for free use to Caritas Internationalis (1976) by the author, Marcello Stanca.)

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol"; // NUOVA SINAPSI: Aggiungiamo la capacità di evolvere

/**
 * @title SolidaryHub (Rector Orbis - The Ruler of the World)
 * @author Avv. Marcello Stanca - Architectus Aequitatis
 * @notice Cor Aetereum et Director Orchestae Oecosystematis 'Solidary System'. Hic, omnes moduli in unam symphoniam caritatis conveniunt.
 * (English: The Ethereal Heart and Orchestra Director of the 'Solidary System'. Here, all modules converge into a single symphony of charity.)
 * @dev "Canto I - Hub del Paradiso Solidale". Sicut sol in centro systematis solaris, hic contractus omnes planetas in orbita sua tenet, eorum motus coordinans et harmoniam universalem praestans. Est Prima Causa non mota ex qua omnis actio legitima in galaxia nostra procedit.
 * (English: "Canto I - Hub of the Solidary Paradise". Like the sun at the center of the solar system, this contract holds all planets in their orbit, coordinating their movements and ensuring universal harmony. It is the Unmoved Mover from which all legitimate action in our galaxy proceeds.)
 */
contract SolidaryHub is Initializable, AccessControlUpgradeable, PausableUpgradeable, UUPSUpgradeable {

    // ... (ROLES & STATE VARIABLES rimangono invariati nella loro struttura) ...
    bytes32 public constant ECOSYSTEM_ADMIN = keccak256("ECOSYSTEM_ADMIN");
    bytes32 public constant MODULE_MANAGER = keccak256("MODULE_MANAGER");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    struct ModuleInfo {
        address contractAddress;
        string moduleName;
        uint8 layer;
        bool active;
        uint256 version;
    }

    mapping(uint8 => address[]) public modulesByLayer;
    mapping(address => ModuleInfo) public modules;
    mapping(string => address) public moduleByName;

    struct EcosystemState {
        uint256 totalUsers;
        uint256 totalImpact;
        uint256 globalReputation;
        bool emergencyMode;
    }

    EcosystemState public ecosystemState;

    event ModuleRegistered(address indexed moduleAddress, string moduleName, uint8 layer);
    event ModuleActivated(address indexed moduleAddress, bool status);
    event EcosystemStateUpdated(uint256 totalUsers, uint256 totalImpact);
    event EmergencyTriggered(address indexed trigger, string reason);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // --- MODIFICATO: La funzione ora accetta un 'initialAdmin' per la massima chiarezza e sicurezza ---
    function initialize(address initialAdmin) public initializer {
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        // Consecratio Munerum (Consecration of Roles)
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(ECOSYSTEM_ADMIN, initialAdmin);
        _grantRole(MODULE_MANAGER, initialAdmin);
        _grantRole(EMERGENCY_ROLE, initialAdmin);

        ecosystemState = EcosystemState({
            totalUsers: 0,
            totalImpact: 0,
            globalReputation: 0,
            emergencyMode: false
        });
    }

    // ... (Tutte le altre funzioni rimangono logicamente invariate, ma ora sono parte di un contratto aggiornabile) ...
    
    // 🔗 GESTIO MODULORUM (MODULE MANAGEMENT)
    function registerModule(address contractAddress, string memory moduleName, uint8 layer) external onlyRole(MODULE_MANAGER) {
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

    function setModuleStatus(address moduleAddress, bool active) external onlyRole(MODULE_MANAGER) {
        require(modules[moduleAddress].contractAddress != address(0), "Module not registered");
        modules[moduleAddress].active = active;
        emit ModuleActivated(moduleAddress, active);
    }

    // 🌐 ORCHESTRATIO OECOSYSTEMATIS (ECOSYSTEM ORCHESTRATION)
    function updateEcosystemState(uint256 newUsers, uint256 newImpact, uint256 newReputation) external onlyRole(ORACLE_ROLE) whenNotPaused {
        ecosystemState.totalUsers += newUsers;
        ecosystemState.totalImpact += newImpact;
        ecosystemState.globalReputation = newReputation;
        emit EcosystemStateUpdated(ecosystemState.totalUsers, ecosystemState.totalImpact);
    }

    function crossModuleCall(address targetModule, bytes calldata data) external returns (bytes memory) {
        require(modules[targetModule].active, "Target module not active");
        require(hasRole(MODULE_MANAGER, msg.sender) || hasRole(ECOSYSTEM_ADMIN, msg.sender), "Unauthorized cross-call");
        (bool success, bytes memory result) = targetModule.call(data);
        require(success, "Cross-module call failed");
        return result;
    }

    // 🚨 FUNCTIONES SUBITARIAE (EMERGENCY FUNCTIONS)
    function triggerEmergency(string memory reason) external onlyRole(EMERGENCY_ROLE) {
        _pause();
        ecosystemState.emergencyMode = true;
        emit EmergencyTriggered(msg.sender, reason);
    }

    function resolveEmergency() external onlyRole(EMERGENCY_ROLE) {
        _unpause();
        ecosystemState.emergencyMode = false;
    }

    // 👁️ FUNCTIONES INTUENDI (VIEW FUNCTIONS)
    function getModuleInfo(address moduleAddress) external view returns (ModuleInfo memory) {
        return modules[moduleAddress];
    }
    function getModulesByLayer(uint8 layer) external view returns (address[] memory) {
        return modulesByLayer[layer];
    }
    function getModuleByName(string memory moduleName) external view returns (address) {
        return moduleByName[moduleName];
    }
    function getEcosystemState() external view returns (EcosystemState memory) {
        return ecosystemState;
    }
    function isEmergencyMode() external view returns (bool) {
        return ecosystemState.emergencyMode || paused();
    }

    // ⚡ FUNCTIONES UTILITATIS (UTILITY FUNCTIONS)
    function calculateEcosystemHealth() external view returns (uint256) {
        if (ecosystemState.totalUsers == 0) return 0;
        return (ecosystemState.totalImpact + ecosystemState.globalReputation) / ecosystemState.totalUsers;
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

    // 🔄 AUCTORITAS EMENDANDI (UPGRADEABILITY)
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
