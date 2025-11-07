// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// © Copyright Marcello Stanca - Italy - Florence. Author and owner of the Solidary.it ecosystem and this smart contract. The ecosystem and its logical components (.sol files and scripts) are protected by copyright.


contract MockReputation {
    mapping(address => uint256) public scores;

    function setScore(address user, uint256 score) external {
        scores[user] = score;
    }

    function getReputationScore(address user) external view returns (uint256) {
        return scores[user];
    }
}
