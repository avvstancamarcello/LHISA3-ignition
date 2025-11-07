// © Copyright Marcello Stanca, lawyer in Florence, Italy

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

//
// © Copyright Marcello Stanca, Firenze, Italy

import "@openzeppelin/contracts/access/Ownable.sol";

contract setFungibleManager is Ownable {
    address public manager;

    event ManagerSet(address indexed oldManager, address indexed newManager);

    constructor(address initialOwner, address initialManager) Ownable() {
        manager = initialManager;
    }

    function setManager(address newManager) external onlyOwner {
        require(newManager != address(0), "Invalid address");
        emit ManagerSet(manager, newManager);
        manager = newManager;
    }

    function getManager() external view returns (address) {
        return manager;
    }
}
