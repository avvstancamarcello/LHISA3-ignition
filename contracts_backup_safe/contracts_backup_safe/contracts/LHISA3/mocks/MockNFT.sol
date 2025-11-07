// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// © Copyright Marcello Stanca - Italy - Florence. Author and owner of the Solidary.it ecosystem and this smart contract. The ecosystem and its logical components (.sol files and scripts) are protected by copyright.


contract MockNFT {
    mapping(address => bool) public wasMinted;

    function safeMint(address to, string memory, string memory) external {
        wasMinted[to] = true;
    }

    function totalSupply() external pure returns (uint256) {
        return 0;
    }
}
 
