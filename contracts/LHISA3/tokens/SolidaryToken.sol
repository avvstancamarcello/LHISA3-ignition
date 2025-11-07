// © Copyright Marcello Stanca, lawyer in Florence, Italy

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

//
// © Copyright Marcello Stanca, Firenze, Italy

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SolidaryToken is ERC20, Ownable {
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * (10 ** 18); // 1 milione di token

    mapping(address => bool) public sponsorWallets;
    event SponsorRegistered(address indexed sponsor);
    event Sponsored(address indexed sponsor, address indexed beneficiary, uint256 amount);

    constructor(address initialOwner) ERC20("Solidary", "SLDY") Ownable() {
        _mint(initialOwner, INITIAL_SUPPLY);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    function registerSponsor() external {
        sponsorWallets[msg.sender] = true;
        emit SponsorRegistered(msg.sender);
    }

    function sponsor(address beneficiary, uint256 amount) external {
        require(sponsorWallets[msg.sender], "Not a registered sponsor");
        _transfer(msg.sender, beneficiary, amount);
        emit Sponsored(msg.sender, beneficiary, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
