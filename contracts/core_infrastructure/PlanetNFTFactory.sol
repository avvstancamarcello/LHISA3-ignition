// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

// Copyright © 2025 Avv. Marcello Stanca - Firenze, Italia. All Rights Reserved.
//
// Hoc contractum, pars 'Solidary System', ab Auctore Marcello Stanca Caritati Internationali (MCMLXXVI) conceditur.
// (This smart contract, part of the 'Solidary System', is granted for free use to Caritas Internationalis (1976) by the author, Marcello Stanca.)

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PlanetNFTFactory
 * @author Avv. Marcello Stanca
 * @notice Fabrica digitalis quae "Planetas" (NFTs) pro unoquoque modulo Oecosystematis 'Solidary System' creat.
 * (English: A digital factory that creates "Planets" (NFTs) for each module of the 'Solidary System'.)
 * @dev Hoc contractum nunc utitur mechanismo interno ad numerationem, postquam libraria "Counters" ab OpenZeppelin obsoleta est. Est velocius et efficacius.
 * (English: This contract now uses an internal counting mechanism, after the "Counters" library was deprecated by OpenZeppelin. It is faster and more efficient.)
 */
contract PlanetNFTFactory is ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;

    mapping(string => uint256) public moduleToNFT;

    event PlanetNFTMinted(address indexed recipient, uint256 tokenId, string moduleName);

    constructor(address initialOwner) ERC721("SolidaryPlanetNFT", "SPNFT") Ownable(initialOwner) {
        _nextTokenId = 1;
    }

    function mintPlanetNFT(address recipient, string memory moduleName, string memory tokenURI) public onlyOwner returns (uint256) {
        require(moduleToNFT[moduleName] == 0, "Modulo gia' ha un NFT assegnato");

        uint256 newItemId = _nextTokenId;
        _nextTokenId++;

        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        moduleToNFT[moduleName] = newItemId;

        emit PlanetNFTMinted(recipient, newItemId, moduleName);
        return newItemId;
    }

    function getModuleNFTURI(string memory moduleName) public view returns (string memory) {
        uint256 tokenId = moduleToNFT[moduleName];
        require(tokenId != 0, "Modulo non ha NFT");
        return tokenURI(tokenId);
    }
}
