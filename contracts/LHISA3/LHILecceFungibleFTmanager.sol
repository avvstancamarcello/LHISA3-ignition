// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca, Firenze, Italy

import "@openzeppelin/contracts/access/Ownable.sol";
import "./tokens/LecceFT.sol";

// Interfaccia orbitale per LHILecceNFT
interface ILHILecceNFT {
    function safeMint(address to, string memory tokenURI, string memory description) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract LHILecceFungibleFTmanager is Ownable {
    ILHILecceNFT public lhiLecceNFT;
    LecceFT public lecceFT;

    constructor(address initialOwner, address nftAddress, address ftAddress) Ownable() {
        lhiLecceNFT = ILHILecceNFT(nftAddress);
        lecceFT = LecceFT(ftAddress);
    }

    function rewardFan(address fan, string memory tokenURI, uint256 ftAmount) external onlyOwner {
        string memory description = "NFT del tifoso solidale";

        // 🎖️ Mint NFT al tifoso
        lhiLecceNFT.safeMint(fan, tokenURI, description);

        // 🪙 Trasferisci token fungibili
        lecceFT.transfer(fan, ftAmount);
    }

    function updateNFTContract(address newNFT) external onlyOwner {
        lhiLecceNFT = ILHILecceNFT(newNFT);
    }

    function updateFTContract(address newFT) external onlyOwner {
        lecceFT = LecceFT(newFT);
    }
}
