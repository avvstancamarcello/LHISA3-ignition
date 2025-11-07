// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// Version semplificata che non richiede contratti esterni
contract OceanMangaOrchestratorSimple is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    
    address public creator;
    address public charityFund;

    // Percentuali (base 1000 per precisione)
    uint256 public constant CREATOR_SHARE = 25;   // 2.5%
    uint256 public constant CHARITY_SHARE = 25;   // 2.5%
    
    // ID NFT incrementale
    uint256 public nextTokenId = 1;

    // Storage per i metadati NFT "virtuali"
    mapping(uint256 => string) public tokenURIs;
    mapping(uint256 => address) public tokenOwners;
    mapping(address => uint256[]) public ownerTokens;

    event PhotoMinted(
        address indexed user, 
        string tokenURI, 
        uint256 ethPaid, 
        uint256 nftId
    );

    constructor(
        address _creator,
        address _charity
    ) {
        _transferOwnership(msg.sender);
        creator = _creator;
        charityFund = _charity;
    }

    function mintPhotoCombo(string memory tokenURI) external payable nonReentrant {
        require(msg.value > 0, "Payment required");
        require(bytes(tokenURI).length > 0, "Token URI required");

        uint256 total = msg.value;
        uint256 currentTokenId = nextTokenId++;
        
        // Calcola le quote
        uint256 creatorAmount = (total * CREATOR_SHARE) / 1000;
        uint256 charityAmount = (total * CHARITY_SHARE) / 1000;

        // Salva il "NFT virtuale"
        tokenURIs[currentTokenId] = tokenURI;
        tokenOwners[currentTokenId] = msg.sender;
        ownerTokens[msg.sender].push(currentTokenId);

        // Distribuisci pagamenti
        if (creatorAmount > 0) {
            payable(creator).transfer(creatorAmount);
        }
        if (charityAmount > 0) {
            payable(charityFund).transfer(charityAmount);
        }

        emit PhotoMinted(msg.sender, tokenURI, total, currentTokenId);
    }
    
    // Funzioni di lettura per compatibilità
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return tokenURIs[tokenId];
    }
    
    function ownerOf(uint256 tokenId) external view returns (address) {
        return tokenOwners[tokenId];
    }
    
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        return ownerTokens[owner];
    }
    
    function totalSupply() external view returns (uint256) {
        return nextTokenId - 1;
    }

    function setAddresses(
        address _creator,
        address _charity
    ) external onlyOwner {
        creator = _creator;
        charityFund = _charity;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}