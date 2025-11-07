// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;
// Copyright Marcello Stanca, Lawyer, Italy, Florence.
// This smart contract is a modular element of the SolidarySystem ecosystem/project, deployed on Polygon and Base networks.

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// Impact tracker interface
interface IOceanMangaImpactTracker {
    function logMintImpact(
        address minter,
        uint256 nftId,
        uint256 charityAmount,
        uint256 ftTokensMinted,
        string memory photoCategory,
        bool isRareNFT
    ) external returns (uint256 impactScore);
}

// Interfacce corrette per i contratti deployati
interface IOceanMangaNFT {
    function mint(address to, uint256 id, uint256 amount, bytes calldata data) external;
}

interface ILunaComicsFT {
    // Cosmix FT mint is non-payable and controlled by MINTER_ROLE
    function mint(address to, uint256 amount) external;
}

// Interfacce per conformità con i contratti esistenti
interface ISolidaryOrchestratorReadable {
    function nftPlanetContract() external view returns (address);
    function ftSatelliteContract() external view returns (address);
}

interface ISolidaryOrchestratorReadableFT {
    function nftPlanetContract() external view returns (address);
    function ftSatelliteContract() external view returns (address);
}

contract OceanMangaOrchestratorV2 is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, ISolidaryOrchestratorReadable, ISolidaryOrchestratorReadableFT {
    IOceanMangaNFT public oceanMangaNFT;
    ILunaComicsFT public lunaComicsFT;
    IOceanMangaImpactTracker public impactTracker;
    
    address public creator;
    address public charityFund;

    // Percentuali (base 1000 per maggiore precisione)
    uint256 public constant NFT_SHARE = 550;      // 55%
    uint256 public constant FT_SHARE = 450;       // 45%
    uint256 public constant CREATOR_SHARE = 25;   // 2.5%
    uint256 public constant CHARITY_SHARE = 25;   // 2.5%
    
    // Ratio FT per ETH (es: 1 ETH = 1000 FT)
    uint256 public ftRatio = 1000;
    
    // ID NFT incrementale
    uint256 public nextTokenId = 1;
    
    // Rare NFT settings
    uint256 public rareNFTThreshold = 0.1 ether; // Minimum ETH for rare NFT
    mapping(uint256 => bool) public isRareNFT;
    mapping(address => uint256) public userRareNFTCount;

    // Photo categories for impact tracking
    mapping(string => bool) public validCategories;

    event PhotoMinted(
        address indexed user, 
        string tokenURI, 
        uint256 ethPaid, 
        uint256 nftId, 
        uint256 ftAmount,
        uint256 impactScore,
        bool isRare
    );
    
    event RareNFTMinted(
        address indexed user,
        uint256 indexed nftId,
        uint256 bonusImpact
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _nft,
        address _ft,
        address _creator,
        address _charity,
        address _impactTracker
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        
        oceanMangaNFT = IOceanMangaNFT(_nft);
        lunaComicsFT = ILunaComicsFT(_ft);
        impactTracker = IOceanMangaImpactTracker(_impactTracker);
        creator = _creator;
        charityFund = _charity;
        
        // Initialize valid photo categories
        validCategories["portrait"] = true;
        validCategories["landscape"] = true;
        validCategories["abstract"] = true;
        validCategories["wildlife"] = true;
        validCategories["street"] = true;
        validCategories["architecture"] = true;
        validCategories["macro"] = true;
        validCategories["sports"] = true;
        validCategories["other"] = true;
    }

    function mintPhotoCombo(
        string memory tokenURI, 
        string memory photoCategory
    ) external payable nonReentrant {
        require(msg.value > 0, "Payment required");
        require(validCategories[photoCategory], "Invalid photo category");

        uint256 total = msg.value;
        uint256 currentTokenId = nextTokenId++;
        
        // Determina se è un rare NFT
        bool isRare = msg.value >= rareNFTThreshold;
        if (isRare) {
            isRareNFT[currentTokenId] = true;
            userRareNFTCount[msg.sender]++;
        }
        
        // Calcola le quote
        uint256 ftAmount = (total * FT_SHARE) / 1000;
        uint256 creatorAmount = (total * CREATOR_SHARE) / 1000;
        uint256 charityAmount = (total * CHARITY_SHARE) / 1000;

        // 1. Mint NFT (ERC1155: id, amount, data)
        oceanMangaNFT.mint(msg.sender, currentTokenId, 1, abi.encode(tokenURI));

    // 2. Mint FT (calcola quantità basata su ETH ricevuto)
    uint256 ftTokensToMint = (ftAmount * ftRatio) / 1 ether;
    // Cosmix FT mint is non-payable; orchestrator mints tokens by calling mint()
    lunaComicsFT.mint(msg.sender, ftTokensToMint);

        // 3. Traccia impact sociale (NUOVO)
        uint256 impactScore = 0;
        if (address(impactTracker) != address(0)) {
            impactScore = impactTracker.logMintImpact(
                msg.sender,
                currentTokenId,
                charityAmount,
                ftTokensToMint,
                photoCategory,
                isRare
            );
        }

        // 4. Distribuisci pagamenti
        uint256 remaining = total - ftAmount - creatorAmount - charityAmount;
        if (remaining > 0) {
            // Il resto rimane nel contratto orchestratore
        }
        payable(creator).transfer(creatorAmount);
        payable(charityFund).transfer(charityAmount);

        emit PhotoMinted(
            msg.sender, 
            tokenURI, 
            total, 
            currentTokenId, 
            ftTokensToMint,
            impactScore,
            isRare
        );
        
        if (isRare) {
            emit RareNFTMinted(msg.sender, currentTokenId, impactScore > 500 ? impactScore - 500 : 0);
        }
    }
    
    /**
     * @dev Legacy function for backwards compatibility
     */
    function mintPhotoCombo(string memory tokenURI) external payable {
        // Call new function with default category
        this.mintPhotoCombo{value: msg.value}(tokenURI, "other");
    }
    
    // Implementazione delle interfacce
    function nftPlanetContract() external view override(ISolidaryOrchestratorReadable, ISolidaryOrchestratorReadableFT) returns (address) {
        return address(oceanMangaNFT);
    }
    
    function ftSatelliteContract() external view override(ISolidaryOrchestratorReadable, ISolidaryOrchestratorReadableFT) returns (address) {
        return address(lunaComicsFT);
    }

    // Impact and Rare NFT functions
    function getUserRareNFTCount(address user) external view returns (uint256) {
        return userRareNFTCount[user];
    }
    
    function checkIsRareNFT(uint256 tokenId) external view returns (bool) {
        return isRareNFT[tokenId];
    }
    
    function addPhotoCategory(string memory category) external onlyOwner {
        validCategories[category] = true;
    }
    
    function removePhotoCategory(string memory category) external onlyOwner {
        validCategories[category] = false;
    }

    // Admin functions
    function setImpactTracker(address _impactTracker) external onlyOwner {
        impactTracker = IOceanMangaImpactTracker(_impactTracker);
    }
    
    function setRareNFTThreshold(uint256 _threshold) external onlyOwner {
        rareNFTThreshold = _threshold;
    }

    function setFTRatio(uint256 _newRatio) external onlyOwner {
        ftRatio = _newRatio;
    }

    function setAddresses(
        address _creator,
        address _charity
    ) external onlyOwner {
        creator = _creator;
        charityFund = _charity;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    // Emergency functions
    function emergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    function pause() external onlyOwner {
        // Could implement pausable functionality if needed
    }
}