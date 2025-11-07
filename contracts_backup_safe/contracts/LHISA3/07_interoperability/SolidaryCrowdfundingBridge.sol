// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca Lawyer - ITALY Florence
// Canto Finale - Ponte del Crowdfunding Universale - Divina Commedia della Solidarietà Blockchain

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

/**
 * @title SolidaryCrowdfundingBridge
 * @dev Canto Finale della Divina Commedia Blockchain - Unisce tutti i meccanismi di crowdfunding
 * @notice Bridge universale per BigBrother (BBTM), MILAN (AC Milan Voting), e ecosistema Solidary
 */
contract SolidaryCrowdfundingBridge is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎭 ROLES & CONSTANTS - I CUSTODI DEL CANTO
    // ═══════════════════════════════════════════════════════════════════════════════
    
    bytes32 public constant CAMPAIGN_CREATOR = keccak256("CAMPAIGN_CREATOR");
    bytes32 public constant BRIDGE_OPERATOR = keccak256("BRIDGE_OPERATOR");
    bytes32 public constant FUND_VALIDATOR = keccak256("FUND_VALIDATOR");
    bytes32 public constant IMPACT_ORACLE = keccak256("IMPACT_ORACLE");
    bytes32 public constant CULTURAL_CURATOR = keccak256("CULTURAL_CURATOR");
    
    uint256 public constant MAX_CAMPAIGN_DURATION = 365 days; // 1 anno massimo
    uint256 public constant MIN_FUNDING_GOAL = 1e18; // 1 SLDY minimum
    uint256 public constant PLATFORM_FEE_BASIS_POINTS = 250; // 2.5% platform fee
    uint256 public constant CREATOR_ROYALTY_BASIS_POINTS = 500; // 5% creator royalty
    uint256 public constant MAX_REWARD_TIERS = 10; // Massimo 10 tier di ricompense
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌟 STRUTTURE DIVINE DEL CROWDFUNDING
    // ═══════════════════════════════════════════════════════════════════════════════
    
    enum CampaignType {
        CULTURAL_NFT,       // Campagne BigBrother BBTM NFT
        SPORTS_VOTING,      // Campagne MILAN voting
        SOCIAL_IMPACT,      // Progetti impatto sociale Solidary
        CREATIVE_PROJECT,   // Progetti creativi generici
        CHARITY_FUND,       // Fondi di beneficenza
        TECH_INNOVATION,    // Innovazioni tecnologiche
        ENVIRONMENTAL,      // Progetti ambientali
        EDUCATIONAL,        // Progetti educativi
        HEALTH_WELLNESS,    // Benessere e salute
        CULTURAL_HERITAGE   // Patrimonio culturale
    }
    
    enum CampaignStatus {
        DRAFT,              // In preparazione
        ACTIVE,             // Attiva per finanziamenti
        FUNDED,             // Obiettivo raggiunto
        COMPLETED,          // Completata con successo
        CANCELLED,          // Cancellata
        FAILED,             // Fallita (timeout senza funding)
        REFUNDING           // In rimborso
    }
    
    struct CrowdfundingCampaign {
        uint256 campaignId;
        address creator;
        CampaignType campaignType;
        CampaignStatus status;
        
        // Campaign Details
        string title;
        string description;
        string imageURI;
        string[] tags;
        
        // Funding Parameters
        uint256 fundingGoal;        // Obiettivo in SLDY
        uint256 currentFunding;     // Finanziamento attuale
        uint256 startTime;
        uint256 endTime;
        uint256 minContribution;    // Contributo minimo
        
        // Reward System
        mapping(uint256 => RewardTier) rewardTiers;
        uint256 rewardTierCount;
        
        // Backers
        address[] backers;
        mapping(address => uint256) contributions;
        mapping(address => bool) hasVoted;
        
        // Integration References
        address bbtmContract;       // Contratto BigBrother se applicabile
        address milanContract;      // Contratto MILAN se applicabile
        address nftContract;        // Contratto NFT per ricompense
        uint256[] nftTokenIds;      // Token IDs per ricompense NFT
        
        // Impact Measurement
        uint256 socialImpactScore;
        uint256 culturalValue;
        bool isVerified;
        bool hasDelivered;
    }
    
    struct RewardTier {
        uint256 tierId;
        uint256 minimumContribution;
        uint256 maxBackers;         // Limite backers per questo tier
        uint256 currentBackers;
        string description;
        RewardType rewardType;
        
        // Reward Details
        address tokenContract;      // Contratto token/NFT reward
        uint256[] tokenIds;         // Token IDs specifici
        uint256 tokenAmount;        // Quantità token fungibili
        string physicalReward;      // Descrizione ricompense fisiche
        bool isLimitedEdition;
        bool isDelivered;
    }
    
    enum RewardType {
        NFT_EXCLUSIVE,          // NFT esclusivi BBTM
        VOTING_RIGHTS,          // Diritti voto MILAN
        SLDY_TOKENS,           // Token SLDY
        PHYSICAL_ITEM,         // Oggetti fisici
        EXPERIENCE,            // Esperienze uniche
        EARLY_ACCESS,          // Accesso anticipato
        CREATOR_MEETING,       // Incontro con creator
        LIMITED_EDITION,       // Edizioni limitate
        GOVERNANCE_POWER,      // Potere di governance
        CULTURAL_ACCESS        // Accesso contenuti culturali
    }
    
    struct BackerProfile {
        address backerAddress;
        uint256 totalContributed;
        uint256 campaignsSupported;
        uint256[] supportedCampaigns;
        mapping(uint256 => uint256) campaignContributions;
        uint256 reputationScore;
        bool isVerified;
        BackerTier tier;
    }
    
    struct BackerProfileView {
        address backerAddress;
        uint256 totalContributed;
        uint256 campaignsSupported;
        uint256[] supportedCampaigns;
        uint256 reputationScore;
        bool isVerified;
        BackerTier tier;
    }
    
    enum BackerTier {
        NEWCOMER,       // 0-100 SLDY contributed
        SUPPORTER,      // 101-1000 SLDY
        ADVOCATE,       // 1001-10000 SLDY  
        CHAMPION,       // 10001-100000 SLDY
        GUARDIAN,       // 100001+ SLDY
        LEGEND          // Special status
    }
    
    struct CreatorProfile {
        address creatorAddress;
        uint256 campaignsCreated;
        uint256 totalRaised;
        uint256 successfulCampaigns;
        uint256 creatorReputation;
        bool isVerified;
        bool isKYCVerified;
        string creatorBio;
        string[] specialties;        // Areas of expertise
        uint256 averageDeliveryTime;
        CreatorTier tier;
    }
    
    enum CreatorTier {
        ROOKIE,         // First campaign
        EXPERIENCED,    // 2-5 successful campaigns
        VETERAN,        // 6-20 successful campaigns  
        MASTER,         // 21+ successful campaigns
        LEGENDARY       // Special recognition
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 💾 STATE VARIABLES - LA MEMORIA DEL CANTO
    // ═══════════════════════════════════════════════════════════════════════════════
    
    mapping(uint256 => CrowdfundingCampaign) public campaigns;
    mapping(address => BackerProfile) public backers;
    mapping(address => CreatorProfile) public creators;
    mapping(CampaignType => uint256[]) public campaignsByType;
    mapping(bytes32 => bool) public processedBridgeTxs;
    
    uint256 public currentCampaignId;
    uint256 public totalCampaigns;
    uint256 public totalFundingRaised;
    uint256 public totalBackersCount;
    uint256 public totalCreatorsCount;
    uint256 public successfulCampaigns;
    
    // Contract References - Gli Alleati del Canto
    IERC20Upgradeable public solidaryToken;
    address public bbtmMainContract;
    address public milanContract;
    address public impactFund;
    address public culturalMint;
    address public reputationManager;
    address public trustManager;
    address public creatorWallet;
    
    // System Configuration
    bool public bridgeActive;
    bool public campaignCreationEnabled;
    uint256 public platformFeePercentage;
    uint256 public creatorRoyaltyPercentage;
    
    // Events - Le Voci del Canto
    event CampaignCreated(uint256 indexed campaignId, address indexed creator, CampaignType campaignType, string title);
    event CampaignFunded(uint256 indexed campaignId, address indexed backer, uint256 amount);
    event CampaignCompleted(uint256 indexed campaignId, uint256 totalRaised, bool successful);
    event RewardDistributed(uint256 indexed campaignId, address indexed backer, uint256 tierId, RewardType rewardType);
    event BBTMIntegration(uint256 indexed campaignId, address indexed bbtmContract, uint256[] nftIds);
    event MILANIntegration(uint256 indexed campaignId, address indexed milanContract, uint256 votingPower);
    event CreatorVerified(address indexed creator, CreatorTier tier);
    event BackerTierUpdated(address indexed backer, BackerTier oldTier, BackerTier newTier);
    event CrossChainBridge(bytes32 indexed txHash, uint256 campaignId, uint256 amount, string targetChain);
    event ImpactMeasured(uint256 indexed campaignId, uint256 socialScore, uint256 culturalValue);
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏗️ INITIALIZATION - LA GENESI DEL CANTO
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        address admin,
        address _solidaryToken,
        address _bbtmMainContract,
        address _milanMainContract,
        address _impactFund,
        address _culturalMint,
        address _reputationManager,
        address _trustManager,
        address _creatorWallet
    ) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CAMPAIGN_CREATOR, admin);
        _grantRole(BRIDGE_OPERATOR, admin);
        _grantRole(FUND_VALIDATOR, admin);
        _grantRole(IMPACT_ORACLE, admin);
        _grantRole(CULTURAL_CURATOR, admin);
        
        solidaryToken = IERC20Upgradeable(_solidaryToken);
        bbtmMainContract = _bbtmMainContract;
        milanContract = _milanMainContract;
        impactFund = _impactFund;
        culturalMint = _culturalMint;
        reputationManager = _reputationManager;
        trustManager = _trustManager;
        creatorWallet = _creatorWallet;
        
        currentCampaignId = 1;
        bridgeActive = true;
        campaignCreationEnabled = true;
        platformFeePercentage = PLATFORM_FEE_BASIS_POINTS;
        creatorRoyaltyPercentage = CREATOR_ROYALTY_BASIS_POINTS;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎬 CAMPAIGN CREATION - LA CREAZIONE DEI SOGNI
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Crea una nuova campagna di crowdfunding universale
     * @param campaignType Tipo di campagna (BBTM, MILAN, Solidary)
     * @param title Titolo della campagna
     * @param description Descrizione dettagliata
     * @param fundingGoal Obiettivo di finanziamento in SLDY
     * @param duration Durata in secondi
     * @param minContribution Contributo minimo
     * @param imageURI URI immagine campagna
     * @param tags Array di tag per categorizzazione
     */
    function createCampaign(
        CampaignType campaignType,
        string memory title,
        string memory description,
        uint256 fundingGoal,
        uint256 duration,
        uint256 minContribution,
        string memory imageURI,
        string[] memory tags
    ) external nonReentrant returns (uint256) {
        require(campaignCreationEnabled, "Campaign creation disabled");
        require(bytes(title).length > 0, "Title required");
        require(bytes(description).length > 0, "Description required");
        require(fundingGoal >= MIN_FUNDING_GOAL, "Funding goal too low");
        require(duration <= MAX_CAMPAIGN_DURATION, "Duration too long");
        require(duration >= 7 days, "Duration too short");
        
        uint256 campaignId = currentCampaignId++;
        
        CrowdfundingCampaign storage campaign = campaigns[campaignId];
        campaign.campaignId = campaignId;
        campaign.creator = msg.sender;
        campaign.campaignType = campaignType;
        campaign.status = CampaignStatus.DRAFT;
        campaign.title = title;
        campaign.description = description;
        campaign.imageURI = imageURI;
        campaign.tags = tags;
        campaign.fundingGoal = fundingGoal;
        campaign.startTime = block.timestamp;
        campaign.endTime = block.timestamp + duration;
        campaign.minContribution = minContribution;
        
        // Initialize creator profile if first campaign
        CreatorProfile storage creator = creators[msg.sender];
        if (creator.creatorAddress == address(0)) {
            creator.creatorAddress = msg.sender;
            creator.tier = CreatorTier.ROOKIE;
            totalCreatorsCount++;
        }
        creator.campaignsCreated++;
        
        // Add to category index
        campaignsByType[campaignType].push(campaignId);
        totalCampaigns++;
        
        emit CampaignCreated(campaignId, msg.sender, campaignType, title);
        return campaignId;
    }
    
    /**
     * @dev Aggiunge reward tier a una campagna
     * @param campaignId ID campagna
     * @param minimumContribution Contributo minimo per tier
     * @param maxBackers Numero massimo backers
     * @param description Descrizione reward
     * @param rewardType Tipo di ricompensa
     */
    function addRewardTier(
        uint256 campaignId,
        uint256 minimumContribution,
        uint256 maxBackers,
        string memory description,
        RewardType rewardType
    ) external nonReentrant {
        CrowdfundingCampaign storage campaign = campaigns[campaignId];
        require(campaign.creator == msg.sender, "Not campaign creator");
        require(campaign.status == CampaignStatus.DRAFT, "Campaign already active");
        require(campaign.rewardTierCount < MAX_REWARD_TIERS, "Too many reward tiers");
        
        uint256 tierId = campaign.rewardTierCount++;
        RewardTier storage tier = campaign.rewardTiers[tierId];
        tier.tierId = tierId;
        tier.minimumContribution = minimumContribution;
        tier.maxBackers = maxBackers;
        tier.description = description;
        tier.rewardType = rewardType;
    }
    
    /**
     * @dev Attiva una campagna per il finanziamento
     * @param campaignId ID campagna da attivare
     */
    function launchCampaign(uint256 campaignId) external nonReentrant {
        CrowdfundingCampaign storage campaign = campaigns[campaignId];
        require(campaign.creator == msg.sender || hasRole(FUND_VALIDATOR, msg.sender), "Not authorized");
        require(campaign.status == CampaignStatus.DRAFT, "Campaign not in draft");
        require(campaign.rewardTierCount > 0, "No reward tiers defined");
        
        campaign.status = CampaignStatus.ACTIVE;
        campaign.startTime = block.timestamp;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 💰 FUNDING & BACKING - IL SOSTEGNO DEI CREDENTI
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Finanzia una campagna con SLDY tokens
     * @param campaignId ID campagna
     * @param amount Importo in SLDY
     * @param selectedTier ID tier ricompensa (opzionale)
     */
    function fundCampaign(
        uint256 campaignId, 
        uint256 amount,
        uint256 selectedTier
    ) external nonReentrant {
        CrowdfundingCampaign storage campaign = campaigns[campaignId];
        require(campaign.status == CampaignStatus.ACTIVE, "Campaign not active");
        require(block.timestamp <= campaign.endTime, "Campaign ended");
        require(amount >= campaign.minContribution, "Below minimum contribution");
        
        // Validate reward tier
        if (selectedTier < campaign.rewardTierCount) {
            RewardTier storage tier = campaign.rewardTiers[selectedTier];
            require(amount >= tier.minimumContribution, "Below tier minimum");
            require(tier.currentBackers < tier.maxBackers, "Tier full");
            tier.currentBackers++;
        }
        
        // Transfer SLDY tokens
        require(solidaryToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        // Update campaign funding
        campaign.currentFunding += amount;
        
        // Initialize or update backer
        if (campaign.contributions[msg.sender] == 0) {
            campaign.backers.push(msg.sender);
        }
        campaign.contributions[msg.sender] += amount;
        
        // Update backer profile
        BackerProfile storage backer = backers[msg.sender];
        if (backer.backerAddress == address(0)) {
            backer.backerAddress = msg.sender;
            backer.tier = BackerTier.NEWCOMER;
            totalBackersCount++;
        }
        backer.totalContributed += amount;
        backer.campaignsSupported++;
        backer.supportedCampaigns.push(campaignId);
        backer.campaignContributions[campaignId] += amount;
        
        // Update backer tier
        _updateBackerTier(msg.sender);
        
        // Distribute platform fee and creator royalty
        _distributeFees(amount);
        
        // Check if campaign is funded
        if (campaign.currentFunding >= campaign.fundingGoal) {
            campaign.status = CampaignStatus.FUNDED;
        }
        
        emit CampaignFunded(campaignId, msg.sender, amount);
    }
    
    /**
     * @dev Integra campagna con contratto BigBrother BBTM
     * @param campaignId ID campagna
     * @param bbtmContract Indirizzo contratto BBTM
     * @param nftTokenIds Array token IDs per rewards
     */
    function integrateBBTM(
        uint256 campaignId,
        address bbtmContract,
        uint256[] memory nftTokenIds
    ) external onlyRole(BRIDGE_OPERATOR) {
        CrowdfundingCampaign storage campaign = campaigns[campaignId];
        require(campaign.campaignType == CampaignType.CULTURAL_NFT, "Not BBTM campaign");
        
        campaign.bbtmContract = bbtmContract;
        campaign.nftTokenIds = nftTokenIds;
        
        emit BBTMIntegration(campaignId, bbtmContract, nftTokenIds);
    }
    
    /**
     * @dev Integra campagna con contratto MILAN voting
     * @param campaignId ID campagna  
     * @param milanContract Indirizzo contratto MILAN
     * @param votingPower Potere di voto assegnato
     */
    function integrateMILAN(
        uint256 campaignId,
        address milanContract,
        uint256 votingPower
    ) external onlyRole(BRIDGE_OPERATOR) {
        CrowdfundingCampaign storage campaign = campaigns[campaignId];
        require(campaign.campaignType == CampaignType.SPORTS_VOTING, "Not MILAN campaign");
        
        campaign.milanContract = milanContract;
        
        emit MILANIntegration(campaignId, milanContract, votingPower);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎁 REWARD DISTRIBUTION - LA DISTRIBUZIONE DEI DONI
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Distribuisce ricompense ai backers di una campagna completata
     * @param campaignId ID campagna
     */
    function distributeRewards(uint256 campaignId) external nonReentrant {
        CrowdfundingCampaign storage campaign = campaigns[campaignId];
        require(campaign.creator == msg.sender || hasRole(FUND_VALIDATOR, msg.sender), "Not authorized");
        require(campaign.status == CampaignStatus.FUNDED, "Campaign not funded");
        
        // Distribute rewards based on tiers
        for (uint256 i = 0; i < campaign.backers.length; i++) {
            address backer = campaign.backers[i];
            uint256 contribution = campaign.contributions[backer];
            
            // Find appropriate reward tier
            uint256 eligibleTier = _findEligibleTier(campaignId, contribution);
            if (eligibleTier < campaign.rewardTierCount) {
                _distributeRewardToUser(campaignId, backer, eligibleTier);
            }
        }
        
        campaign.status = CampaignStatus.COMPLETED;
        campaign.hasDelivered = true;
        
        // Update creator stats
        CreatorProfile storage creator = creators[campaign.creator];
        creator.successfulCampaigns++;
        creator.totalRaised += campaign.currentFunding;
        _updateCreatorTier(campaign.creator);
        
        successfulCampaigns++;
        
        emit CampaignCompleted(campaignId, campaign.currentFunding, true);
    }
    
    function _distributeRewardToUser(uint256 campaignId, address backer, uint256 tierId) internal {
        CrowdfundingCampaign storage campaign = campaigns[campaignId];
        RewardTier storage tier = campaign.rewardTiers[tierId];
        
        if (tier.rewardType == RewardType.NFT_EXCLUSIVE && campaign.bbtmContract != address(0)) {
            // Mint BBTM NFT reward
            _mintBBTMReward(backer, campaign.bbtmContract, tierId);
        } else if (tier.rewardType == RewardType.VOTING_RIGHTS && campaign.milanContract != address(0)) {
            // Grant MILAN voting rights
            _grantMILANVoting(backer, campaign.milanContract, tierId);
        } else if (tier.rewardType == RewardType.SLDY_TOKENS) {
            // Transfer SLDY tokens
            solidaryToken.transfer(backer, tier.tokenAmount);
        }
        
        emit RewardDistributed(campaignId, backer, tierId, tier.rewardType);
    }
    
    function _mintBBTMReward(address backer, address bbtmContract, uint256 tierId) internal {
        // Integration with BigBrother contract for NFT minting
        (bool success, ) = bbtmContract.call(
            abi.encodeWithSignature(
                "mintRewardNFT(address,uint256)",
                backer,
                tierId
            )
        );
    }
    
    function _grantMILANVoting(address backer, address milanContractAddr, uint256 tierId) internal {
        // Integration with MILAN contract for voting rights
        (bool success, ) = milanContractAddr.call(
            abi.encodeWithSignature(
                "grantVotingRights(address,uint256)",
                backer,
                tierId + 1 // Voting power based on tier
            )
        );
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔧 INTERNAL UTILITY FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function _distributeFees(uint256 amount) internal {
        uint256 platformFee = (amount * platformFeePercentage) / 10000;
        uint256 creatorRoyalty = (amount * creatorRoyaltyPercentage) / 10000;
        
        if (creatorWallet != address(0) && creatorRoyalty > 0) {
            solidaryToken.transfer(creatorWallet, creatorRoyalty);
        }
    }
    
    function _updateBackerTier(address backerAddress) internal {
        BackerProfile storage backer = backers[backerAddress];
        BackerTier oldTier = backer.tier;
        BackerTier newTier = _calculateBackerTier(backer.totalContributed);
        
        if (newTier != oldTier) {
            backer.tier = newTier;
            emit BackerTierUpdated(backerAddress, oldTier, newTier);
        }
    }
    
    function _calculateBackerTier(uint256 totalContributed) internal pure returns (BackerTier) {
        if (totalContributed <= 100e18) return BackerTier.NEWCOMER;
        else if (totalContributed <= 1000e18) return BackerTier.SUPPORTER;
        else if (totalContributed <= 10000e18) return BackerTier.ADVOCATE;
        else if (totalContributed <= 100000e18) return BackerTier.CHAMPION;
        else return BackerTier.GUARDIAN;
    }
    
    function _updateCreatorTier(address creatorAddress) internal {
        CreatorProfile storage creator = creators[creatorAddress];
        CreatorTier newTier = _calculateCreatorTier(creator.successfulCampaigns);
        
        if (newTier != creator.tier) {
            creator.tier = newTier;
            emit CreatorVerified(creatorAddress, newTier);
        }
    }
    
    function _calculateCreatorTier(uint256 successfulCampaignCount) internal pure returns (CreatorTier) {
        if (successfulCampaignCount == 1) return CreatorTier.ROOKIE;
        else if (successfulCampaignCount <= 5) return CreatorTier.EXPERIENCED;
        else if (successfulCampaignCount <= 20) return CreatorTier.VETERAN;
        else return CreatorTier.MASTER;
    }
    
    function _findEligibleTier(uint256 campaignId, uint256 contribution) internal view returns (uint256) {
        CrowdfundingCampaign storage campaign = campaigns[campaignId];
        uint256 bestTier = campaign.rewardTierCount; // Invalid tier by default
        uint256 highestEligible = 0;
        
        for (uint256 i = 0; i < campaign.rewardTierCount; i++) {
            RewardTier storage tier = campaign.rewardTiers[i];
            if (contribution >= tier.minimumContribution && tier.minimumContribution >= highestEligible) {
                bestTier = i;
                highestEligible = tier.minimumContribution;
            }
        }
        
        return bestTier;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 👁️ VIEW FUNCTIONS - GLI OCCHI DEL CANTO
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function getCampaign(uint256 campaignId) external view returns (
        address creator,
        CampaignType campaignType,
        CampaignStatus status,
        string memory title,
        string memory description,
        uint256 fundingGoal,
        uint256 currentFunding,
        uint256 startTime,
        uint256 endTime,
        uint256 backersCount
    ) {
        CrowdfundingCampaign storage campaign = campaigns[campaignId];
        return (
            campaign.creator,
            campaign.campaignType,
            campaign.status,
            campaign.title,
            campaign.description,
            campaign.fundingGoal,
            campaign.currentFunding,
            campaign.startTime,
            campaign.endTime,
            campaign.backers.length
        );
    }
    
    function getBackerProfile(address backerAddress) external view returns (BackerProfileView memory) {
        BackerProfile storage backer = backers[backerAddress];
        return BackerProfileView({
            backerAddress: backer.backerAddress,
            totalContributed: backer.totalContributed,
            campaignsSupported: backer.campaignsSupported,
            supportedCampaigns: backer.supportedCampaigns,
            reputationScore: backer.reputationScore,
            isVerified: backer.isVerified,
            tier: backer.tier
        });
    }
    
    function getCreatorProfile(address creatorAddress) external view returns (CreatorProfile memory) {
        return creators[creatorAddress];
    }
    
    function getCampaignsByType(CampaignType campaignType) external view returns (uint256[] memory) {
        return campaignsByType[campaignType];
    }
    
    function getSystemStats() external view returns (
        uint256 campaignCount,
        uint256 totalFunding,
        uint256 totalBackers,
        uint256 totalCreators,
        uint256 successRatePercent
    ) {
        uint256 successRatePercent = totalCampaigns > 0 ? (successfulCampaigns * 10000) / totalCampaigns : 0;
        return (totalCampaigns, totalFundingRaised, totalBackersCount, totalCreatorsCount, successRatePercent);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // ⚙️ ADMIN FUNCTIONS - I GOVERNATORI DEL CANTO
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function setSystemStatus(bool _bridgeActive, bool _campaignCreationEnabled) 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        bridgeActive = _bridgeActive;
        campaignCreationEnabled = _campaignCreationEnabled;
    }
    
    function setFeePercentages(uint256 _platformFee, uint256 _creatorRoyalty) 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        require(_platformFee <= 1000, "Platform fee too high"); // Max 10%
        require(_creatorRoyalty <= 1000, "Creator royalty too high"); // Max 10%
        
        platformFeePercentage = _platformFee;
        creatorRoyaltyPercentage = _creatorRoyalty;
    }
    
    function updateContractReferences(
        address _solidaryToken,
        address _bbtmMainContract,
        address _milanContract,
        address _impactFund,
        address _culturalMint,
        address _reputationManager,
        address _trustManager,
        address _creatorWallet
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_solidaryToken != address(0)) solidaryToken = IERC20Upgradeable(_solidaryToken);
        if (_bbtmMainContract != address(0)) bbtmMainContract = _bbtmMainContract;
        if (_milanContract != address(0)) milanContract = _milanContract;
        if (_impactFund != address(0)) impactFund = _impactFund;
        if (_culturalMint != address(0)) culturalMint = _culturalMint;
        if (_reputationManager != address(0)) reputationManager = _reputationManager;
        if (_trustManager != address(0)) trustManager = _trustManager;
        if (_creatorWallet != address(0)) creatorWallet = _creatorWallet;
    }
    
    /**
     * @dev Emergency function per rimborsi in caso di problemi
     * @param campaignId ID campagna
     */
    function emergencyRefund(uint256 campaignId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        CrowdfundingCampaign storage campaign = campaigns[campaignId];
        require(campaign.status == CampaignStatus.ACTIVE || campaign.status == CampaignStatus.FUNDED, "Invalid status");
        
        campaign.status = CampaignStatus.REFUNDING;
        
        // Refund all backers
        for (uint256 i = 0; i < campaign.backers.length; i++) {
            address backer = campaign.backers[i];
            uint256 contribution = campaign.contributions[backer];
            if (contribution > 0) {
                solidaryToken.transfer(backer, contribution);
                campaign.contributions[backer] = 0;
            }
        }
        
        campaign.currentFunding = 0;
        campaign.status = CampaignStatus.CANCELLED;
    }
}