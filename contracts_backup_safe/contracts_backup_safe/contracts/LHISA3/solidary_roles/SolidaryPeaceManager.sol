// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca Lawyer - ITALY Florence

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SolidaryPeaceManager is AccessControl {
    bytes32 public constant PEACE_MINT_ROLE = keccak256("PEACE_MINT_ROLE");

    event PeaceMintLogged(address indexed to, string protectionNote);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PEACE_MINT_ROLE, admin);
    }

    function mintPeaceToken(address to, string memory protectionNote) external onlyRole(PEACE_MINT_ROLE) {
        emit PeaceMintLogged(to, protectionNote);
    }
}
