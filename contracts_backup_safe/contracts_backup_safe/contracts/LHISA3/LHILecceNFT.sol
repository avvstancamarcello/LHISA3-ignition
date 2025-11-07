// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca Lawyer - ITALY Florence

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract LHILecceNFT is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, OwnableUpgradeable {
    uint256 public nextTokenId;
    uint256 public totalSupply;
    mapping(uint256 => string) private _tokenDescriptions;
    
    string private _baseTokenURI;
    string private _contractURI;

    event NFTMinted(address indexed to, uint256 indexed tokenId, string uri, string description);
    event BaseURIUpdated(string newBaseURI);
    event ContractURIUpdated(string newContractURI);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __ERC721_init("LHILecceNFT", "LECCENFT");
        __ERC721URIStorage_init();
        __Ownable_init();
        transferOwnership(initialOwner);
        nextTokenId = 1;
        totalSupply = 0;
    }

    function mintNFT(address to, string memory uri, string memory description) internal {
        uint256 tokenId = nextTokenId;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _tokenDescriptions[tokenId] = description;
        emit NFTMinted(to, tokenId, uri, description);
        nextTokenId++;
        totalSupply++;
    }

    function safeMint(address to, string memory uri, string memory description) external onlyOwner {
        mintNFT(to, uri, description);
    }

    function getDescription(uint256 tokenId) external view returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        return _tokenDescriptions[tokenId];
    }

    function totalMinted() external view returns (uint256) {
        return nextTokenId - 1;
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // Base URI functions for IPFS metadata
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    // Contract URI for collection metadata
    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractURI = newContractURI;
        emit ContractURIUpdated(newContractURI);
    }
    
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
