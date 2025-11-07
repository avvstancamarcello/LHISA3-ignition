// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SolidaryComics is ERC20, Ownable {
    address public charityWallet;
    uint256 public feePercent = 2;

    event ComicDonation(address indexed donor, uint256 feeAmount, string comicTitle);

    constructor(address _charityWallet, address initialOwner) ERC20("SolidaryComics", "COMIX") Ownable(initialOwner) {
        charityWallet = _charityWallet;
    }

    function transferWithComicCause(address to, uint256 amount, string memory comicTitle) external {
        uint256 fee = (amount * feePercent) / 100;
        uint256 netAmount = amount - fee;

        _transfer(msg.sender, charityWallet, fee);
        _transfer(msg.sender, to, netAmount);

        emit ComicDonation(msg.sender, fee, comicTitle);
    }

    function setFeePercent(uint256 newFee) external onlyOwner {
        require(newFee <= 10, "Fee too high");
        feePercent = newFee;
    }

    function updateCharityWallet(address newWallet) external onlyOwner {
        charityWallet = newWallet;
    }
}
