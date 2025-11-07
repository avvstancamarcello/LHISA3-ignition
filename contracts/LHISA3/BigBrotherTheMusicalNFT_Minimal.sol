// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca - Avv. - ITALY Florence
// Author and architect of the Solidary.it ecosystem and this smart contract.
// The ecosystem and its logical components (.sol files and scripts) are protected by copyright.
// Solidary Network® - Compassionate Blockchain Infrastructure

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// ═══════════════════════════════════════════════════════════════════════════════
// 🌐 SOLIDARY ECOSYSTEM INTERFACES  
// ═══════════════════════════════════════════════════════════════════════════════

interface ISolidaryTrustManager {
    function isValidated(address user) external view returns (bool);
}

interface ISolidaryHub {
    function isActiveMember(address user) external view returns (bool);
}

/**
 * @title BigBrotherTheMusicalNFT - Minimal Deploy Version
 * @author Avv. Marcello Stanca - Solidary Network Architect
 * @notice Collezione NFT musicale del Maestro Stefano Burbi - Versione essenziale per deploy
 * @dev ERC-1155 Upgradeable con funzionalità core per upgrade futuri
 * 
 * 🎭 BBTM Musical Collection - V1.0 Core Features:
 * - 20 NFT musicali unici (Token IDs: 5, 10, 15... 100)
 * - Valori configurati in EUR (da 0.25€ a 5.00€)
 * - Integrazione base Solidary Network  
 * - Mint con royalties automatiche
 * - Upgradeable con pattern UUPS per funzionalità future
 * 
 * © Copyright Marcello Stanca - Solidary Network Ecosystem
 */
