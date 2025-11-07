// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca Lawyer - ITALY Florence

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SolidaryEduManager is AccessControl {
    bytes32 public constant EDU_MINT_ROLE = keccak256("EDU_MINT_ROLE");

    event EduMintLogged(address indexed to, string testimony);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(EDU_MINT_ROLE, admin);
    }

    function mintEduToken(address to, string memory testimony) external onlyRole(EDU_MINT_ROLE) {
        emit EduMintLogged(to, testimony);
    }
}
