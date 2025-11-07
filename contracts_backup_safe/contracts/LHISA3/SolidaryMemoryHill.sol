// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca, Firenze, Italy

contract SolidaryMemoryHill {
    address public owner;
    string[] public testimonies;

    constructor(address _owner) {
        owner = _owner;
    }

    function publishTestimony(string memory cid) external {
        testimonies.push(cid);
    }

    function getTestimony(uint256 index) external view returns (string memory) {
        require(index < testimonies.length, "Invalid index");
        return testimonies[index];
    }

    function totalTestimonies() external view returns (uint256) {
        return testimonies.length;
    }
}
