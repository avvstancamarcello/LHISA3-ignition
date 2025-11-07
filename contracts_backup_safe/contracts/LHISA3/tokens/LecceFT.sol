// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// © Copyright Marcello Stanca - Italy - Florence. Author and owner of the Solidary.it ecosystem and this smart contract. The ecosystem and its logical components (.sol files and scripts) are protected by copyright.


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LecceFT is ERC20, Ownable {
    uint256 public mintFeeBasisPoints = 250; // 2.5%
    address public solidaryWallet;

    constructor(address initialOwner) ERC20("LecceFT", "LFT") Ownable(initialOwner) {}

    function mint(address to, uint256 amount) public payable {
        uint256 fee = (amount * mintFeeBasisPoints) / 10000;
        require(msg.value >= fee, "Insufficient fee");

        payable(solidaryWallet).transfer(fee);
        _mint(to, amount);
    }

    function updateSolidaryWallet(address newWallet) public onlyOwner {
        solidaryWallet = newWallet;
    }

    function updateMintFee(uint256 newFeeBasisPoints) public onlyOwner {
        require(newFeeBasisPoints <= 1000, "Fee too high");
        mintFeeBasisPoints = newFeeBasisPoints;
    }
}
