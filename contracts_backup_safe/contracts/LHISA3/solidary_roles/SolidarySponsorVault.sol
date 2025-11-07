// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca Lawyer - ITALY Florence

import "@openzeppelin/contracts/access/AccessControl.sol";

contract SolidarySponsorVault is AccessControl {
    bytes32 public constant SPONSOR_ROLE = keccak256("SPONSOR_ROLE");

    event SponsorMintLogged(address indexed to, string sponsorshipNote);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(SPONSOR_ROLE, admin);
    }

    function mintSponsorToken(address to, string memory sponsorshipNote) external onlyRole(SPONSOR_ROLE) {
        emit SponsorMintLogged(to, sponsorshipNote);
    }
}
