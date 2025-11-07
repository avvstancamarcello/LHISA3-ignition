// © Copyright Marcello Stanca, lawyer in Florence, Italy

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


// © Copyright Marcello Stanca, Firenze, Italy

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SolidaryCulturalMint is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    string public culturalTheme;
    address public culturalBeneficiary;

    mapping(uint256 => string) private _tokenMessages;
    mapping(uint256 => address) private _tokenSponsors;

    event CulturalMinted(
        address indexed to,
        uint256 indexed tokenId,
        string uri,
        string message,
        address sponsor
    );

    event ThemeUpdated(string oldTheme, string newTheme);
    event BeneficiaryUpdated(address oldBeneficiary, address newBeneficiary);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner, string memory theme, address beneficiary) public initializer {
        __ERC721_init("SolidaryCulturalMint", "SCMINT");
        __ERC721URIStorage_init();
        __Ownable_init();
        transferOwnership(initialOwner);
        culturalTheme = theme;
        culturalBeneficiary = beneficiary;
    }

    function mintCulturalNFT(
        address to,
        string memory uri,
        string memory message,
        address sponsor
    ) external onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _tokenMessages[tokenId] = message;
        _tokenSponsors[tokenId] = sponsor;

        emit CulturalMinted(to, tokenId, uri, message, sponsor);
    }

    function updateTheme(string memory newTheme) external onlyOwner {
        emit ThemeUpdated(culturalTheme, newTheme);
        culturalTheme = newTheme;
    }

    function updateBeneficiary(address newBeneficiary) external onlyOwner {
        require(newBeneficiary != address(0), "Invalid address");
        emit BeneficiaryUpdated(culturalBeneficiary, newBeneficiary);
        culturalBeneficiary = newBeneficiary;
    }

    function getTheme() external view returns (string memory) {
        return culturalTheme;
    }

    function getBeneficiary() external view returns (address) {
        return culturalBeneficiary;
    }

    function totalMinted() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function getMessage(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenMessages[tokenId];
    }

    function getSponsor(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenSponsors[tokenId];
    }

    // Override richiesti per compatibilità multipla ERC721
    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns (bool)
    {
    return super.supportsInterface(interfaceId);
    }
}
