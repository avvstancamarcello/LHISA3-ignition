// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca Lawyer - ITALY Florence
// Canto V - Muse della Creatività Culturale - Divina Commedia della Solidarietà Blockchain

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title SolidaryCulturalMint
 * @dev Factory NFT per contenuti culturali e artistici dell'ecosistema Solidary
 * @notice Supporta artisti verificati, royalties automatiche e governance culturale
 */
contract SolidaryCulturalMint is 
    Initializable, 
    ERC721Upgradeable, 
    ERC721URIStorageUpgradeable, 
    ERC721RoyaltyUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable 
{
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔐 ROLES & CONSTANTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    bytes32 public constant CULTURAL_CURATOR = keccak256("CULTURAL_CURATOR");
    bytes32 public constant VERIFIED_ARTIST = keccak256("VERIFIED_ARTIST");
    bytes32 public constant MARKETPLACE_MANAGER = keccak256("MARKETPLACE_MANAGER");
    bytes32 public constant ROYALTY_MANAGER = keccak256("ROYALTY_MANAGER");
    
    uint256 public constant MAX_ROYALTY_PERCENTAGE = 1000; // 10% max royalty
    uint256 public constant CULTURAL_IMPACT_THRESHOLD = 100; // Min impact score for curation
    uint256 public constant MAX_BATCH_MINT = 50; // Max NFT per batch mint
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 CULTURAL NFT STRUCTURES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    struct CulturalNFT {
        uint256 tokenId;
        address creator;
        string title;
        string description;
        CulturalCategory category;
        string culturalRegion;      // "lecce", "italy", "europe", "global"
        uint256 creationTimestamp;
        uint256 culturalImpactScore;
        bool isVerified;
        bool isCurated;
        string[] tags;
        mapping(string => string) metadata; // Extended metadata
    }
    
    enum CulturalCategory {
        VISUAL_ART,          // Pittura, scultura, fotografia
        MUSIC,               // Musica, composizioni, registrazioni
        LITERATURE,          // Poesia, narrativa, saggi
        PERFORMANCE,         // Teatro, danza, performance art
        DIGITAL_ART,         // Arte digitale, NFT art
        TRADITIONAL_CRAFT,   // Artigianato tradizionale
        ARCHITECTURAL,       // Architettura, design urbano
        CULINARY,           // Arte culinaria, ricette tradizionali
        HISTORICAL_DOCUMENT, // Documenti storici, testimonianze
        COMMUNITY_PROJECT    // Progetti collaborativi comunitari
    }
    
    struct Artist {
        address artistAddress;
        string artistName;
        string bio;
        string culturalBackground;
        uint256 verificationTimestamp;
        uint256 totalWorksCreated;
        uint256 totalCulturalImpact;
        uint256 reputationScore;
        bool isVerified;
        bool isActive;
        string[] specialties;
    }
    
    struct CulturalCollection {
        uint256 collectionId;
        address curator;
        string collectionName;
        string description;
        string theme;
        uint256[] tokenIds;
        uint256 creationTime;
        bool isActive;
        mapping(address => bool) collaborators;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 💾 STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    mapping(uint256 => CulturalNFT) public culturalNFTs;
    mapping(address => Artist) public artists;
    mapping(uint256 => CulturalCollection) public collections;
    mapping(CulturalCategory => uint256) public categoryMintCounts;
    mapping(string => uint256[]) public regionTokens; // Region -> token IDs
    
    uint256 public currentTokenId;
    uint256 public currentCollectionId;
    uint256 public totalVerifiedArtists;
    uint256 public totalCulturalImpact;
    
    // Contract references
    address public reputationManager;
    address public impactLogger;
    address public solidaryHub;
    address public culturalTreasury;
    
    // Platform settings
    uint256 public platformRoyaltyPercentage = 250; // 2.5% platform royalty
    uint256 public artistRoyaltyPercentage = 750;   // 7.5% artist royalty
    uint256 public mintFee = 1e16; // 0.01 ETH equivalent mint fee
    bool public mintingActive;
    bool public curationRequired;
    
    // Events
    event ArtistVerified(address indexed artist, string artistName, uint256 timestamp);
    event CulturalNFTMinted(uint256 indexed tokenId, address indexed creator, CulturalCategory category, string title);
    event NFTCurated(uint256 indexed tokenId, address indexed curator, uint256 impactScore);
    event CollectionCreated(uint256 indexed collectionId, address indexed curator, string collectionName);
    event CulturalImpactScored(uint256 indexed tokenId, uint256 impactScore, address indexed scorer);
    event RoyaltyDistributed(uint256 indexed tokenId, address indexed recipient, uint256 amount);
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏗️ INITIALIZATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        address admin,
        address _reputationManager,
        address _impactLogger,
        address _solidaryHub,
        address _culturalTreasury
    ) public initializer {
        __ERC721_init("Solidary Cultural NFT", "SCNFT");
        __ERC721URIStorage_init();
        __ERC721Royalty_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CULTURAL_CURATOR, admin);
        _grantRole(MARKETPLACE_MANAGER, admin);
        _grantRole(ROYALTY_MANAGER, admin);
        
        reputationManager = _reputationManager;
        impactLogger = _impactLogger;
        solidaryHub = _solidaryHub;
        culturalTreasury = _culturalTreasury;
        
        currentTokenId = 1;
        currentCollectionId = 1;
        mintingActive = true;
        curationRequired = false;
        
        // Set default platform royalty
        _setDefaultRoyalty(_culturalTreasury, uint96(platformRoyaltyPercentage));
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎨 ARTIST VERIFICATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Verifica un artista per il mint di NFT culturali
     * @param artistAddress Indirizzo dell'artista
     * @param artistName Nome dell'artista
     * @param bio Biografia dell'artista
     * @param culturalBackground Background culturale
     * @param specialties Specialità artistiche
     */
    function verifyArtist(
        address artistAddress,
        string memory artistName,
        string memory bio,
        string memory culturalBackground,
        string[] memory specialties
    ) external onlyRole(CULTURAL_CURATOR) {
        require(artistAddress != address(0), "Invalid artist address");
        require(bytes(artistName).length > 0, "Artist name required");
        require(!artists[artistAddress].isVerified, "Artist already verified");
        
        Artist storage artist = artists[artistAddress];
        artist.artistAddress = artistAddress;
        artist.artistName = artistName;
        artist.bio = bio;
        artist.culturalBackground = culturalBackground;
        artist.verificationTimestamp = block.timestamp;
        artist.isVerified = true;
        artist.isActive = true;
        artist.specialties = specialties;
        
        // Grant VERIFIED_ARTIST role
        _grantRole(VERIFIED_ARTIST, artistAddress);
        totalVerifiedArtists++;
        
        emit ArtistVerified(artistAddress, artistName, block.timestamp);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🖼️ NFT MINTING
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Minta un NFT culturale
     * @param to Destinatario dell'NFT
     * @param title Titolo dell'opera
     * @param description Descrizione dell'opera
     * @param category Categoria culturale
     * @param culturalRegion Regione culturale
     * @param _tokenURI URI dei metadata
     * @param tags Tag per categorizzazione
     */
    function mintCulturalNFT(
        address to,
        string memory title,
        string memory description,
        CulturalCategory category,
        string memory culturalRegion,
        string memory _tokenURI,
        string[] memory tags
    ) external payable nonReentrant returns (uint256) {
        require(mintingActive, "Minting not active");
        require(hasRole(VERIFIED_ARTIST, msg.sender) || hasRole(CULTURAL_CURATOR, msg.sender), "Not verified artist");
        require(bytes(title).length > 0, "Title required");
        require(bytes(_tokenURI).length > 0, "Token URI required");
        require(msg.value >= mintFee, "Insufficient mint fee");
        
        uint256 tokenId = currentTokenId++;
        
        // Mint the NFT
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        
        // Create cultural NFT record
        CulturalNFT storage nft = culturalNFTs[tokenId];
        nft.tokenId = tokenId;
        nft.creator = msg.sender;
        nft.title = title;
        nft.description = description;
        nft.category = category;
        nft.culturalRegion = culturalRegion;
        nft.creationTimestamp = block.timestamp;
        nft.tags = tags;
        nft.isVerified = hasRole(VERIFIED_ARTIST, msg.sender);
        nft.isCurated = !curationRequired; // Auto-curated if curation not required
        
        // Set individual royalty for this token
        _setTokenRoyalty(tokenId, msg.sender, uint96(artistRoyaltyPercentage));
        
        // Update statistics
        categoryMintCounts[category]++;
        regionTokens[culturalRegion].push(tokenId);
        
        // Update artist stats
        if (artists[msg.sender].isVerified) {
            artists[msg.sender].totalWorksCreated++;
        }
        
        // Transfer mint fee to treasury
        if (msg.value > 0) {
            payable(culturalTreasury).transfer(msg.value);
        }
        
        emit CulturalNFTMinted(tokenId, msg.sender, category, title);
        return tokenId;
    }
    
    /**
     * @dev Batch mint per collezioni
     * @param to Destinatario degli NFT
     * @param metadataArray Array di metadata per ogni NFT
     */
    function batchMintCultural(
        address to,
        CulturalMintData[] memory metadataArray
    ) external payable nonReentrant returns (uint256[] memory) {
        require(metadataArray.length <= MAX_BATCH_MINT, "Batch too large");
        require(hasRole(VERIFIED_ARTIST, msg.sender) || hasRole(CULTURAL_CURATOR, msg.sender), "Not verified");
        require(msg.value >= mintFee * metadataArray.length, "Insufficient mint fee");
        
        uint256[] memory tokenIds = new uint256[](metadataArray.length);
        
        for (uint256 i = 0; i < metadataArray.length; i++) {
            tokenIds[i] = _mintSingleNFT(to, metadataArray[i]);
        }
        
        // Transfer total mint fee to treasury
        if (msg.value > 0) {
            payable(culturalTreasury).transfer(msg.value);
        }
        
        return tokenIds;
    }
    
    struct CulturalMintData {
        string title;
        string description;
        CulturalCategory category;
        string culturalRegion;
        string tokenURI;
        string[] tags;
    }
    
    function _mintSingleNFT(address to, CulturalMintData memory data) internal returns (uint256) {
        uint256 tokenId = currentTokenId++;
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, data.tokenURI);
        
        // Create cultural NFT record
        CulturalNFT storage nft = culturalNFTs[tokenId];
        nft.tokenId = tokenId;
        nft.creator = msg.sender;
        nft.title = data.title;
        nft.description = data.description;
        nft.category = data.category;
        nft.culturalRegion = data.culturalRegion;
        nft.creationTimestamp = block.timestamp;
        nft.tags = data.tags;
        nft.isVerified = hasRole(VERIFIED_ARTIST, msg.sender);
        nft.isCurated = !curationRequired;
        
        // Set royalty
        _setTokenRoyalty(tokenId, msg.sender, uint96(artistRoyaltyPercentage));
        
        // Update stats
        categoryMintCounts[data.category]++;
        regionTokens[data.culturalRegion].push(tokenId);
        
        emit CulturalNFTMinted(tokenId, msg.sender, data.category, data.title);
        return tokenId;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏛️ CULTURAL CURATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Cura un NFT culturale assegnando un punteggio di impatto
     * @param tokenId ID del token da curare
     * @param impactScore Punteggio di impatto culturale (0-10000)
     * @param curationNotes Note del curatore
     */
    function curateNFT(
        uint256 tokenId,
        uint256 impactScore,
        string memory curationNotes
    ) external onlyRole(CULTURAL_CURATOR) {
        require(_exists(tokenId), "Token does not exist");
        require(impactScore <= 10000, "Impact score too high");
        
        CulturalNFT storage nft = culturalNFTs[tokenId];
        require(!nft.isCurated, "NFT already curated");
        
        nft.culturalImpactScore = impactScore;
        nft.isCurated = true;
        
        // Update global cultural impact
        totalCulturalImpact += impactScore;
        
        // Update artist impact
        if (artists[nft.creator].isVerified) {
            artists[nft.creator].totalCulturalImpact += impactScore;
        }
        
        // Log impact
        _logCulturalImpact(tokenId, impactScore, curationNotes);
        
        emit NFTCurated(tokenId, msg.sender, impactScore);
        emit CulturalImpactScored(tokenId, impactScore, msg.sender);
    }
    
    /**
     * @dev Crea una collezione culturale curata
     * @param collectionName Nome della collezione
     * @param description Descrizione della collezione
     * @param theme Tema della collezione
     * @param tokenIds Array di token ID da includere
     */
    function createCulturalCollection(
        string memory collectionName,
        string memory description,
        string memory theme,
        uint256[] memory tokenIds
    ) external onlyRole(CULTURAL_CURATOR) returns (uint256) {
        require(bytes(collectionName).length > 0, "Collection name required");
        require(tokenIds.length > 0, "No tokens provided");
        
        uint256 collectionId = currentCollectionId++;
        
        CulturalCollection storage collection = collections[collectionId];
        collection.collectionId = collectionId;
        collection.curator = msg.sender;
        collection.collectionName = collectionName;
        collection.description = description;
        collection.theme = theme;
        collection.creationTime = block.timestamp;
        collection.isActive = true;
        
        // Add tokens to collection
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_exists(tokenIds[i]), "Token does not exist");
            collection.tokenIds.push(tokenIds[i]);
        }
        
        emit CollectionCreated(collectionId, msg.sender, collectionName);
        return collectionId;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔧 UTILITY FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function _logCulturalImpact(uint256 tokenId, uint256 impactScore, string memory notes) internal {
        (bool success, ) = impactLogger.call(
            abi.encodeWithSignature(
                "logImpact(string,string,uint256)",
                "cultural_curation",
                string(abi.encodePacked("NFT #", tokenId, " Cultural Impact: ", notes)),
                impactScore
            )
        );
        // Don't revert if logging fails
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 👁️ VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function getCulturalNFT(uint256 tokenId) external view returns (
        uint256 id,
        address creator,
        string memory title,
        string memory description,
        CulturalCategory category,
        string memory culturalRegion,
        uint256 creationTimestamp,
        uint256 culturalImpactScore,
        bool isVerified,
        bool isCurated
    ) {
        CulturalNFT storage nft = culturalNFTs[tokenId];
        return (
            nft.tokenId,
            nft.creator,
            nft.title,
            nft.description,
            nft.category,
            nft.culturalRegion,
            nft.creationTimestamp,
            nft.culturalImpactScore,
            nft.isVerified,
            nft.isCurated
        );
    }
    
    function getArtist(address artistAddress) external view returns (Artist memory) {
        return artists[artistAddress];
    }
    
    function getCollection(uint256 collectionId) external view returns (
        uint256 id,
        address curator,
        string memory collectionName,
        string memory description,
        string memory theme,
        uint256[] memory tokenIds,
        uint256 creationTime,
        bool isActive
    ) {
        CulturalCollection storage collection = collections[collectionId];
        return (
            collection.collectionId,
            collection.curator,
            collection.collectionName,
            collection.description,
            collection.theme,
            collection.tokenIds,
            collection.creationTime,
            collection.isActive
        );
    }
    
    function getTokensByRegion(string memory region) external view returns (uint256[] memory) {
        return regionTokens[region];
    }
    
    function getCategoryMintCount(CulturalCategory category) external view returns (uint256) {
        return categoryMintCounts[category];
    }
    
    function getPlatformStats() external view returns (
        uint256 totalTokens,
        uint256 totalArtists,
        uint256 totalImpact,
        uint256 totalCollections
    ) {
        return (currentTokenId - 1, totalVerifiedArtists, totalCulturalImpact, currentCollectionId - 1);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // ⚙️ ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function setMintFee(uint256 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintFee = newFee;
    }
    
    function setRoyaltyPercentages(uint256 platformPercentage, uint256 artistPercentage) 
        external onlyRole(ROYALTY_MANAGER) 
    {
        require(platformPercentage + artistPercentage <= MAX_ROYALTY_PERCENTAGE, "Total royalty too high");
        platformRoyaltyPercentage = platformPercentage;
        artistRoyaltyPercentage = artistPercentage;
        
        _setDefaultRoyalty(culturalTreasury, uint96(platformPercentage));
    }
    
    function setMintingStatus(bool active) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintingActive = active;
    }
    
    function setCurationRequired(bool required) external onlyRole(CULTURAL_CURATOR) {
        curationRequired = required;
    }
    
    function updateContractReferences(
        address _reputationManager,
        address _impactLogger,
        address _solidaryHub,
        address _culturalTreasury
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_reputationManager != address(0)) reputationManager = _reputationManager;
        if (_impactLogger != address(0)) impactLogger = _impactLogger;
        if (_solidaryHub != address(0)) solidaryHub = _solidaryHub;
        if (_culturalTreasury != address(0)) culturalTreasury = _culturalTreasury;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔄 OVERRIDE FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721RoyaltyUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function _burn(uint256 tokenId) 
        internal 
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable, ERC721RoyaltyUpgradeable) 
    {
        super._burn(tokenId);
    }
}