// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca Lawyer - ITALY Florence

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SolidaryGovToken is AccessControl {
    bytes32 public constant GOV_MINT_ROLE = keccak256("GOV_MINT_ROLE");

    event GovMintLogged(address indexed to, string civicAction);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(GOV_MINT_ROLE, admin);
    }

    function mintGovToken(address to, string memory civicAction) external onlyRole(GOV_MINT_ROLE) {
        emit GovMintLogged(to, civicAction);
    }
}
