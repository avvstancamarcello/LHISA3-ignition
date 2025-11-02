// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;


// Copyright Marcello Stanca, Lawyer, Italy, Florence.
// This smart contract is a modular element of the SolidarySystem ecosystem/project, deployed on Polygon and Base networks.

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CosmixSolidaryToken is Initializable, ERC20Upgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("COSMIX_MINTER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("COSMIX_MANAGER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("COSMIX_UPGRADER_ROLE");


    function initialize(
        address admin,
        uint256 initialSupply,
        address treasury
    ) public initializer {
        __ERC20_init("Cosmix Solidary Token", "COSMIX");
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);

        _mint(treasury, initialSupply);
    }

    // Allows MANAGER to grant MINTER_ROLE to orchestrator or other contracts
    function grantMinterRole(address orchestrator) external onlyRole(MANAGER_ROLE) {
        _grantRole(MINTER_ROLE, orchestrator);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyRole(MANAGER_ROLE) {
        _burn(from, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}
