// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca Lawyer - ITALY Florence

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Fibromialgy is ERC20, Ownable {
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10**18;

    address public wallet_creator;
    address public wallet_drawfound;

    constructor(address initialOwner, address _creator, address _drawfound)
        ERC20("Fibromialgy Token", "FMG")
    Ownable()
    {
        wallet_creator = _creator;
        wallet_drawfound = _drawfound;
        _mint(initialOwner, INITIAL_SUPPLY);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        uint256 fee = (amount * 5) / 100;
        uint256 netAmount = amount - fee;

        super.transfer(wallet_creator, fee / 2);
        super.transfer(wallet_drawfound, fee / 2);
        return super.transfer(to, netAmount);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    function euroValue() external pure returns (uint256) {
        return 1;
    }
}
