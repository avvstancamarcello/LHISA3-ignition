// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.29;

import "./core/RefundManager.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";

/**
 * @title BigBrotherTheMusicalNFT_V2_WithRefund
 * @author Avv. Marcello Stanca - Solidary Network Architect
 * @notice NFT Collection Big Brother The Musical con protezione refund integrata
 * @dev Upgrade del sistema BBTM NFT con RefundManager per protezione investitori
 * 
 * 🎭 BBTM + REFUND SYSTEM:
 * - Collezione NFT da 20 pezzi con pricing EUR (0.25€-5.00€)
 * - Frasi nascoste di Orwell distribuite nei metadati
 * - Protezione acquirenti con soglia globale 100.000 EUR
 * - Refund automatico se ecosistema Solidary non raggiunge target
 * - Royalty ERC2981 + distribuzione automatica Solidary
 * 
 * 🎨 ORWELL MARKETING + INVESTOR PROTECTION:
 * Combina arte digitale con garanzie economiche
 */
contract BigBrotherTheMusicalNFT_V2_WithRefund is 
    RefundManager, 
    ERC721Upgradeable, 
    AccessControlUpgradeable,
    ERC2981Upgradeable 
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎭 BBTM SPECIFIC CONSTANTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");
    
    /// @notice Totale NFT nella collezione
    uint256 public constant MAX_SUPPLY = 20;
    
    /// @notice Base URI per metadati
    string public baseTokenURI;
    
    /// @notice Counter per token IDs
    CountersUpgradeable.Counter private _tokenIdCounter;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 💰 PRICING SYSTEM
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @notice Mapping ID → Prezzo in EUR (wei equivalent)
    mapping(uint256 => uint256) public tokenPriceEUR;
    
    /// @notice Mapping owner → NFT acquistati (per refund tracking)
    mapping(address => uint256[]) public userNFTs;
    
    /// @notice Mapping tokenId → Orwell phrase
    mapping(uint256 => string) public orwellPhrases;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 NFT DATA STRUCTURES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    struct NFTData {
        uint256 tokenId;
        uint256 priceEUR;
        string orwellPhrase;
        string imageURI;
        address currentOwner;
        bool minted;
    }
    
    /// @notice Array con tutti i dati NFT
    NFTData[] public nftCollection;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📢 EVENTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    event NFTMinted(uint256 indexed tokenId, address indexed to, uint256 priceEUR, string orwellPhrase);
    event PriceUpdated(uint256 indexed tokenId, uint256 newPriceEUR);
    event OrwellPhraseSet(uint256 indexed tokenId, string phrase);
    event BaseURIUpdated(string newBaseURI);
    event NFTRefunded(address indexed user, uint256[] tokenIds, uint256 refundAmount);
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏗️ INITIALIZATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        address _creatorWallet,
        address _solidaryWallet,
        uint256 _refundDeadline
    ) public initializer {
        __RefundManager_init(_creatorWallet, _solidaryWallet, _refundDeadline);
        __ERC721_init(_name, _symbol);
        __AccessControl_init();
        __ERC2981_init();
        
        baseTokenURI = _baseTokenURI;
        
        // Setup roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(CURATOR_ROLE, msg.sender);
        
        // Setup royalty (5% per ERC2981)
        _setDefaultRoyalty(creatorWallet, 500); // 5%
        
        // Inizializza collezione NFT
        _initializeNFTCollection();
    }
    
    /**
     * @notice Inizializza la collezione con 20 NFT e frasi Orwell
     */
    function _initializeNFTCollection() internal {
        // Array con le 20 frasi di Orwell distribuite
        string[20] memory phrases = [
            "War is peace.",
            "Freedom is slavery.", 
            "Ignorance is strength.",
            "Big Brother is watching.",
            "Doublethink means the power.",
            "Who controls the past controls.",
            "Reality exists in the mind.",
            "Power is not a means.",
            "The party seeks power entirely.",
            "Orthodoxy means not thinking.",
            "Freedom is the freedom to.",
            "In the face of pain there.",
            "The best books are those that.",
            "Perhaps one did not want to.",
            "The object of persecution is.",
            "If you want a picture of.",
            "Until they become conscious they.",
            "The proles are not human beings.",
            "Sanity is not statistical.",
            "The aim of a joke is not."
        ];
        
        // Prezzi in EUR (da 0.25€ a 5.00€) - cast esplicito a uint256
        uint256[20] memory prices;
        prices[0] = 0.25 ether; prices[1] = 0.50 ether; prices[2] = 0.75 ether; prices[3] = 1.00 ether;
        prices[4] = 1.25 ether; prices[5] = 1.50 ether; prices[6] = 1.75 ether; prices[7] = 2.00 ether;
        prices[8] = 2.25 ether; prices[9] = 2.50 ether; prices[10] = 2.75 ether; prices[11] = 3.00 ether;
        prices[12] = 3.25 ether; prices[13] = 3.50 ether; prices[14] = 3.75 ether; prices[15] = 4.00 ether;
        prices[16] = 4.25 ether; prices[17] = 4.50 ether; prices[18] = 4.75 ether; prices[19] = 5.00 ether;
        
        // Inizializza la collezione
        for (uint256 i = 0; i < MAX_SUPPLY; i++) {
            uint256 tokenId = (i + 1) * 5; // IDs: 5, 10, 15, ..., 100
            
            nftCollection.push(NFTData({
                tokenId: tokenId,
                priceEUR: prices[i],
                orwellPhrase: phrases[i],
                imageURI: string(abi.encodePacked(tokenId, "_watermarked.png")),
                currentOwner: address(0),
                minted: false
            }));
            
            tokenPriceEUR[tokenId] = prices[i];
            orwellPhrases[tokenId] = phrases[i];
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎨 MINTING SYSTEM WITH REFUND PROTECTION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Mint NFT specifico con protezione refund
     * @param tokenId ID del token da mintare
     */
    function mintNFT(uint256 tokenId) external payable nonReentrant {
        require(_isValidTokenId(tokenId), "Invalid token ID");
        require(!_exists(tokenId), "Token already minted");
        require(msg.value >= tokenPriceEUR[tokenId], "Insufficient payment");
        
        // Registra contribuzione per sistema refund
        _recordContribution(msg.sender, msg.value);
        
        // Mint NFT
        _safeMint(msg.sender, tokenId);
        _tokenIdCounter.increment();
        
        // Aggiorna tracking
        userNFTs[msg.sender].push(tokenId);
        _updateNFTData(tokenId, msg.sender);
        
        emit NFTMinted(tokenId, msg.sender, tokenPriceEUR[tokenId], orwellPhrases[tokenId]);
    }
    
    /**
     * @notice Batch mint multipli NFT
     * @param tokenIds Array di token IDs da mintare
     */
    function batchMintNFTs(uint256[] memory tokenIds) external payable nonReentrant {
        uint256 totalPrice = 0;
        
        // Calcola prezzo totale
        for (uint i = 0; i < tokenIds.length; i++) {
            require(_isValidTokenId(tokenIds[i]), "Invalid token ID");
            require(!_exists(tokenIds[i]), "Token already minted");
            totalPrice += tokenPriceEUR[tokenIds[i]];
        }
        
        require(msg.value >= totalPrice, "Insufficient payment");
        
        // Registra contribuzione per sistema refund
        _recordContribution(msg.sender, msg.value);
        
        // Mint tutti gli NFT
        for (uint i = 0; i < tokenIds.length; i++) {
            _safeMint(msg.sender, tokenIds[i]);
            _tokenIdCounter.increment();
            userNFTs[msg.sender].push(tokenIds[i]);
            _updateNFTData(tokenIds[i], msg.sender);
            
            emit NFTMinted(tokenIds[i], msg.sender, tokenPriceEUR[tokenIds[i]], orwellPhrases[tokenIds[i]]);
        }
    }
    
    /**
     * @notice Aggiorna dati NFT dopo mint
     */
    function _updateNFTData(uint256 tokenId, address owner) internal {
        for (uint i = 0; i < nftCollection.length; i++) {
            if (nftCollection[i].tokenId == tokenId) {
                nftCollection[i].currentOwner = owner;
                nftCollection[i].minted = true;
                break;
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔄 REFUND SYSTEM INTEGRATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Hook specifico per BBTM durante refund
     * @dev Brucia gli NFT dell'utente durante il refund
     * @param user Utente che richiede refund
     * @param originalAmount Importo originale della contribuzione
     */
    function _processRefundHook(address user, uint256 originalAmount) internal override {
        uint256[] memory userTokens = userNFTs[user];
        uint256[] memory tokensToBurn = new uint256[](userTokens.length);
        uint256 burnCount = 0;
        
        // Identifica NFT da bruciare
        for (uint i = 0; i < userTokens.length; i++) {
            uint256 tokenId = userTokens[i];
            if (_exists(tokenId) && ownerOf(tokenId) == user) {
                tokensToBurn[burnCount] = tokenId;
                burnCount++;
            }
        }
        
        // Brucia gli NFT
        for (uint i = 0; i < burnCount; i++) {
            uint256 tokenId = tokensToBurn[i];
            _burn(tokenId);
            
            // Aggiorna dati collezione
            _updateNFTDataAfterBurn(tokenId);
        }
        
        // Pulisci array user NFTs
        delete userNFTs[user];
        
        emit NFTRefunded(user, tokensToBurn, originalAmount);
    }
    
    /**
     * @notice Aggiorna dati NFT dopo burn
     */
    function _updateNFTDataAfterBurn(uint256 tokenId) internal {
        for (uint i = 0; i < nftCollection.length; i++) {
            if (nftCollection[i].tokenId == tokenId) {
                nftCollection[i].currentOwner = address(0);
                nftCollection[i].minted = false;
                break;
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Ottieni dati completi di un NFT
     */
    function getNFTData(uint256 tokenId) external view returns (NFTData memory) {
        for (uint i = 0; i < nftCollection.length; i++) {
            if (nftCollection[i].tokenId == tokenId) {
                return nftCollection[i];
            }
        }
        revert("Token not found");
    }
    
    /**
     * @notice Ottieni intera collezione NFT
     */
    function getFullCollection() external view returns (NFTData[] memory) {
        return nftCollection;
    }
    
    /**
     * @notice Ottieni NFT posseduti da un utente
     */
    function getUserNFTs(address user) external view returns (uint256[] memory) {
        return userNFTs[user];
    }
    
    /**
     * @notice Controlla se tokenId è valido per questa collezione
     */
    function _isValidTokenId(uint256 tokenId) internal pure returns (bool) {
        return tokenId >= 5 && tokenId <= 100 && tokenId % 5 == 0;
    }
    
    /**
     * @notice Override tokenURI per metadati personalizzati
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        
        return string(abi.encodePacked(
            baseTokenURI,
            "watermarked_double_compressed/",
            StringsUpgradeable.toString(tokenId),
            "_watermarked.png"
        ));
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔐 ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Aggiorna base URI (solo admin)
     */
    function setBaseURI(string memory _newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseTokenURI = _newBaseURI;
        emit BaseURIUpdated(_newBaseURI);
    }
    
    /**
     * @notice Aggiorna prezzo NFT (solo curator)
     */
    function updateTokenPrice(uint256 tokenId, uint256 newPriceEUR) 
        external 
        onlyRole(CURATOR_ROLE) 
    {
        require(_isValidTokenId(tokenId), "Invalid token ID");
        tokenPriceEUR[tokenId] = newPriceEUR;
        
        // Aggiorna anche nella collezione
        for (uint i = 0; i < nftCollection.length; i++) {
            if (nftCollection[i].tokenId == tokenId) {
                nftCollection[i].priceEUR = newPriceEUR;
                break;
            }
        }
        
        emit PriceUpdated(tokenId, newPriceEUR);
    }
    
    /**
     * @notice Aggiorna frase Orwell (solo curator)
     */
    function updateOrwellPhrase(uint256 tokenId, string memory newPhrase) 
        external 
        onlyRole(CURATOR_ROLE) 
    {
        require(_isValidTokenId(tokenId), "Invalid token ID");
        orwellPhrases[tokenId] = newPhrase;
        
        // Aggiorna anche nella collezione
        for (uint i = 0; i < nftCollection.length; i++) {
            if (nftCollection[i].tokenId == tokenId) {
                nftCollection[i].orwellPhrase = newPhrase;
                break;
            }
        }
        
        emit OrwellPhraseSet(tokenId, newPhrase);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔄 INTERFACE SUPPORT
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        override(ERC721Upgradeable, AccessControlUpgradeable, ERC2981Upgradeable) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
}