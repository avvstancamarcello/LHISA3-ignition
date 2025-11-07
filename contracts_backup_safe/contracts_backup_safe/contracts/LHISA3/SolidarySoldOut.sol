// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.29;

/**
 * @title SolidarySoldOut - Musical NFT Collection
 * @author Avv. Marcello Stanca - Solidary Network Architect
 * @notice Collection NFT "Big Brother The Musical" - Quando l'arte incontra il sold out eterno
 * @dev ERC1155 + UUPS Upgradeable per 20 Musical NFTs collezionabili (5-100)
 * 
 * 🎭 SOLDOUT: Il sogno di ogni spettacolo teatrale!
 * - SOLD OUT = Successo totale della rappresentazione
 * - SOL = Connessione al brand Solidary + nota musicale dominante
 * - OUT = Outstanding, esclusivo, unico per collezionisti
 * 
 * 💎 COLLECTION FEATURES V1.0:
 * - ✅ 20 Musical NFT tokens (IDs 5,10,15...100) 
 * - ✅ EUR pricing system (0.25€ - 5.00€)
 * - ✅ Solidary ecosystem integration
 * - ✅ UUPS upgradeable pattern
 * - ✅ Access control & royalties
 * - ✅ Collector-focused design
 * 
 * 🎵 MUSICAL THEORY CONNECTION:
 * Questo contratto rappresenta la "risoluzione armonica" del sistema:
 * SOLMUS (crowdfunding) crea tensione → SOLDOUT (collezione) risolve in successo!
 * 
 * 🚀 UPGRADE ROADMAP (attraverso UUPS):
 * V1.1: Advanced collector features
 * V1.2: Royalty sharing system
 * V1.3: Community governance
 * 
 * 📦 SIZE OPTIMIZATION:
 * - Core collection functionality
 * - Essential collector features
 * - Minimal gas consumption
 * - Optimized for mainnet
 */

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SolidarySoldOut is 
    Initializable,
    ERC1155Upgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    IERC2981Upgradeable
{
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏷️ ROLES & CONSTANTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    bytes32 public constant ECOSYSTEM_ARCHITECT_ROLE = keccak256("ECOSYSTEM_ARCHITECT_ROLE");
    bytes32 public constant MAESTRO_ROLE = keccak256("MAESTRO_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    // 🎭 Musical NFT Configuration
    uint256 public constant TOTAL_MUSICAL_NFTS = 20;
    uint256 public constant START_TOKEN_ID = 5;
    uint256 public constant TOKEN_ID_INCREMENT = 5;
    uint256 public constant MAX_TOKEN_ID = 100;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 💎 COLLECTOR STORAGE
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @notice Contract metadata URI
    string private _contractURI;
    
    /// @notice Prezzi in EUR (convertiti in wei) per ogni token ID
    mapping(uint256 => uint256) public tokenPricesEUR;
    
    /// @notice Tracking dei mint per token ID  
    mapping(uint256 => uint256) public tokenMintCounts;
    
    /// @notice Supply massima per token (per scarsità)
    mapping(uint256 => uint256) public maxSupplyPerToken;
    
    /// @notice Collector addresses che possiedono ogni token
    mapping(uint256 => address[]) public tokenCollectors;
    
    /// @notice Check se indirizzo possiede token specifico
    mapping(address => mapping(uint256 => bool)) public isCollectorOfToken;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏛️ SOLIDARY ECOSYSTEM INTEGRATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    address public ecosystemArchitect;
    address public maestroWallet; 
    address public trustManager;
    address public solidaryHub;
    
    /// @notice Modalità "solo Solidary" per accesso esclusivo
    bool public solidaryOnlyMode;
    
    /// @notice Royalty percentage (basis points)
    uint256 public royaltyPercentage;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎪 EVENTS - La sinfonia del sold out
    // ═══════════════════════════════════════════════════════════════════════════════
    
    event CollectorPurchase(
        address indexed collector,
        uint256 indexed tokenId, 
        uint256 amount,
        uint256 pricePerToken,
        string trackTitle
    );
    
    event TokenSoldOut(uint256 indexed tokenId, uint256 totalCollectors);
    event CollectorBadgeEarned(address indexed collector, uint256 tokenId);
    event SoldOutMilestone(uint256 totalTokensSoldOut, uint256 totalCollectors);
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎵 INITIALIZATION - L'accordatura del sold out
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    /**
     * @notice Inizializza la collezione SolidarySoldOut
     * @param baseURI URI base per i metadata NFT su IPFS
     * @param contractURI_ URI per metadata del contratto
     * @param ecosystemArchitect_ Indirizzo dell'architetto ecosistema
     * @param maestroWallet_ Wallet del maestro/creator
     * @param trustManager_ Indirizzo del Trust Manager
     * @param solidaryHub_ Indirizzo del Solidary Hub
     */
    function initialize(
        string memory baseURI,
        string memory contractURI_,
        address ecosystemArchitect_,
        address maestroWallet_,
        address trustManager_,
        address solidaryHub_
    ) public initializer {
        __ERC1155_init(baseURI);
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        // Setup ruoli
        _grantRole(DEFAULT_ADMIN_ROLE, maestroWallet_);
        _grantRole(ECOSYSTEM_ARCHITECT_ROLE, ecosystemArchitect_);
        _grantRole(MAESTRO_ROLE, maestroWallet_);
        _grantRole(MINTER_ROLE, maestroWallet_);
        
        // Configurazione contratto
        _contractURI = contractURI_;
        ecosystemArchitect = ecosystemArchitect_;
        maestroWallet = maestroWallet_;
        trustManager = trustManager_;
        solidaryHub = solidaryHub_;
        
        // Setup royalties (5%)
        royaltyPercentage = 500; // 5% in basis points
        
        // Inizializza prezzi Musical NFT (0.25€ - 5.00€)
        _initializeMusicalNFTPricing();
        
        // Set supply limits per scarsità collezione
        _initializeSupplyLimits();
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 💰 PRICING SYSTEM - Il listino del sold out
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function _initializeMusicalNFTPricing() internal {
        // Prezzi crescenti per 20 Musical NFTs (IDs 5-100)
        // Da 0.25€ a 5.00€ in progressione
        uint256 basePrice = 25; // 0.25€ in centesimi
        
        for (uint256 i = 0; i < TOTAL_MUSICAL_NFTS; i++) {
            uint256 tokenId = START_TOKEN_ID + (i * TOKEN_ID_INCREMENT);
            uint256 priceInCents = basePrice + (i * 25); // +0.25€ per ogni token
            
            // Converti da centesimi EUR a wei (1 centesimo = 10^16 wei)
            tokenPricesEUR[tokenId] = priceInCents * 1e16;
        }
    }
    
    function _initializeSupplyLimits() internal {
        // Supply limitata per creare scarsità da collezione
        for (uint256 i = 0; i < TOTAL_MUSICAL_NFTS; i++) {
            uint256 tokenId = START_TOKEN_ID + (i * TOKEN_ID_INCREMENT);
            // Supply inversamente proporzionale al prezzo per bilanciare rarità
            maxSupplyPerToken[tokenId] = 1000 - (i * 25); // Da 1000 a 525
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🛒 COLLECTOR PURCHASE FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Acquista Musical NFT per collezione
     * @param tokenId ID del token musicale (5-100, multipli di 5)
     * @param amount Quantità da acquistare
     */
    function collectMusicalNFT(uint256 tokenId, uint256 amount) external payable {
        require(_isValidMusicalTokenId(tokenId), "Invalid token ID");
        require(amount > 0, "Amount must be > 0");
        require(
            tokenMintCounts[tokenId] + amount <= maxSupplyPerToken[tokenId], 
            "Exceeds max supply - SOLD OUT!"
        );
        
        // Calcola prezzo totale
        uint256 totalPrice = tokenPricesEUR[tokenId] * amount;
        require(msg.value >= totalPrice, "Insufficient payment");
        
        // Mint NFT al collezionista
        _mint(msg.sender, tokenId, amount, "");
        
        // Aggiorna tracking
        tokenMintCounts[tokenId] += amount;
        
        // Aggiungi a lista collezionisti se primo acquisto
        if (!isCollectorOfToken[msg.sender][tokenId]) {
            tokenCollectors[tokenId].push(msg.sender);
            isCollectorOfToken[msg.sender][tokenId] = true;
            emit CollectorBadgeEarned(msg.sender, tokenId);
        }
        
        // Get track title per evento
        string memory trackTitle = _getTrackTitle(tokenId);
        
        emit CollectorPurchase(msg.sender, tokenId, amount, tokenPricesEUR[tokenId], trackTitle);
        
        // Check se token è sold out
        if (tokenMintCounts[tokenId] == maxSupplyPerToken[tokenId]) {
            emit TokenSoldOut(tokenId, tokenCollectors[tokenId].length);
        }
        
        // Rimborso excess payment
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }
    
    /**
     * @notice Acquista multiple tokens in batch (per collezionisti seri)
     * @param tokenIds Array di token IDs
     * @param amounts Array di quantità
     */
    function batchCollectMusicalNFTs(uint256[] memory tokenIds, uint256[] memory amounts) external payable {
        require(tokenIds.length == amounts.length, "Arrays length mismatch");
        
        uint256 totalCost = 0;
        
        // Calcola costo totale
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_isValidMusicalTokenId(tokenIds[i]), "Invalid token ID");
            totalCost += tokenPricesEUR[tokenIds[i]] * amounts[i];
        }
        
        require(msg.value >= totalCost, "Insufficient payment");
        
        // Esegui mint per ogni token
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (amounts[i] > 0) {
                // Usa internal per evitare duplicate checks
                _collectInternal(tokenIds[i], amounts[i]);
            }
        }
        
        // Rimborso excess
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }
    
    function _collectInternal(uint256 tokenId, uint256 amount) internal {
        require(
            tokenMintCounts[tokenId] + amount <= maxSupplyPerToken[tokenId], 
            "Token sold out"
        );
        
        _mint(msg.sender, tokenId, amount, "");
        tokenMintCounts[tokenId] += amount;
        
        if (!isCollectorOfToken[msg.sender][tokenId]) {
            tokenCollectors[tokenId].push(msg.sender);
            isCollectorOfToken[msg.sender][tokenId] = true;
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 COLLECTOR VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function getCollectorProfile(address collector) external view returns (
        uint256 totalTokensOwned,
        uint256 uniqueTokensOwned, 
        uint256[] memory ownedTokenIds,
        bool isWhaleCollector
    ) {
        uint256 uniqueCount = 0;
        uint256[] memory tempIds = new uint256[](TOTAL_MUSICAL_NFTS);
        
        for (uint256 i = 0; i < TOTAL_MUSICAL_NFTS; i++) {
            uint256 tokenId = START_TOKEN_ID + (i * TOKEN_ID_INCREMENT);
            uint256 balance = balanceOf(collector, tokenId);
            
            if (balance > 0) {
                tempIds[uniqueCount] = tokenId;
                uniqueCount++;
                totalTokensOwned += balance;
            }
        }
        
        // Create properly sized array
        ownedTokenIds = new uint256[](uniqueCount);
        for (uint256 i = 0; i < uniqueCount; i++) {
            ownedTokenIds[i] = tempIds[i];
        }
        
        uniqueTokensOwned = uniqueCount;
        isWhaleCollector = uniqueCount >= 10; // 50%+ della collezione
    }
    
    function getTokenCollectionInfo(uint256 tokenId) external view returns (
        uint256 currentSupply,
        uint256 maxSupply,
        uint256 priceEUR,
        uint256 totalCollectors,
        bool isSoldOut,
        string memory trackTitle
    ) {
        require(_isValidMusicalTokenId(tokenId), "Invalid token ID");
        
        currentSupply = tokenMintCounts[tokenId];
        maxSupply = maxSupplyPerToken[tokenId];
        priceEUR = tokenPricesEUR[tokenId];
        totalCollectors = tokenCollectors[tokenId].length;
        isSoldOut = currentSupply == maxSupply;
        trackTitle = _getTrackTitle(tokenId);
    }
    
    function getSoldOutStats() external view returns (
        uint256 totalTokensSoldOut,
        uint256 totalCollectors,
        uint256 totalRevenue,
        uint256 collectionCompletionPercentage
    ) {
        uint256 soldOutCount = 0;
        uint256 uniqueCollectors = 0;
        uint256 revenue = 0;
        
        // Count stats across all tokens
        for (uint256 i = 0; i < TOTAL_MUSICAL_NFTS; i++) {
            uint256 tokenId = START_TOKEN_ID + (i * TOKEN_ID_INCREMENT);
            
            if (tokenMintCounts[tokenId] == maxSupplyPerToken[tokenId]) {
                soldOutCount++;
            }
            
            revenue += tokenMintCounts[tokenId] * tokenPricesEUR[tokenId];
        }
        
        totalTokensSoldOut = soldOutCount;
        totalRevenue = revenue;
        collectionCompletionPercentage = (soldOutCount * 100) / TOTAL_MUSICAL_NFTS;
        
        // TODO: Calculate unique collectors across all tokens
        totalCollectors = _countUniqueCollectors();
    }
    
    function _countUniqueCollectors() internal view returns (uint256) {
        // Simplified - in production use more gas-efficient method
        return 0; // Placeholder
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎵 MUSICAL UTILITIES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function _isValidMusicalTokenId(uint256 tokenId) internal pure returns (bool) {
        return tokenId >= START_TOKEN_ID && 
               tokenId <= MAX_TOKEN_ID && 
               (tokenId - START_TOKEN_ID) % TOKEN_ID_INCREMENT == 0;
    }
    
    function _getTrackTitle(uint256 tokenId) internal pure returns (string memory) {
        // Simplified track mapping - in production load from IPFS
        if (tokenId == 5) return "Opening Theme";
        if (tokenId == 10) return "Solidarity March";
        if (tokenId == 15) return "Digital Dreams";
        if (tokenId == 20) return "Network Harmony";
        if (tokenId == 100) return "Grand Finale";
        return "Musical Track";
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 💎 ROYALTY IMPLEMENTATION (ERC-2981)
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function royaltyInfo(uint256 tokenId, uint256 salePrice) 
        external view override returns (address, uint256) 
    {
        return (maestroWallet, (salePrice * royaltyPercentage) / 10000);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔧 ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function withdraw() external onlyRole(MAESTRO_ROLE) {
        payable(maestroWallet).transfer(address(this).balance);
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function setSolidaryOnlyMode(bool enabled) external onlyRole(ECOSYSTEM_ARCHITECT_ROLE) {
        solidaryOnlyMode = enabled;
    }
    
    function updateRoyaltyPercentage(uint256 newPercentage) external onlyRole(MAESTRO_ROLE) {
        require(newPercentage <= 1000, "Max 10%"); // Max 10%
        royaltyPercentage = newPercentage;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔐 UPGRADE & INTERFACE SUPPORT
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function _authorizeUpgrade(address newImplementation) 
        internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
    
    function supportsInterface(bytes4 interfaceId) 
        public view virtual override(ERC1155Upgradeable, AccessControlUpgradeable, IERC165Upgradeable) 
        returns (bool) 
    {
        return interfaceId == type(IERC2981Upgradeable).interfaceId ||
               super.supportsInterface(interfaceId);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎭 SOLDOUT SIGNATURE - Il sigillo del successo
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Restituisce la firma della collezione SOLDOUT
     * @dev Messaggio speciale per collezionisti e teoria musicale
     */
    function getSoldOutSignature() external pure returns (string memory) {
        return "SOLDOUT: When art meets eternal success! From SOLMUS crowdfunding to SOLDOUT collection - the perfect harmonic resolution of solidarity and musical excellence!";
    }
    
    /**
     * @notice Versione e info del contratto
     */
    function getContractInfo() external pure returns (
        string memory contractName,
        string memory contractSymbol, 
        uint256 version,
        uint256 totalTokenTypes,
        string memory description
    ) {
        return (
            "SolidarySoldOut",
            "SOLDOUT", 
            1,
            TOTAL_MUSICAL_NFTS,
            "Musical NFT Collection - Big Brother The Musical - Collector's Edition"
        );
    }
}