// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca, Firenze, Italy


import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ReputationManager is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    struct Reputation {
        uint256 score;
        uint256 validations;
        uint256 reports;
        bool flagged;
    }

    mapping(address => Reputation) public reputations;
    bytes32 public constant UPGRADER_ROLE = keccak256("REPUTATION_UPGRADER_ROLE");


    event ReputationUpdated(address indexed user, uint256 newScore);
    event UserFlagged(address indexed user);

    function initialize(address admin) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
    }

    function increaseReputation(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Reputation storage rep = reputations[user];
        rep.score += 10;
        rep.validations += 1;
        emit ReputationUpdated(user, rep.score);
    }

    function reportUser(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
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

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}
