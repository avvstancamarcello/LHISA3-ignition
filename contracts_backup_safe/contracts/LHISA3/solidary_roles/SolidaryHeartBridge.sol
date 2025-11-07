// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca Lawyer - ITALY Florence

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SolidaryHeartBridge is AccessControl {
    bytes32 public constant HEART_MINT_ROLE = keccak256("HEART_MINT_ROLE");

    event HeartTransitLogged(address indexed to, string portWitness);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(HEART_MINT_ROLE, admin);
    }

    function mintHeartToken(address to, string memory portWitness) external onlyRole(HEART_MINT_ROLE) {
        emit HeartTransitLogged(to, portWitness);
    }
}
