// © Copyright Marcello Stanca, lawyer in Florence, Italy

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

//
// © Copyright Marcello Stanca, Firenze, Italy

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ImpactFund is Ownable {
    IERC20 public token;
    uint256 public totalDonated;

    event DonationReceived(address indexed donor, uint256 amount);
    event FundsWithdrawn(address indexed to, uint256 amount);

    constructor(address initialOwner, address tokenAddress) Ownable(initialOwner) {
        token = IERC20(tokenAddress);
    }

    function donate(uint256 amount) external {
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        totalDonated += amount;
        emit DonationReceived(msg.sender, amount);
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        require(token.transfer(to, amount), "Withdraw failed");
        emit FundsWithdrawn(to, amount);
    }

    function getBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}