contract BigBrotherTheMusicalNFT is 
    Initializable,
    ERC1155Upgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC2981Upgradeable
{
    using Strings for uint256;

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎭 ROLES & ADDRESSES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    bytes32 public constant MAESTRO_ROLE = keccak256("MAESTRO_ROLE");
    bytes32 public constant ECOSYSTEM_MANAGER_ROLE = keccak256("ECOSYSTEM_MANAGER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    ISolidaryTrustManager public solidaryTrustManager;
    ISolidaryHub public solidaryHub;
    address public ecosystemArchitect; // Avv. Marcello Stanca
    address public maestroWallet;      // Maestro Stefano Burbi

    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    string public name;
    string public symbol;
    string private _contractURI;
    string public baseURI;
    
    struct MusicalNFT {
        string title;
        string composer;
        uint256 euroValue;  // Valore in centesimi EUR
        uint256 maxSupply;
        uint256 mintedSupply;
        bool isActive;
    }
    
    mapping(uint256 => MusicalNFT) public musicalNFTs;
    uint256[] public availableTokenIds;
    mapping(uint256 => bool) public isValidTokenId;
    
    uint256 public maestroRoyaltyPercentage;
    bool public solidaryOnlyMode;
    uint256 public contractVersion;

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎯 EVENTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    event MusicalNFTMinted(address indexed recipient, uint256 indexed tokenId, uint256 amount, uint256 totalCost);
    event MusicalNFTConfigured(uint256 indexed tokenId, string title, uint256 euroValue, uint256 maxSupply);
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🚀 INITIALIZATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function initialize(
        string memory _baseURI,
        string memory _contractURIParam,
        address _ecosystemArchitect,
        address _maestroWallet,
        address _trustManager,
        address _solidaryHub
    ) public initializer {
        require(bytes(_baseURI).length > 0, "Base URI cannot be empty");
        require(bytes(_contractURIParam).length > 0, "Contract URI cannot be empty");
        require(_ecosystemArchitect != address(0), "Ecosystem architect cannot be zero");
        require(_maestroWallet != address(0), "Maestro wallet cannot be zero");
        
        __ERC1155_init(_baseURI);
        __AccessControl_init();
        __ReentrancyGuard_init();
        __ERC2981_init();
        __UUPSUpgradeable_init();
        
        name = "BigBrother The Musical";
        symbol = "BBTM";
        baseURI = _baseURI;
        _contractURI = _contractURIParam;
        
        ecosystemArchitect = _ecosystemArchitect;
        maestroWallet = _maestroWallet;
        
        solidaryTrustManager = ISolidaryTrustManager(_trustManager);
        solidaryHub = ISolidaryHub(_solidaryHub);
        
        _grantRole(DEFAULT_ADMIN_ROLE, _ecosystemArchitect);
        _grantRole(MAESTRO_ROLE, _maestroWallet);
        _grantRole(MINTER_ROLE, _ecosystemArchitect);
        
        maestroRoyaltyPercentage = 800; // 8% totali
        solidaryOnlyMode = false;
        contractVersion = 1;
        
        _setDefaultRoyalty(_ecosystemArchitect, 800); // 8%
        
        _initializeMusicalTokens();
    }
    
    function _initializeMusicalTokens() internal {
        // Serie 1: Token economici (5-25)
        _configureMusicalNFT(5, "Ouverture Solidale", "Maestro Stefano Burbi", 25, 2000);
        _configureMusicalNFT(10, "Preludio Compassione", "Maestro Stefano Burbi", 50, 1500);
        _configureMusicalNFT(15, "Aria del Cuore Solidale", "Maestro Stefano Burbi", 75, 1200);
        _configureMusicalNFT(20, "Intermezzo Blockchain", "Maestro Stefano Burbi", 100, 1000);
        _configureMusicalNFT(25, "Sinfonia della Compassion", "Maestro Stefano Burbi", 125, 800);
        
        // Serie 2: Token medi (30-50)
        _configureMusicalNFT(30, "Movimento Solidary Hearts", "Maestro Stefano Burbi", 150, 600);
        _configureMusicalNFT(35, "Crescendo Tecnologico", "Maestro Stefano Burbi", 175, 500);
        _configureMusicalNFT(40, "Variazioni Ecosystem", "Maestro Stefano Burbi", 200, 400);
        _configureMusicalNFT(45, "Fuga Umanita Digitale", "Maestro Stefano Burbi", 225, 300);
        _configureMusicalNFT(50, "Suite dell'Innovazione", "Maestro Stefano Burbi", 250, 250);
        
        // Serie 3: Token premium (55-75)
        _configureMusicalNFT(55, "Rapsodi Solidary Network", "Maestro Stefano Burbi", 275, 200);
        _configureMusicalNFT(60, "Concerto per Smart Contract", "Maestro Stefano Burbi", 300, 150);
        _configureMusicalNFT(65, "Sonata del Trust Manager", "Maestro Stefano Burbi", 325, 120);
        _configureMusicalNFT(70, "Polonaise Governante", "Maestro Stefano Burbi", 350, 100);
        _configureMusicalNFT(75, "Toccata Impact Fund", "Maestro Stefano Burbi", 375, 80);
        
        // Serie 4: Token collector (80-100)
        _configureMusicalNFT(80, "Fantasia Marcello's Dream", "Maestro Stefano Burbi", 400, 60);
        _configureMusicalNFT(85, "Ballata Cross-Chain Bridge", "Maestro Stefano Burbi", 425, 50);
        _configureMusicalNFT(90, "Elegia Memory Hill", "Maestro Stefano Burbi", 450, 40);
        _configureMusicalNFT(95, "Requiem per il Web2", "Maestro Stefano Burbi", 475, 30);
        _configureMusicalNFT(100, "Grande Finale Vision Orchestrale", "Maestro Stefano Burbi", 500, 20);
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎵 MUSICAL NFT CORE FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function _configureMusicalNFT(
        uint256 tokenId,
        string memory title,
        string memory composer,
        uint256 euroValue,
        uint256 maxSupply
    ) internal {
        require(tokenId % 5 == 0, "Token ID must be multiple of 5");
        
        musicalNFTs[tokenId] = MusicalNFT({
            title: title,
            composer: composer,
            euroValue: euroValue,
            maxSupply: maxSupply,
            mintedSupply: 0,
            isActive: true
        });
        
        availableTokenIds.push(tokenId);
        isValidTokenId[tokenId] = true;
        
        emit MusicalNFTConfigured(tokenId, title, euroValue, maxSupply);
    }
    
    function mintMusicalNFT(uint256 tokenId, uint256 amount) external payable nonReentrant {
        require(isValidTokenId[tokenId], "Token ID not configured");
        require(amount > 0, "Amount must be greater than 0");
        
        MusicalNFT storage nft = musicalNFTs[tokenId];
        require(nft.isActive, "Token not active for minting");
        require(nft.mintedSupply + amount <= nft.maxSupply, "Exceeds maximum supply");
        
        // Check Solidary-only mode
        if (solidaryOnlyMode && !isSolidaryTrustedWallet(msg.sender)) {
            revert("Only Solidary members can mint in exclusive mode");
        }
        
        // Payment verification (simplified)
        uint256 totalCost = nft.euroValue * amount;
        require(msg.value >= totalCost * 1e15, "Insufficient payment"); // Rough ETH conversion
        
        nft.mintedSupply += amount;
        _mint(msg.sender, tokenId, amount, "");
        
        emit MusicalNFTMinted(msg.sender, tokenId, amount, totalCost);
    }

    function mintBatchMusicalNFTs(uint256[] memory tokenIds, uint256[] memory amounts) external payable nonReentrant {
        require(tokenIds.length == amounts.length, "Arrays length mismatch");
        require(tokenIds.length > 0, "Empty arrays");
        
        uint256 totalCost = 0;
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 amount = amounts[i];
            
            require(isValidTokenId[tokenId], "Invalid token ID");
            require(amount > 0, "Amount must be greater than 0");
            
            MusicalNFT storage nft = musicalNFTs[tokenId];
            require(nft.isActive, "Token not active");
            require(nft.mintedSupply + amount <= nft.maxSupply, "Exceeds max supply");
            
            nft.mintedSupply += amount;
            totalCost += nft.euroValue * amount;
        }
        
        if (solidaryOnlyMode && !isSolidaryTrustedWallet(msg.sender)) {
            revert("Solidary members only");
        }
        
        require(msg.value >= totalCost * 1e15, "Insufficient payment");
        
        _mintBatch(msg.sender, tokenIds, amounts, "");
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌐 SOLIDARY INTEGRATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function isSolidaryTrustedWallet(address wallet) public view returns (bool) {
        if (address(solidaryTrustManager) == address(0)) return false;
        try solidaryTrustManager.isValidated(wallet) returns (bool isValid) {
            return isValid;
        } catch {
            return false;
        }
    }
    
    function setSolidaryOnlyMode(bool enabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        solidaryOnlyMode = enabled;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 👁️ VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function getMusicalNFTInfo(uint256 tokenId) external view returns (MusicalNFT memory) {
        require(isValidTokenId[tokenId], "Token ID not configured");
        return musicalNFTs[tokenId];
    }
    
    function getAvailableTokenIds() external view returns (uint256[] memory) {
        return availableTokenIds;
    }
    
    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }
    
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔧 ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function setBaseURI(string memory newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = newBaseURI;
    }
    
    function setContractURI(string memory newContractURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _contractURI = newContractURI;
    }
    
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        payable(ecosystemArchitect).transfer(balance);
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔒 REQUIRED OVERRIDES & UPGRADE
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function supportsInterface(bytes4 interfaceId) 
        public view override(ERC1155Upgradeable, AccessControlUpgradeable, ERC2981Upgradeable) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
    
    function _authorizeUpgrade(address newImplementation) 
        internal override onlyRole(DEFAULT_ADMIN_ROLE) 
    {}
}