// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca Lawyer - ITALY Florence

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SolidaryUnivManager is AccessControl {
    bytes32 public constant UNIV_MINT_ROLE = keccak256("UNIV_MINT_ROLE");

    event UnivMintLogged(address indexed to, string researchNote);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(UNIV_MINT_ROLE, admin);
    }

    function mintUnivToken(address to, string memory researchNote) external onlyRole(UNIV_MINT_ROLE) {
        emit UnivMintLogged(to, researchNote);
    }
}
