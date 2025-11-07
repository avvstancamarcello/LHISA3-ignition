// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca Lawyer - ITALY Florence

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SolidaryFaithMint is AccessControl {
    bytes32 public constant FAITH_MINT_ROLE = keccak256("FAITH_MINT_ROLE");

    event FaithMintLogged(address indexed to, string spiritualWitness);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(FAITH_MINT_ROLE, admin);
    }

    function mintFaithToken(address to, string memory spiritualWitness) external onlyRole(FAITH_MINT_ROLE) {
        emit FaithMintLogged(to, spiritualWitness);
    }
}
