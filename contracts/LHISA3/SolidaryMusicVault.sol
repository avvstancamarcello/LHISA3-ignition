// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract SolidaryMusicVault is ERC721URIStorage {
    uint256 public nextTrackId;

    constructor() ERC721("SolidaryMusicVault", "SMV") {}

    function mintTrack(address to, string memory ipfsURI) public {
        _safeMint(to, nextTrackId);
        _setTokenURI(nextTrackId, ipfsURI);
        nextTrackId++;
    }
}
