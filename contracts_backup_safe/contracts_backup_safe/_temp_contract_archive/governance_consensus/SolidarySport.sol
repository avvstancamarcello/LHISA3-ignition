// © Copyright Marcello Stanca, lawyer in Florence, Italy

// SPDX-License-Identifier: MIT
// © Copyright Marcello Stanca – Lawyer, Italy (Florence)
pragma solidity ^0.8.26;

//
// © Copyright Marcello Stanca, Firenze, Italy

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract SolidarySport is ERC721URIStorage, Ownable {
    uint256 public nextTokenId;
    uint256 public nextSportNFTId;
    string public baseURI;

    struct FanToken {
        string teamName;
        address tokenAddress;
        bool listed;
    }

    mapping(address => FanToken) public fanTokens;
    address[] public listedTokens;

    struct MatchSession {
        string matchName;
        uint256 startTime;
        uint256 endTime;
        bool active;
    }

    MatchSession public currentMatch;

    event FanTokenPurchased(address indexed buyer, address tokenAddress, uint256 amount);
    event FanTokenSold(address indexed seller, address tokenAddress, uint256 amount);
    event MatchStarted(string matchName, uint256 startTime, uint256 endTime);
    event MatchEnded(string matchName);
    event SportNFTMinted(address indexed to, uint256 tokenId, string cid);

    constructor(
        address initialOwner,
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) Ownable(initialOwner) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        nextSportNFTId = 1;
    }

    // 🏅 Mint badge simbolico
    function mintBadge(address to, string memory uri) external onlyOwner {
        uint256 tokenId = nextTokenId;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        nextTokenId++;
    }

    // 🎟️ Mint NFT sportivo (immagine, audio, testo)
    function mintSportNFT(address to, string memory cid) public onlyOwner {
        _mint(to, nextSportNFTId);
        _setTokenURI(nextSportNFTId, string(abi.encodePacked(baseURI, cid)));
        emit SportNFTMinted(to, nextSportNFTId, cid);
        nextSportNFTId++;
    }

    // ⚽ Elenco token calcistici quotati
    function listFanToken(address tokenAddress, string memory teamName) public onlyOwner {
        fanTokens[tokenAddress] = FanToken(teamName, tokenAddress, true);
        listedTokens.push(tokenAddress);
    }

    function getListedTokens() public view returns (address[] memory) {
        return listedTokens;
    }

    // 🛒 Acquisto token calcistici (placeholder per Binance API)
    function buyFanToken(address tokenAddress, uint256 amount) public {
        require(fanTokens[tokenAddress].listed, "Token non registrato");
        emit FanTokenPurchased(msg.sender, tokenAddress, amount);
    }

    // 🔻 Vendita token calcistici (dissenso)
    function sellFanToken(address tokenAddress, uint256 amount) public {
        require(fanTokens[tokenAddress].listed, "Token non registrato");
        emit FanTokenSold(msg.sender, tokenAddress, amount);
    }

    // 📺 Sessione partita live
    function startMatch(string memory matchName, uint256 durationMinutes) public onlyOwner {
        currentMatch = MatchSession(matchName, block.timestamp, block.timestamp + (durationMinutes * 1 minutes), true);
        emit MatchStarted(matchName, currentMatch.startTime, currentMatch.endTime);
    }

    function endMatch() public onlyOwner {
        require(currentMatch.active, "Nessuna partita attiva");
        emit MatchEnded(currentMatch.matchName);
        currentMatch.active = false;
    }

    // 🔗 Imposta base URI per NFT
    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }
}
