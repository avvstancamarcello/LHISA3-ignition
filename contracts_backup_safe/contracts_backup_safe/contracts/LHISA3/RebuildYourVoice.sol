// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RebuildYourVoice is ERC1155, Ownable {
    uint256 public constant VOCE_LIBERATA = 1;

    constructor(address initialOwner) ERC1155("https://solidary.it/api/rebuildyourvoice/{id}.json") Ownable(initialOwner) {}

    function mintFT(address to, uint256 amount) public onlyOwner {
        _mint(to, VOCE_LIBERATA, amount, "");
    }

    function mintNFT(address to, string memory metadataURI) public onlyOwner {
        uint256 newId = uint256(keccak256(abi.encodePacked(to, metadataURI, block.timestamp)));
        _mint(to, newId, 1, "");
        _setURI(metadataURI);
    }

    function linkToVotingApp(address ivoteAddress) public onlyOwner {
        emit VotingAppLinked(ivoteAddress);
    }

    function launchVote(string memory message) public onlyOwner {
        emit VoteLaunched(message);
    }

    event VotingAppLinked(address ivoteAddress);
    event VoteLaunched(string message);
}
