// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca – Lawyer, Italy (Florence)
// © Copyright Marcello Stanca, Firenze, Italy


contract ReputationManager {
    struct Reputation {
        uint256 score;
        uint256 validations;
        uint256 reports;
        bool flagged;
    }

    mapping(address => Reputation) public reputations;

    event ReputationUpdated(address indexed user, uint256 newScore);
    event UserFlagged(address indexed user);

    function increaseReputation(address user) external {
        Reputation storage rep = reputations[user];
        rep.score += 10;
        rep.validations += 1;
        emit ReputationUpdated(user, rep.score);
    }

    function reportUser(address user) external {
        Reputation storage rep = reputations[user];
        rep.reports += 1;
        if (rep.reports > rep.validations / 2) {
            rep.flagged = true;
            emit UserFlagged(user);
        }
    }

    function getReputation(address user) external view returns (Reputation memory) {
        return reputations[user];
    }
}
