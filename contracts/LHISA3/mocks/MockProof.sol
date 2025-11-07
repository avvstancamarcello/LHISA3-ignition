// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// © Copyright Marcello Stanca - Italy - Florence. Author and owner of the Solidary.it ecosystem and this smart contract. The ecosystem and its logical components (.sol files and scripts) are protected by copyright.


contract MockProof {
    mapping(uint256 => bool) public validated;

    function setValidated(uint256 proofId, bool status) external {
        validated[proofId] = status;
    }

    function isResearchValidated(uint256 proofId) external view returns (bool) {
        return validated[proofId];
    }
}
