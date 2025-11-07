// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title SolidaryMusicalFunding (SOLMUS)
 * @author Avv. Marcello Stanca - Solidary Network Architect
 * @notice Crowdfunding token per "Big Brother The Musical" - La nota dominante della solidarietà
 * @dev ERC20 + UUPS Upgradeable per finanziamento produzione musical solidale
 * 
 * 🎵 SOLMUS: Quadruplo significato evocativo:
 * - SOLidary: Brand dell'ecosistema blockchain umanitario
 * - SOLidity: Tecnologia smart contract utilizzata
 * - SOL: Quinta nota musicale (dominante armonica in teoria musicale)
 * - MUSical: Progetto teatrale che finanziamo
 * 
 * 🎭 MUSICAL THEORY EASTER EGG:
 * In teoria musicale, SOL (G) è la dominante che crea tensione verso la risoluzione.
 * SOLMUS (crowdfunding) crea tensione/aspettativa → SOLDOUT (successo) risolve l'armonia!
 */
contract SolidaryMusicalFunding is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📋 CROWDFUNDING PARAMETERS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @notice Obiettivo di finanziamento in EUR (convertito in wei)
    uint256 public fundingGoal;
    
    /// @notice Deadline del crowdfunding (timestamp)
    uint256 public fundingDeadline;
    
    /// @notice Totale raccolto finora
    uint256 public totalRaised;
    
    /// @notice Minimo contributo richiesto
    uint256 public minimumContribution;
    
    /// @notice Stato del crowdfunding
    enum FundingState { ACTIVE, GOAL_REACHED, ENDED, REFUNDING }
    FundingState public currentState;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 💰 CONTRIBUTOR MANAGEMENT
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @notice Mapping dei contributi per ogni indirizzo
    mapping(address => uint256) public contributions;
    
    /// @notice Array di tutti i contributors
    address[] public contributors;
    
    /// @notice Check se un indirizzo ha già contribuito
    mapping(address => bool) public hasContributed;
    
    /// @notice Reward NFT address (SolidarySoldOut collection)
    address public rewardNFTContract;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎭 MUSICAL REWARDS TIERS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @notice Tier dei premi basati sul contributo
    struct RewardTier {
        uint256 minAmount;      // Minimo contributo per tier
        string tierName;        // Nome del tier
        string benefits;        // Benefici del tier
        uint256 nftBonus;       // Bonus NFT per il tier
    }
    
    RewardTier[] public rewardTiers;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎪 EVENTS - La sinfonia degli eventi
    // ═══════════════════════════════════════════════════════════════════════════════
    
    event FundingContribution(
        address indexed contributor, 
        uint256 amount, 
        uint256 totalContribution,
        string tierAchieved
    );
    
    event FundingGoalReached(uint256 totalRaised, uint256 totalContributors);
    event FundingEnded(bool successful, uint256 finalAmount);
    event RefundProcessed(address indexed contributor, uint256 amount);
    event RewardTierAdded(uint256 tierIndex, string tierName, uint256 minAmount);
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎵 INITIALIZATION - L'accordatura iniziale
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    /**
     * @notice Inizializza il contratto di crowdfunding musical
     * @param _fundingGoalEUR Obiettivo in EUR (sarà convertito in wei)
     * @param _durationDays Durata della campagna in giorni
     * @param _minimumContributionEUR Contributo minimo in EUR
     * @param initialOwner Owner del contratto
     */
    function initialize(
        uint256 _fundingGoalEUR,
        uint256 _durationDays,
        uint256 _minimumContributionEUR,
        address initialOwner
    ) public initializer {
        __ERC20_init("Solidary Musical Funding", "SOLMUS");
        __Ownable_init();
        __UUPSUpgradeable_init();
        
        // Transfer ownership to initial owner
        _transferOwnership(initialOwner);
        
        // Conversione EUR in wei (1 EUR = 10^18 wei per semplicità)
        fundingGoal = _fundingGoalEUR * 1e18;
        minimumContribution = _minimumContributionEUR * 1e18;
        
        fundingDeadline = block.timestamp + (_durationDays * 1 days);
        currentState = FundingState.ACTIVE;
        
        // Setup reward tiers iniziali
        _setupInitialRewardTiers();
        
        // Mint initial supply al deployer (per liquidità iniziale)
        _mint(initialOwner, 1000000 * 1e18); // 1M SOLMUS
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎭 CROWDFUNDING CORE FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Contribuisci al crowdfunding del musical
     * @dev Riceve ETH e minta SOLMUS tokens proporzionalmente
     */
    function contribute() external payable {
        require(currentState == FundingState.ACTIVE, "Crowdfunding not active");
        require(block.timestamp < fundingDeadline, "Crowdfunding ended");
        require(msg.value >= minimumContribution, "Below minimum contribution");
        
        // Aggiorna contributi
        if (!hasContributed[msg.sender]) {
            contributors.push(msg.sender);
            hasContributed[msg.sender] = true;
        }
        
        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;
        
        // Minta SOLMUS tokens (1:1 ratio con EUR)
        uint256 tokensToMint = msg.value; // Assume 1 ETH = 1 EUR per semplicità
        _mint(msg.sender, tokensToMint);
        
        // Determina tier raggiunto
        string memory tierAchieved = _determineRewardTier(contributions[msg.sender]);
        
        emit FundingContribution(msg.sender, msg.value, contributions[msg.sender], tierAchieved);
        
        // Check se obiettivo raggiunto
        if (totalRaised >= fundingGoal && currentState == FundingState.ACTIVE) {
            currentState = FundingState.GOAL_REACHED;
            emit FundingGoalReached(totalRaised, contributors.length);
        }
    }
    
    /**
     * @notice Termina il crowdfunding (solo owner)
     */
    function endFunding() external onlyOwner {
        require(currentState != FundingState.ENDED, "Already ended");
        require(block.timestamp >= fundingDeadline || currentState == FundingState.GOAL_REACHED, "Cannot end yet");
        
        bool successful = totalRaised >= fundingGoal;
        
        if (successful) {
            currentState = FundingState.ENDED;
            // Trasferisce i fondi al owner per produzione
            payable(owner()).transfer(address(this).balance);
        } else {
            currentState = FundingState.REFUNDING;
        }
        
        emit FundingEnded(successful, totalRaised);
    }
    
    /**
     * @notice Richiedi rimborso se crowdfunding fallito
     */
    function claimRefund() external {
        require(currentState == FundingState.REFUNDING, "Refunds not available");
        require(contributions[msg.sender] > 0, "No contribution to refund");
        
        uint256 refundAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        
        // Brucia i SOLMUS tokens ricevuti
        uint256 tokensToBurn = balanceOf(msg.sender);
        if (tokensToBurn > 0) {
            _burn(msg.sender, tokensToBurn);
        }
        
        payable(msg.sender).transfer(refundAmount);
        emit RefundProcessed(msg.sender, refundAmount);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏆 REWARD TIERS MANAGEMENT
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function _setupInitialRewardTiers() internal {
        // 🎭 CAST SUPPORTER (0.1+ ETH)
        rewardTiers.push(RewardTier({
            minAmount: 0.1 ether,
            tierName: "Cast Supporter",
            benefits: "Digital thank you + Production updates",
            nftBonus: 0
        }));
        
        // 🎵 ORCHESTRA MEMBER (0.5+ ETH)
        rewardTiers.push(RewardTier({
            minAmount: 0.5 ether,
            tierName: "Orchestra Member", 
            benefits: "Above + Exclusive rehearsal video",
            nftBonus: 1
        }));
        
        // 🎪 STAGE MANAGER (1+ ETH)
        rewardTiers.push(RewardTier({
            minAmount: 1 ether,
            tierName: "Stage Manager",
            benefits: "Above + VIP premiere tickets",
            nftBonus: 2
        }));
        
        // 🎭 EXECUTIVE PRODUCER (5+ ETH)
        rewardTiers.push(RewardTier({
            minAmount: 5 ether,
            tierName: "Executive Producer",
            benefits: "Above + Name in credits + Backstage access",
            nftBonus: 5
        }));
        
        // 👑 ARTISTIC DIRECTOR (10+ ETH)
        rewardTiers.push(RewardTier({
            minAmount: 10 ether,
            tierName: "Artistic Director",
            benefits: "Above + Private meet & greet + Royalty share",
            nftBonus: 10
        }));
    }
    
    function _determineRewardTier(uint256 contributionAmount) internal view returns (string memory) {
        for (uint256 i = rewardTiers.length; i > 0; i--) {
            if (contributionAmount >= rewardTiers[i-1].minAmount) {
                return rewardTiers[i-1].tierName;
            }
        }
        return "Contributor";
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 VIEW FUNCTIONS - Le statistiche del concerto
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function getFundingProgress() external view returns (
        uint256 raised,
        uint256 goal,
        uint256 percentage,
        uint256 timeLeft,
        FundingState state,
        uint256 totalContributors
    ) {
        raised = totalRaised;
        goal = fundingGoal;
        percentage = goal > 0 ? (raised * 100) / goal : 0;
        timeLeft = block.timestamp < fundingDeadline ? fundingDeadline - block.timestamp : 0;
        state = currentState;
        totalContributors = contributors.length;
    }
    
    function getContributorInfo(address contributor) external view returns (
        uint256 contribution,
        uint256 tokensOwned,
        string memory currentTier,
        bool hasContrib
    ) {
        contribution = contributions[contributor];
        tokensOwned = balanceOf(contributor);
        currentTier = _determineRewardTier(contribution);
        hasContrib = hasContributed[contributor];
    }
    
    function getRewardTierInfo(uint256 tierIndex) external view returns (RewardTier memory) {
        require(tierIndex < rewardTiers.length, "Invalid tier index");
        return rewardTiers[tierIndex];
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔧 ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function setRewardNFTContract(address _nftContract) external onlyOwner {
        rewardNFTContract = _nftContract;
    }
    
    function addRewardTier(
        uint256 minAmount,
        string memory tierName,
        string memory benefits,
        uint256 nftBonus
    ) external onlyOwner {
        rewardTiers.push(RewardTier({
            minAmount: minAmount,
            tierName: tierName,
            benefits: benefits,
            nftBonus: nftBonus
        }));
        
        emit RewardTierAdded(rewardTiers.length - 1, tierName, minAmount);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔐 UPGRADE AUTHORIZATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎵 MUSICAL SIGNATURE - Il finale dell'armonia
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Restituisce la firma musicale del contratto
     * @dev Easter egg per la teoria musicale: SOL come dominante
     */
    function getMusicalSignature() external pure returns (string memory) {
        return "SOL (G) - The dominant note that creates tension, resolving to success. SOLMUS->SOLDOUT: The perfect harmonic progression of solidarity!";
    }
}