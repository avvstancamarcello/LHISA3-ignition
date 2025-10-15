// © Copyright Marcello Stanca, lawyer in Florence, Italy

// SPDX-License-Identifier: MIT
// © Copyright Marcello Stanca – Lawyer, Italy (Florence)
pragma solidity ^0.8.26;

//
// © Copyright Marcello Stanca, Firenze, Italy

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SolidaryBadge is ERC721, Ownable {
    uint256 public nextBadgeId;
    mapping(uint256 => string) private _badgeDescriptions;

    event BadgeMinted(address indexed to, uint256 indexed badgeId, string description);
    event BadgeUpdated(uint256 indexed badgeId, string newDescription);

    constructor(address initialOwner) ERC721("SolidaryBadge", "SLDB") Ownable(initialOwner) {
        nextBadgeId = 1;
    }

    function mintBadge(address to, string memory description) external onlyOwner {
        uint256 badgeId = nextBadgeId;
        _safeMint(to, badgeId);
        _badgeDescriptions[badgeId] = description;
        emit BadgeMinted(to, badgeId, description);
        nextBadgeId++;
    }

    function updateBadgeDescription(uint256 badgeId, string memory newDescription) external onlyOwner {
        require(ownerOf(badgeId) != address(0), "Badge does not exist");
        _badgeDescriptions[badgeId] = newDescription;
        emit BadgeUpdated(badgeId, newDescription);
    }

    function getBadgeDescription(uint256 badgeId) external view returns (string memory) {
        require(ownerOf(badgeId) != address(0), "Badge does not exist");
        return _badgeDescriptions[badgeId];
    }

    function totalBadgesMinted() external view returns (uint256) {
        return nextBadgeId - 1;
    }
}
