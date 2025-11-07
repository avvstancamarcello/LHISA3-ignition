// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

// Copyright © 2025 Avv. Marcello Stanca - Firenze, Italia. All Rights Reserved.
// Hoc contractum, pars SolidarySystem.org, ab Auctore Marcello Stanca Caritas Internationalis (MCMLXXVI) conceditur.

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract LuccaComixNFT is Initializable, ERC721Upgradeable, OwnableUpgradeable {
    uint256 private _tokenIdCounter;
    
    // Charity system
    struct Charity {
        string name;
        string description;
        uint256 votes;
        address wallet;
        bool active;
    }
    
    Charity[] public charities;
    mapping(address => bool) public hasVotedForCharity;
    
    // Events
    event CharityVoteCast(address indexed voter, uint256 charityId, uint256 timestamp);
    event PhotoMinted(address indexed creator, uint256 nftId, string emotion);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("Lucca Comix NFT", "LCNFT");
        __Ownable_init(msg.sender);
        _tokenIdCounter = 0;
    }
    
    function mintPhoto(string memory emotion) external returns (uint256) {
        uint256 newTokenId = _tokenIdCounter;
        _tokenIdCounter++;
        _mint(msg.sender, newTokenId);
        
        emit PhotoMinted(msg.sender, newTokenId, emotion);
        return newTokenId;
    }
    
    function voteForCharity(uint256 charityId) external {
        require(!hasVotedForCharity[msg.sender], "Already voted");
        require(charityId < charities.length, "Invalid charity");
        require(charities[charityId].active, "Charity not active");

        charities[charityId].votes++;
        hasVotedForCharity[msg.sender] = true;

        emit CharityVoteCast(msg.sender, charityId, block.timestamp);
    }
    
    function addCharity(string memory name, string memory description, address wallet) external onlyOwner {
        charities.push(Charity(name, description, 0, wallet, true));
    }
}
