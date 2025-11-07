// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca Lawyer - ITALY Florence

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SolidaryJusticeManager is AccessControl {
    bytes32 public constant JUS_MINT_ROLE = keccak256("JUS_MINT_ROLE");

    event JusticeMintLogged(address indexed to, string rehabilitationNote);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(JUS_MINT_ROLE, admin);
    }

    function mintJusToken(address to, string memory rehabilitationNote) external onlyRole(JUS_MINT_ROLE) {
        emit JusticeMintLogged(to, rehabilitationNote);
    }
}
