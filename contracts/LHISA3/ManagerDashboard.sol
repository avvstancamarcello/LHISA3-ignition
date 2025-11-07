// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca, Firenze, Italy

import "@openzeppelin/contracts/access/Ownable.sol";

// Interfaccia orbitale per LHILecceNFT
interface ILHILecceNFT {
    function totalMinted() external view returns (uint256);
    function symbol() external view returns (string memory);
}

// Interfaccia orbitale per LecceFT
interface ILecceFT {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function symbol() external view returns (string memory);
}

contract ManagerDashboard is Ownable {
    ILHILecceNFT public lhiLecceNFT;
    ILecceFT public lecceFT;

    constructor(address initialOwner, address nftAddress, address ftAddress) Ownable() {
        lhiLecceNFT = ILHILecceNFT(nftAddress);
        lecceFT = ILecceFT(ftAddress);
    }

    // 📊 Stato NFT
    function totalNFTMinted() external view returns (uint256) {
        return lhiLecceNFT.totalMinted();
    }

    // 💰 Stato FT
    function ftBalanceOf(address account) external view returns (uint256) {
        return lecceFT.balanceOf(account);
    }

    function ftTotalSupply() external view returns (uint256) {
        return lecceFT.totalSupply();
    }

    // 🔧 Aggiornamento contratti
    function updateNFTContract(address newNFT) external onlyOwner {
        lhiLecceNFT = ILHILecceNFT(newNFT);
    }

    function updateFTContract(address newFT) external onlyOwner {
        lecceFT = ILecceFT(newFT);
    }

    // 🧾 Informazioni generali
    function getNFTSymbol() external view returns (string memory) {
        return lhiLecceNFT.symbol();
    }

    function getFTSymbol() external view returns (string memory) {
        return lecceFT.symbol();
    }
}
