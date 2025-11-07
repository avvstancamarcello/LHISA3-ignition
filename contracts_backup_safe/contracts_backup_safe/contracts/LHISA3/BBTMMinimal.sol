// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.29;

/**
 * @title BigBrotherTheMusicalNFT - ULTRA MINIMAL
 * @author Avv. Marcello Stanca - Solidary Network Architect
 * @notice Versione ultra-minimale per deployment mainnet - Solo core functionality
 * @dev ERC1155 + UUPS Upgradeable per 20 Musical NFTs (5-100)
 * 
 * 🎭 FEATURES V1.0 MINIMAL CORE:
 * - ✅ 20 Musical NFT tokens (IDs 5,10,15...100)
 * - ✅ EUR pricing system (0.25€ - 5.00€)
 * - ✅ Basic Solidary integration
 * - ✅ UUPS upgradeable pattern
 * - ✅ Access control essentials
 * - ✅ Royalty standard (ERC-2981)
 * 
 * 🚀 UPGRADE ROADMAP (attraverso UUPS):
 * V1.1: Analytics & monitoring
 * V1.2: Advanced features
 * V1.3: Governance
 * 
 * 📦 SIZE OPTIMIZATION:
 * - No batch operations
 * - No governance
 * - No analytics
 * - Minimal error strings
 * - Essential functions only
 */

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract BBTMMinimal is 
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
    
    uint256 public constant EUR_TO_WEI_MULTIPLIER = 1e16; // 0.01€ = 1e16 wei
    uint96 public constant ROYALTY_PERCENTAGE = 500; // 5%
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 STORAGE
    // ═══════════════════════════════════════════════════════════════════════════════
    
    string public contractVersion;
    string public baseURI;
    string private _contractURI;
    
    address public ecosystemArchitect;
    address public maestroWallet;
    address public solidaryTrustManager;
    address public solidaryHub;
    
    bool public solidaryOnlyMode;
    bool public tradingEnabled;
    bool public mintingEnabled;
    
    // Musical NFT data
    mapping(uint256 => uint256) public tokenPricesEur; // Prezzo in centesimi di EUR
    mapping(uint256 => uint256) public maxSupplyPerToken;
    mapping(uint256 => uint256) public mintedSupply;
    mapping(uint256 => string) public tokenTitles;
    
    uint256[] public availableTokenIds;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎉 EVENTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    event MusicalNFTMinted(uint256 indexed tokenId, address indexed to, uint256 amount);
    event PricingUpdated(uint256 indexed tokenId, uint256 newPriceEur);
    event SolidaryModeToggled(bool enabled);
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🚀 INITIALIZATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        string memory _baseURI,
        string memory _contractURI_,
        address _ecosystemArchitect,
        address _maestroWallet,
        address _solidaryTrustManager,
        address _solidaryHub
    ) public initializer {
        __ERC1155_init(_baseURI);
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        contractVersion = "1.0-minimal";
        baseURI = _baseURI;
        _contractURI = _contractURI_;
        
        ecosystemArchitect = _ecosystemArchitect;
        maestroWallet = _maestroWallet;
        solidaryTrustManager = _solidaryTrustManager;
        solidaryHub = _solidaryHub;
        
        // Setup roles
        _grantRole(DEFAULT_ADMIN_ROLE, _ecosystemArchitect);
        _grantRole(ECOSYSTEM_ARCHITECT_ROLE, _ecosystemArchitect);
        _grantRole(MAESTRO_ROLE, _maestroWallet);
        _grantRole(MINTER_ROLE, _maestroWallet);
        
        // Enable basic functionality
        tradingEnabled = true;
        mintingEnabled = true;
        solidaryOnlyMode = false;
        
        // Initialize 20 Musical NFTs
        _initializeMusicalNFTs();
    }
    
    function _initializeMusicalNFTs() internal {
        // 20 Musical NFT tokens: 5, 10, 15, 20... 100
        uint256[20] memory tokenIds = [uint256(5),10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100];
        uint256[20] memory supplies = [uint256(2000),1900,1800,1700,1600,1500,1400,1300,1200,1100,1000,900,800,700,600,500,400,300,200,100];
        uint256[20] memory prices = [uint256(25),30,35,40,45,50,60,70,80,90,100,120,150,180,220,280,350,420,480,500]; // Centesimi EUR
        
        string[20] memory titles = [
            "Entry Melody 1", "Entry Melody 2", "Entry Melody 3", "Entry Melody 4", "Entry Melody 5",
            "Intermediate 1", "Intermediate 2", "Intermediate 3", "Intermediate 4", "Intermediate 5",
            "Premium 1", "Premium 2", "Premium 3", "Premium 4", "Premium 5",
            "Ultra Rare 1", "Ultra Rare 2", "Ultra Rare 3", "Ultra Rare 4", "Masterpiece"
        ];
        
        for (uint256 i = 0; i < 20; i++) {
            uint256 tokenId = tokenIds[i];
            tokenPricesEur[tokenId] = prices[i];
            maxSupplyPerToken[tokenId] = supplies[i];
            tokenTitles[tokenId] = titles[i];
            availableTokenIds.push(tokenId);
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎵 CORE MINTING
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function mintMusicalNFT(uint256 tokenId, uint256 amount) external payable {
        require(mintingEnabled, "Minting disabled");
        require(tokenPricesEur[tokenId] > 0, "Invalid token");
        require(amount > 0 && amount <= 10, "Invalid amount");
        require(mintedSupply[tokenId] + amount <= maxSupplyPerToken[tokenId], "Supply exceeded");
        
        if (solidaryOnlyMode) {
            require(_isSolidaryMember(msg.sender), "Solidary only");
        }
        
        uint256 totalPrice = (tokenPricesEur[tokenId] * EUR_TO_WEI_MULTIPLIER * amount) / 100;
        require(msg.value >= totalPrice, "Insufficient payment");
        
        mintedSupply[tokenId] += amount;
        _mint(msg.sender, tokenId, amount, "");
        
        // Refund excess
        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
        
        emit MusicalNFTMinted(tokenId, msg.sender, amount);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔍 VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function name() public pure returns (string memory) {
        return "Big Brother The Musical NFT";
    }
    
    function symbol() public pure returns (string memory) {
        return "BBTM";
    }
    
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function getAvailableTokenIds() external view returns (uint256[] memory) {
        return availableTokenIds;
    }
    
    function getMusicalNFTInfo(uint256 tokenId) external view returns (
        string memory title,
        uint256 euroValue,
        uint256 maxSupply,
        uint256 minted
    ) {
        require(tokenPricesEur[tokenId] > 0, "Invalid token");
        return (
            tokenTitles[tokenId],
            tokenPricesEur[tokenId],
            maxSupplyPerToken[tokenId],
            mintedSupply[tokenId]
        );
    }
    
    function totalSupply(uint256 tokenId) external view returns (uint256) {
        return mintedSupply[tokenId];
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏛️ ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function setBaseURI(string memory newBaseURI) external onlyRole(ECOSYSTEM_ARCHITECT_ROLE) {
        baseURI = newBaseURI;
        _setURI(newBaseURI);
    }
    
    function setContractURI(string memory newContractURI) external onlyRole(ECOSYSTEM_ARCHITECT_ROLE) {
        _contractURI = newContractURI;
    }
    
    function toggleSolidaryMode() external onlyRole(ECOSYSTEM_ARCHITECT_ROLE) {
        solidaryOnlyMode = !solidaryOnlyMode;
        emit SolidaryModeToggled(solidaryOnlyMode);
    }
    
    function toggleMinting() external onlyRole(ECOSYSTEM_ARCHITECT_ROLE) {
        mintingEnabled = !mintingEnabled;
    }
    
    function updateTokenPrice(uint256 tokenId, uint256 newPriceEur) 
        external 
        onlyRole(MAESTRO_ROLE) 
    {
        require(tokenPricesEur[tokenId] > 0, "Invalid token");
        tokenPricesEur[tokenId] = newPriceEur;
        emit PricingUpdated(tokenId, newPriceEur);
    }
    
    function withdraw() external onlyRole(MAESTRO_ROLE) {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds");
        payable(maestroWallet).transfer(balance);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 💎 ROYALTY IMPLEMENTATION (ERC-2981)
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function royaltyInfo(uint256, uint256 salePrice) 
        external 
        view 
        override 
        returns (address receiver, uint256 royaltyAmount) 
    {
        receiver = maestroWallet;
        royaltyAmount = (salePrice * ROYALTY_PERCENTAGE) / 10000;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌐 SOLIDARY INTEGRATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function _isSolidaryMember(address account) internal view returns (bool) {
        if (solidaryTrustManager == address(0)) return true;
        
        // Basic check - in upgrade will implement full verification
        (bool success, bytes memory result) = solidaryTrustManager.staticcall(
            abi.encodeWithSignature("isTrustedMember(address)", account)
        );
        
        if (!success || result.length == 0) return false;
        return abi.decode(result, (bool));
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔄 UPGRADE AUTHORIZATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function _authorizeUpgrade(address newImplementation) 
        internal 
        override 
        onlyRole(ECOSYSTEM_ARCHITECT_ROLE) 
    {}
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔧 INTERFACE SUPPORT
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        override(ERC1155Upgradeable, AccessControlUpgradeable, IERC165Upgradeable) 
        returns (bool) 
    {
        return interfaceId == type(IERC2981Upgradeable).interfaceId || 
               super.supportsInterface(interfaceId);
    }
    
    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, _toString(tokenId), ".json"));
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🛠️ UTILITIES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}