// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PeaceAid is ERC20, Ownable {
    mapping(address => bool) public validatedByUN;

    constructor(address initialOwner) ERC20("PeaceAid", "AID") Ownable() {}

    function validateRecipient(address recipient) external onlyOwner {
        validatedByUN[recipient] = true;
    }

    function mintAid(address to, uint256 amount) external onlyOwner {
        require(validatedByUN[to], "Recipient not validated by UN authority");
        _mint(to, amount);
    }

    function donate() external payable {
        // ETH donations can be tracked or converted to AID tokens manually
    }
}
