// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca – Lawyer, Italy (Florence)
// © Copyright Marcello Stanca, Firenze, Italy


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

interface IImpactLogger {
    function logImpact(
        string memory category,
        string memory description,
        uint256 amount
    ) external;
}

contract ModuleRouter is Initializable, AccessControlUpgradeable {
    bytes32 public constant ROUTER_ADMIN = keccak256("ROUTER_ADMIN");
    bytes32 public constant IMPACT_CALLER = keccak256("IMPACT_CALLER");

    address public impactLoggerAddress;

    event ModuleLinked(string moduleName, address moduleAddress);
    event ImpactRouted(address indexed actor, string category, string description, uint256 amount);

    function initialize(address admin) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ROUTER_ADMIN, admin);
    }

    // 🔗 Collegamento modulo ImpactLogger
    function setImpactLogger(address _impactLogger) external onlyRole(ROUTER_ADMIN) {
        impactLoggerAddress = _impactLogger;
        emit ModuleLinked("ImpactLogger", _impactLogger);
    }

    // 📡 Routing della funzione logImpact
    function routeImpact(
        string memory category,
        string memory description,
        uint256 amount
    ) external onlyRole(IMPACT_CALLER) {
        require(impactLoggerAddress != address(0), "ImpactLogger not set");

        IImpactLogger(impactLoggerAddress).logImpact(category, description, amount);

        emit ImpactRouted(msg.sender, category, description, amount);
    }
}
