// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// © Copyright Marcello Stanca - Italy - Florence. Author and owner of the Solidary.it ecosystem and this smart contract. The ecosystem and its logical components (.sol files and scripts) are protected by copyright.


contract MockDonation {
    mapping(address => bool) public donated;

    function setDonated(address user, bool status) external {
        donated[user] = status;
    }

    function hasDonated(address user) external view returns (bool) {
        return donated[user];
    }
}
