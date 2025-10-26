// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca – Lawyer, Italy (Florence)
// © Copyright Marcello Stanca, Firenze, Italy


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

interface ISolidaryToken {
    function balanceOf(address account) external view returns (uint256);
}

contract ImpactLogger is Initializable, AccessControlUpgradeable {
    bytes32 public constant LOGGER_ROLE = keccak256("LOGGER_ROLE");

    ISolidaryToken public solidaryToken;

    event ImpactLogged(
        address indexed actor,
        string category,
        string description,
        uint256 amount
    );

    function initialize(address tokenAddress, address admin) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(LOGGER_ROLE, admin);
        solidaryToken = ISolidaryToken(tokenAddress);
    }

    function logImpact(
        string memory category,
        string memory description,
        uint256 amount
    ) external onlyRole(LOGGER_ROLE) {
        require(
            solidaryToken.balanceOf(msg.sender) >= amount,
            "Insufficient balance"
        );

        emit ImpactLogged(msg.sender, category, description, amount);
    }
}
