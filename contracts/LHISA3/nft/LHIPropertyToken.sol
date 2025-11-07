// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// © Copyright Marcello Stanca - Italy - Florence. Author and owner of the Solidary.it ecosystem and this smart contract. The ecosystem and its logical components (.sol files and scripts) are protected by copyright.


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LHIPropertyToken is ERC721URIStorage, Ownable {
    uint256 public nextTokenId;
    string public buildingName = "Edificio LHI";
    string public location = "Lecce, Salento, Italia";

constructor(address initialOwner) ERC721("LHIPropertyToken", "LHIP") Ownable() {}

    function mintPropertyNFT(address to, string memory tokenURI) public onlyOwner {
        _safeMint(to, nextTokenId);
        _setTokenURI(nextTokenId, tokenURI);
        nextTokenId++;
    }

    function updateTokenURI(uint256 tokenId, string memory newURI) public onlyOwner {
        _setTokenURI(tokenId, newURI);
    }
}
