// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca Lawyer - ITALY Florence

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SolidarySoulBridge is AccessControl {
    bytes32 public constant SOUL_MINT_ROLE = keccak256("SOUL_MINT_ROLE");

    event SoulMintLogged(address indexed to, string soulWitness);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(SOUL_MINT_ROLE, admin);
    }

    function mintSoulToken(address to, string memory soulWitness) external onlyRole(SOUL_MINT_ROLE) {
        emit SoulMintLogged(to, soulWitness);
    }
}
