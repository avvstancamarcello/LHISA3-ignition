// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca - Italy - Florence. Author and owner of the Solidary.it ecosystem and this smart contract. The ecosystem and its logical components (.sol files and scripts) are protected by copyright.


import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PassaportoSolidity is ERC721URIStorage, Ownable {
    uint256 public nextTokenId = 1;
    mapping(address => uint256) public passportOf;
    mapping(uint256 => string) public mottoOfDay;
    mapping(uint256 => string[]) public visitedPlanets;

    constructor(address initialOwner)
        ERC721("PassaportoSolidity", "SOLPASS")
    Ownable()
    {}

    function mintPassport(string memory uri, string memory motto) public {
        require(bytes(uri).length > 0, "URI non valido");
        require(bytes(motto).length <= 100, "Motto troppo lungo");
        require(passportOf[msg.sender] == 0, unicode"Hai già un passaporto");

        uint256 tokenId = nextTokenId;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        passportOf[msg.sender] = tokenId;
        mottoOfDay[tokenId] = motto;
        nextTokenId++;
    }
    
    function totalMinted() external view returns (uint256) {
    return nextTokenId - 1;
    }


    function updateMotto(string memory newMotto) public {
        uint256 tokenId = passportOf[msg.sender];
        require(tokenId != 0, "Nessun passaporto trovato");
        mottoOfDay[tokenId] = newMotto;
    }

    function logPlanetVisit(string memory planetName) public {
        uint256 tokenId = passportOf[msg.sender];
        require(tokenId != 0, "Nessun passaporto trovato");
        visitedPlanets[tokenId].push(planetName);
    }

    function getVisitedPlanets(address user) public view returns (string[] memory) {
        uint256 tokenId = passportOf[user];
        return visitedPlanets[tokenId];
    }

    function getMotto(address user) public view returns (string memory) {
        uint256 tokenId = passportOf[user];
        return mottoOfDay[tokenId];
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
