// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

// Copyright © 2025 Avv. Marcello Stanca - Firenze, Italia. All Rights Reserved.
// Hoc contractum, pars Solidary Solar System, ab Auctore Marcello Stanca
// ad solam Caritas Internationalis (MCMLXXVI) usum conceditur.
//
// This smart contract, part of the Solidary Solar System,
// is conceived by the author as a system of ethical finance with automatic balancing,
// with native anti-speculation stabilization.

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SolidaryOrchestrator is UUPSUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    bytes32 public constant STELLAR_GOVERNOR = keccak256("STELLAR_GOVERNOR");
    bytes32 public constant PLANET_MANAGER = keccak256("PLANET_MANAGER");
    bytes32 public constant SATELLITE_MANAGER = keccak256("SATELLITE_MANAGER");

    // 🌌 SOLAR SYSTEM COMPONENTS
    address public mareaMangaNFT;
    address public lunaComicsFT;

    // 📊 UNIVERSAL STATISTICS
    uint256 public totalQuantumLinks;
    uint256 public totalStellarValue;
    uint256 public universeCreationTime;
    bool public solarSystemInitialized;

    // 🗄️ ENHANCED STORAGE CONFIGURATION
    string public nftStorageAPIKey;
    string public pinataJWT;
    address public metricsContract;
    address public nftPlanetContract;
    address public ftSatelliteContract;

    // 🌠 COSMIC EVENTS
    event PlanetDeployed(address planet);
    event SatelliteDeployed(address satellite);
    event SolarSystemInitialized();
    event QuantumLinkCreated(uint256 nftId, uint256 ftAmount, uint256 timestamp);
    event StellarValueUpdated(uint256 newValue);
    event GravitationalHarmonyAchieved(uint256 harmonyLevel);
    event StorageConfigured(address indexed configurator, string storageType, uint256 timestamp);
    event ContractLinked(address indexed contractAddress, string contractType);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _nftStorageKey, string memory _pinataJWT) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        __Ownable_init(msg.sender);

        // 👑 INITIAL ROLE SETUP
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(STELLAR_GOVERNOR, msg.sender);
        _grantRole(PLANET_MANAGER, msg.sender);
        _grantRole(SATELLITE_MANAGER, msg.sender);

        // 🗄️ STORAGE CONFIGURATION
        nftStorageAPIKey = _nftStorageKey;
        pinataJWT = _pinataJWT;
        universeCreationTime = block.timestamp;

        emit StorageConfigured(msg.sender, "NFT_STORAGE_PINATA", block.timestamp);
    }

    // 🚀 SOLAR SYSTEM INITIALIZATION
    function initializeSolarSystem(address nftPlanet, address ftSatellite)
        external
        onlyRole(STELLAR_GOVERNOR)
    {
        require(!solarSystemInitialized, "Solar system already initialized");
        require(nftPlanet != address(0), "Invalid NFT planet address");
        require(ftSatellite != address(0), "Invalid FT satellite address");

        mareaMangaNFT = nftPlanet;
        lunaComicsFT = ftSatellite;
        solarSystemInitialized = true;

        emit PlanetDeployed(nftPlanet);
        emit SatelliteDeployed(ftSatellite);
        emit SolarSystemInitialized();
        emit GravitationalHarmonyAchieved(100); // Initial harmony level
    }

    // 🌊 QUANTUM BILOCATION CREATION
    function createQuantumLink(uint256 nftId, uint256 ftAmount)
        external
        onlyRole(PLANET_MANAGER)
        nonReentrant
        returns (bool)
    {
        require(solarSystemInitialized, "Solar system not initialized");
        require(ftAmount > 0, "FT amount must be positive");

        totalQuantumLinks++;
        totalStellarValue += ftAmount;

        // 🎯 CALCULATE HARMONY LEVEL
        uint256 harmonyLevel = _calculateHarmony();

        emit QuantumLinkCreated(nftId, ftAmount, block.timestamp);
        emit StellarValueUpdated(totalStellarValue);
        emit GravitationalHarmonyAchieved(harmonyLevel);

        return true;
    }

    // 📈 STELLAR VALUE UPDATE
    function updateStellarValue(uint256 valueIncrease)
        external
        onlyRole(SATELLITE_MANAGER)
        nonReentrant
    {
        require(valueIncrease > 0, "Value increase must be positive");

        totalStellarValue += valueIncrease;

        uint256 harmonyLevel = _calculateHarmony();

        emit StellarValueUpdated(totalStellarValue);
        emit GravitationalHarmonyAchieved(harmonyLevel);
    }

    // 🗄️ STORAGE MANAGEMENT FUNCTIONS
    function configureStorage(string memory _nftStorageKey, string memory _pinataJWT) 
        external 
        onlyRole(STELLAR_GOVERNOR) 
    {
        nftStorageAPIKey = _nftStorageKey;
        pinataJWT = _pinataJWT;
        emit StorageConfigured(msg.sender, "UPDATED_STORAGE", block.timestamp);
    }

    function linkContracts(address _metrics, address _nftPlanet, address _ftSatellite) 
        external 
        onlyRole(STELLAR_GOVERNOR) 
    {
        metricsContract = _metrics;
        nftPlanetContract = _nftPlanet;
        ftSatelliteContract = _ftSatellite;
        
        emit ContractLinked(_metrics, "METRICS");
        emit ContractLinked(_nftPlanet, "NFT_PLANET");
        emit ContractLinked(_ftSatellite, "FT_SATELLITE");
    }

    function getStorageConfig() external view returns (string memory, string memory) {
        return (nftStorageAPIKey, pinataJWT);
    }

    // 🧮 HARMONY CALCULATION
    function _calculateHarmony() internal view returns (uint256) {
        if (totalQuantumLinks == 0) return 100;

        uint256 baseHarmony = 100;
        uint256 valuePerLink = totalStellarValue / totalQuantumLinks;

        // Higher value per link = higher harmony
        if (valuePerLink > 1e18) {
            baseHarmony += 50;
        } else if (valuePerLink > 1e17) {
            baseHarmony += 25;
        }

        return baseHarmony > 150 ? 150 : baseHarmony;
    }

    // 🔧 ROLE MANAGEMENT
    function grantStellarRole(address account, bytes32 role) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(role, account);
    }

    function revokeStellarRole(address account, bytes32 role) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(role, account);
    }

    // 📊 SYSTEM INFORMATION
    function getSolarSystemInfo() external view returns (
        address nftPlanet,
        address ftSatellite,
        uint256 quantumLinks,
        uint256 stellarValue,
        uint256 harmonyLevel,
        uint256 systemAge,
        string memory storageAPIKey,
        address metricsAddr
    ) {
        return (
            mareaMangaNFT,
            lunaComicsFT,
            totalQuantumLinks,
            totalStellarValue,
            _calculateHarmony(),
            block.timestamp - universeCreationTime,
            nftStorageAPIKey,
            metricsContract
        );
    }

    // 🛡️ UPGRADE AUTHORIZATION
    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override
        onlyRole(STELLAR_GOVERNOR)
    {
        require(newImplementation != address(0), "Invalid implementation address");
        // Additional upgrade security checks can be added here
    }

    // 🛠️ UTILITY FUNCTIONS
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}