// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title OceanMangaImpactTracker
 * @dev Simplified impact tracker for OceanManga ecosystem charity donations
 */
contract OceanMangaImpactTracker is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    
    struct ImpactEvent {
        uint256 timestamp;
        address minter;
        uint256 charityAmount;    // Amount donated to charity
        uint256 ftTokensMinted;   // FT tokens generated
        uint256 nftId;           // NFT token ID
        string photoCategory;     // "portrait", "landscape", "abstract", etc.
        uint256 impactScore;     // Calculated impact (1-1000)
        string impactCID;        // IPFS link to detailed impact data
        bool isVerified;
    }
    
    struct UserImpactStats {
        uint256 totalDonated;
        uint256 totalImpactScore;
        uint256 nftsMinted;
        uint256 lastMintDate;
    }
    
    struct GlobalImpactStats {
        uint256 totalEvents;
        uint256 totalCharityAmount;
        uint256 totalBeneficiaries;
        uint256 averageImpactScore;
        address topImpactUser;
        uint256 topImpactScore;
    }
    
    // State variables
    mapping(address => ImpactEvent[]) public userImpactHistory;
    mapping(address => UserImpactStats) public userStats;
    mapping(uint256 => ImpactEvent) public nftImpactData; // NFT ID -> Impact Data
    
    GlobalImpactStats public globalStats;
    address public caritasWallet;
    address public orchestrator;
    
    // Constants for impact calculation
    uint256 public constant BASE_IMPACT_MULTIPLIER = 100;
    uint256 public constant RARE_NFT_BONUS = 500; // Extra impact for rare NFTs
    
    event ImpactLogged(
        address indexed minter,
        uint256 indexed nftId,
        uint256 charityAmount,
        uint256 impactScore,
        string category
    );
    
    event ImpactVerified(
        address indexed minter,
        uint256 indexed nftId,
        address verifier,
        string impactCID
    );
    
    event TopImpactUserUpdated(address indexed newTopUser, uint256 impactScore);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        address _caritasWallet,
        address _orchestrator
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        
        caritasWallet = _caritasWallet;
        orchestrator = _orchestrator;
    }
    
    /**
     * @dev Log impact when NFT is minted (called by orchestrator)
     */
    function logMintImpact(
        address minter,
        uint256 nftId,
        uint256 charityAmount,
        uint256 ftTokensMinted,
        string memory photoCategory,
        bool isRareNFT
    ) external returns (uint256 impactScore) {
        require(msg.sender == orchestrator, "Only orchestrator can log impact");
        
        // Calculate impact score
        impactScore = _calculateImpactScore(charityAmount, ftTokensMinted, isRareNFT);
        
        // Create impact event
        ImpactEvent memory newEvent = ImpactEvent({
            timestamp: block.timestamp,
            minter: minter,
            charityAmount: charityAmount,
            ftTokensMinted: ftTokensMinted,
            nftId: nftId,
            photoCategory: photoCategory,
            impactScore: impactScore,
            impactCID: "",
            isVerified: false
        });
        
        // Store impact data
        userImpactHistory[minter].push(newEvent);
        nftImpactData[nftId] = newEvent;
        
        // Update user stats
        _updateUserStats(minter, charityAmount, impactScore);
        
        // Update global stats
        _updateGlobalStats(charityAmount, impactScore, minter);
        
        emit ImpactLogged(minter, nftId, charityAmount, impactScore, photoCategory);
        
        return impactScore;
    }
    
    /**
     * @dev Calculate impact score based on donation amount and other factors
     */
    function _calculateImpactScore(
        uint256 charityAmount,
        uint256 ftTokensMinted,
        bool isRareNFT
    ) internal pure returns (uint256) {
        uint256 baseScore = charityAmount * BASE_IMPACT_MULTIPLIER / 1e18;
        uint256 ftBonus = ftTokensMinted / 100; // 1 point per 100 FT tokens
        uint256 rareBonus = isRareNFT ? RARE_NFT_BONUS : 0;
        
        uint256 totalScore = baseScore + ftBonus + rareBonus;
        return totalScore > 1000 ? 1000 : totalScore; // Cap at 1000
    }
    
    function _updateUserStats(
        address user,
        uint256 charityAmount,
        uint256 impactScore
    ) internal {
        UserImpactStats storage stats = userStats[user];
        stats.totalDonated += charityAmount;
        stats.totalImpactScore += impactScore;
        stats.nftsMinted += 1;
        stats.lastMintDate = block.timestamp;
    }
    
    function _updateGlobalStats(
        uint256 charityAmount,
        uint256 impactScore,
        address minter
    ) internal {
        globalStats.totalEvents += 1;
        globalStats.totalCharityAmount += charityAmount;
        globalStats.totalBeneficiaries += _estimateBeneficiaries(charityAmount);
        
        // Update average impact score
        globalStats.averageImpactScore = 
            (globalStats.averageImpactScore * (globalStats.totalEvents - 1) + impactScore) / 
            globalStats.totalEvents;
        
        // Check if new top impact user
        if (userStats[minter].totalImpactScore > globalStats.topImpactScore) {
            globalStats.topImpactUser = minter;
            globalStats.topImpactScore = userStats[minter].totalImpactScore;
            emit TopImpactUserUpdated(minter, globalStats.topImpactScore);
        }
    }
    
    function _estimateBeneficiaries(uint256 charityAmount) internal pure returns (uint256) {
        // Estimate: 1 beneficiary per $10 donated (assuming 1 ETH = $2500)
        // charityAmount is in wei, so we divide by 4e15 (0.004 ETH = $10)
        return charityAmount / 4e15;
    }
    
    /**
     * @dev Verify impact event with IPFS documentation
     */
    function verifyImpact(
        address user,
        uint256 nftId,
        string memory impactCID
    ) external onlyOwner {
        require(nftImpactData[nftId].minter == user, "Invalid NFT/user combination");
        require(!nftImpactData[nftId].isVerified, "Already verified");
        
        nftImpactData[nftId].isVerified = true;
        nftImpactData[nftId].impactCID = impactCID;
        
        // Also update in user history
        ImpactEvent[] storage userEvents = userImpactHistory[user];
        for (uint256 i = 0; i < userEvents.length; i++) {
            if (userEvents[i].nftId == nftId) {
                userEvents[i].isVerified = true;
                userEvents[i].impactCID = impactCID;
                break;
            }
        }
        
        emit ImpactVerified(user, nftId, msg.sender, impactCID);
    }
    
    // View functions
    function getUserImpactHistory(address user) external view returns (ImpactEvent[] memory) {
        return userImpactHistory[user];
    }
    
    function getUserStats(address user) external view returns (UserImpactStats memory) {
        return userStats[user];
    }
    
    function getNFTImpactData(uint256 nftId) external view returns (ImpactEvent memory) {
        return nftImpactData[nftId];
    }
    
    function getGlobalStats() external view returns (GlobalImpactStats memory) {
        return globalStats;
    }
    
    function getTotalImpactByCategory(string memory category) external view returns (uint256 totalImpact, uint256 eventCount) {
        // Simplified implementation - in production would use more efficient storage
        for (uint256 i = 0; i < globalStats.totalEvents; i++) {
            // This is a simplified approach - in reality you'd need a more efficient way
            // to track category-specific data
        }
        return (0, 0); // Placeholder
    }
    
    // Admin functions
    function setOrchestrator(address _orchestrator) external onlyOwner {
        orchestrator = _orchestrator;
    }
    
    function setCaritasWallet(address _caritasWallet) external onlyOwner {
        caritasWallet = _caritasWallet;
    }
}