// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca Lawyer - ITALY Florence

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SolidarySocialMint is AccessControl {
    bytes32 public constant SOCIAL_MINT_ROLE = keccak256("SOCIAL_MINT_ROLE");

    event SocialMintLogged(address indexed to, string careNote);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(SOCIAL_MINT_ROLE, admin);
    }

    function mintSocialToken(address to, string memory careNote) external onlyRole(SOCIAL_MINT_ROLE) {
        emit SocialMintLogged(to, careNote);
    }
}
