// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.29;

import "./core/RefundManager.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title SolidarySoldOut_V2_WithRefund
 * @author Avv. Marcello Stanca - Solidary Network Architect
 * @notice Token SOLDOUT rappresenta il successo dell'ecosistema con protezione refund
 * @dev Upgrade del sistema SOLDOUT con RefundManager per protezione investitori
 * 
 * 🎪 SOLDOUT + REFUND SYSTEM:
 * - Token ERC20 rappresentativo del successo dell'ecosistema Solidary
 * - Minting legato a milestone e achievement dell'ecosistema
 * - Protezione acquirenti con soglia globale 100.000 EUR
 * - Refund automatico se target non raggiunto
 * - Sistema di staking e rewards per holder
 * 
 * 🏆 SUCCESS TOKEN + INVESTOR PROTECTION:
 * Combina celebrazione del successo con garanzie economiche
 */
contract SolidarySoldOut_V2_WithRefund is RefundManager, ERC20Upgradeable, AccessControlUpgradeable {
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎪 SOLDOUT SPECIFIC ROLES & CONSTANTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    bytes32 public constant MAESTRO_ROLE = keccak256("MAESTRO_ROLE");
    bytes32 public constant PRODUCER_ROLE = keccak256("PRODUCER_ROLE");
    bytes32 public constant STAGE_MANAGER_ROLE = keccak256("STAGE_MANAGER_ROLE");
    
    /// @notice Prezzo per 1 SOLDOUT token (in wei)
    uint256 public soldoutTokenPrice;
    
    /// @notice Supply massima di SOLDOUT tokens
    uint256 public constant MAX_SOLDOUT_SUPPLY = 1000000 * 10**18; // 1M tokens
    
    /// @notice Percentuale APY per staking
    uint256 public stakingAPY;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏆 SUCCESS MILESTONES SYSTEM
    // ═══════════════════════════════════════════════════════════════════════════════
    
    struct Milestone {
        string name;
        string description;
        uint256 targetAmount;
        bool achieved;
        uint256 achievedAt;
        uint256 rewardTokens;
    }
    
    /// @notice Array delle milestone dell'ecosistema
    Milestone[] public milestones;
    
    /// @notice Mapping utente → milestone raggiunte
    mapping(address => mapping(uint256 => bool)) public userMilestoneRewards;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 💎 STAKING SYSTEM
    // ═══════════════════════════════════════════════════════════════════════════════
    
    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        uint256 lastRewardTime;
        uint256 accumulatedRewards;
    }
    
    /// @notice Mapping utente → info staking
    mapping(address => StakeInfo) public userStakes;
    
    /// @notice Totale tokens in staking
    uint256 public totalStaked;
    
    /// @notice Pool di rewards per staking
    uint256 public rewardPool;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📢 EVENTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    event SOLDOUTTokenPurchased(address indexed buyer, uint256 amount, uint256 tokensReceived);
    event MilestoneAchieved(uint256 indexed milestoneId, string name, uint256 targetAmount);
    event MilestoneRewardClaimed(address indexed user, uint256 indexed milestoneId, uint256 rewardTokens);
    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount, uint256 rewards);
    event StakingRewardsClaimed(address indexed user, uint256 rewards);
    event PriceUpdated(uint256 newPrice);
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏗️ INITIALIZATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        uint256 _tokenPrice,
        uint256 _stakingAPY,
        address _creatorWallet,
        address _solidaryWallet,
        uint256 _refundDeadline,
        address _maestro
    ) public initializer {
        __RefundManager_init(_creatorWallet, _solidaryWallet, _refundDeadline);
        __ERC20_init("Solidary SOLDOUT", "SOLDOUT");
        __AccessControl_init();
        
        soldoutTokenPrice = _tokenPrice;
        stakingAPY = _stakingAPY;
        
        // Setup roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MAESTRO_ROLE, _maestro);
        _grantRole(PRODUCER_ROLE, msg.sender);
        
        // Inizializza milestone di successo
        _initializeMilestones();
    }
    
    /**
     * @notice Inizializza le milestone dell'ecosistema
     */
    function _initializeMilestones() internal {
        // Milestone 1: Prima vendita
        milestones.push(Milestone({
            name: "First Sale",
            description: "Prima vendita NFT/Token nell'ecosistema",
            targetAmount: 1 ether,
            achieved: false,
            achievedAt: 0,
            rewardTokens: 100 * 10**decimals()
        }));
        
        // Milestone 2: Community Building
        milestones.push(Milestone({
            name: "Community Builder",
            description: "Raggiungimento 1.000 EUR di vendite totali",
            targetAmount: 1000 ether,
            achieved: false,
            achievedAt: 0,
            rewardTokens: 500 * 10**decimals()
        }));
        
        // Milestone 3: Ecosystem Growth
        milestones.push(Milestone({
            name: "Ecosystem Growth",
            description: "Raggiungimento 10.000 EUR di vendite totali",
            targetAmount: 10000 ether,
            achieved: false,
            achievedAt: 0,
            rewardTokens: 2000 * 10**decimals()
        }));
        
        // Milestone 4: Major Success
        milestones.push(Milestone({
            name: "Major Success",
            description: "Raggiungimento 50.000 EUR di vendite totali",
            targetAmount: 50000 ether,
            achieved: false,
            achievedAt: 0,
            rewardTokens: 5000 * 10**decimals()
        }));
        
        // Milestone 5: SOLDOUT Achievement
        milestones.push(Milestone({
            name: "SOLDOUT Achievement",
            description: "Raggiungimento soglia 100.000 EUR - Ecosistema SOLDOUT!",
            targetAmount: GLOBAL_SUCCESS_THRESHOLD,
            achieved: false,
            achievedAt: 0,
            rewardTokens: 10000 * 10**decimals()
        }));
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎪 SOLDOUT TOKEN PURCHASE WITH REFUND PROTECTION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Acquista SOLDOUT tokens con protezione refund
     * @param tokenAmount Numero di tokens da acquistare
     */
    function purchaseSOLDOUTTokens(uint256 tokenAmount) external payable nonReentrant {
        require(tokenAmount > 0, "Invalid token amount");
        
        uint256 totalCost = tokenAmount * soldoutTokenPrice / 10**decimals();
        require(msg.value >= totalCost, "Insufficient payment");
        require(totalSupply() + tokenAmount <= MAX_SOLDOUT_SUPPLY, "Exceeds max supply");
        
        // Registra contribuzione per sistema refund
        _recordContribution(msg.sender, msg.value);
        
        // Mint SOLDOUT tokens
        _mint(msg.sender, tokenAmount);
        
        // Controlla e aggiorna milestone
        _checkAndUpdateMilestones();
        
        emit SOLDOUTTokenPurchased(msg.sender, msg.value, tokenAmount);
    }
    
    /**
     * @notice Partecipa al successo dell'ecosistema con contribuzione diretta
     */
    function contributeToSuccess() external payable nonReentrant {
        require(msg.value > 0, "Invalid contribution");
        
        // Registra contribuzione per sistema refund
        _recordContribution(msg.sender, msg.value);
        
        // Calcola bonus tokens basato sulla contribuzione
        uint256 bonusTokens = (msg.value * 1000) / soldoutTokenPrice; // Bonus rate
        
        if (totalSupply() + bonusTokens <= MAX_SOLDOUT_SUPPLY) {
            _mint(msg.sender, bonusTokens);
        }
        
        // Aggiungi alla reward pool per staking
        rewardPool += msg.value / 10; // 10% al reward pool
        
        // Controlla milestone
        _checkAndUpdateMilestones();
        
        emit SOLDOUTTokenPurchased(msg.sender, msg.value, bonusTokens);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏆 MILESTONE SYSTEM
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Controlla e aggiorna milestone raggiunte
     */
    function _checkAndUpdateMilestones() internal {
        uint256 currentTotal = totalRaisedEcosystem > 0 ? totalRaisedEcosystem : totalRaisedThisPlanet;
        
        for (uint i = 0; i < milestones.length; i++) {
            if (!milestones[i].achieved && currentTotal >= milestones[i].targetAmount) {
                milestones[i].achieved = true;
                milestones[i].achievedAt = block.timestamp;
                
                emit MilestoneAchieved(i, milestones[i].name, milestones[i].targetAmount);
            }
        }
    }
    
    /**
     * @notice Reclama reward per milestone raggiunta
     * @param milestoneId ID della milestone
     */
    function claimMilestoneReward(uint256 milestoneId) external nonReentrant {
        require(milestoneId < milestones.length, "Invalid milestone ID");
        require(milestones[milestoneId].achieved, "Milestone not achieved");
        require(!userMilestoneRewards[msg.sender][milestoneId], "Reward already claimed");
        require(balanceOf(msg.sender) > 0, "Must hold SOLDOUT tokens");
        
        userMilestoneRewards[msg.sender][milestoneId] = true;
        
        uint256 rewardAmount = milestones[milestoneId].rewardTokens;
        if (totalSupply() + rewardAmount <= MAX_SOLDOUT_SUPPLY) {
            _mint(msg.sender, rewardAmount);
        }
        
        emit MilestoneRewardClaimed(msg.sender, milestoneId, rewardAmount);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 💎 STAKING SYSTEM
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Stake SOLDOUT tokens per rewards
     * @param amount Numero di tokens da stakare
     */
    function stakeTokens(uint256 amount) external nonReentrant {
        require(amount > 0, "Invalid amount");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        // Aggiorna rewards esistenti
        _updateStakingRewards(msg.sender);
        
        // Trasferisci tokens al contratto
        _transfer(msg.sender, address(this), amount);
        
        // Aggiorna info staking
        userStakes[msg.sender].amount += amount;
        userStakes[msg.sender].startTime = block.timestamp;
        userStakes[msg.sender].lastRewardTime = block.timestamp;
        
        totalStaked += amount;
        
        emit TokensStaked(msg.sender, amount);
    }
    
    /**
     * @notice Unstake tokens e reclama rewards
     * @param amount Numero di tokens da unstakare
     */
    function unstakeTokens(uint256 amount) external nonReentrant {
        require(amount > 0, "Invalid amount");
        require(userStakes[msg.sender].amount >= amount, "Insufficient staked amount");
        
        // Aggiorna e paga rewards
        _updateStakingRewards(msg.sender);
        uint256 rewards = userStakes[msg.sender].accumulatedRewards;
        userStakes[msg.sender].accumulatedRewards = 0;
        
        // Aggiorna info staking
        userStakes[msg.sender].amount -= amount;
        totalStaked -= amount;
        
        // Trasferisci tokens indietro
        _transfer(address(this), msg.sender, amount);
        
        // Paga rewards se disponibili
        if (rewards > 0 && rewardPool >= rewards) {
            rewardPool -= rewards;
            payable(msg.sender).transfer(rewards);
        }
        
        emit TokensUnstaked(msg.sender, amount, rewards);
    }
    
    /**
     * @notice Aggiorna rewards di staking per un utente
     */
    function _updateStakingRewards(address user) internal {
        StakeInfo storage stake = userStakes[user];
        
        if (stake.amount > 0) {
            uint256 timeStaked = block.timestamp - stake.lastRewardTime;
            uint256 rewards = (stake.amount * stakingAPY * timeStaked) / (365 days * 10000);
            
            stake.accumulatedRewards += rewards;
            stake.lastRewardTime = block.timestamp;
        }
    }
    
    /**
     * @notice Reclama solo i rewards senza unstaking
     */
    function claimStakingRewards() external nonReentrant {
        _updateStakingRewards(msg.sender);
        uint256 rewards = userStakes[msg.sender].accumulatedRewards;
        
        require(rewards > 0, "No rewards available");
        require(rewardPool >= rewards, "Insufficient reward pool");
        
        userStakes[msg.sender].accumulatedRewards = 0;
        rewardPool -= rewards;
        
        payable(msg.sender).transfer(rewards);
        
        emit StakingRewardsClaimed(msg.sender, rewards);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔄 REFUND SYSTEM INTEGRATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Hook specifico per SOLDOUT durante refund
     * @dev Brucia i token SOLDOUT dell'utente durante il refund
     * @param user Utente che richiede refund
     * @param originalAmount Importo originale della contribuzione
     */
    function _processRefundHook(address user, uint256 originalAmount) internal override {
        // Calcola tokens da bruciare basato sulla contribuzione
        uint256 tokensToBurn = (originalAmount * 10**decimals()) / soldoutTokenPrice;
        uint256 userBalance = balanceOf(user);
        
        // Brucia i token (fino al massimo del balance utente)
        uint256 burnAmount = tokensToBurn > userBalance ? userBalance : tokensToBurn;
        if (burnAmount > 0) {
            _burn(user, burnAmount);
        }
        
        // Se aveva tokens in staking, rimuovili
        if (userStakes[user].amount > 0) {
            totalStaked -= userStakes[user].amount;
            delete userStakes[user];
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Ottieni tutte le milestone
     */
    function getAllMilestones() external view returns (Milestone[] memory) {
        return milestones;
    }
    
    /**
     * @notice Ottieni info staking di un utente
     */
    function getStakingInfo(address user) external view returns (
        uint256 stakedAmount,
        uint256 pendingRewards,
        uint256 stakingDuration
    ) {
        StakeInfo storage stake = userStakes[user];
        stakedAmount = stake.amount;
        
        if (stake.amount > 0) {
            uint256 timeStaked = block.timestamp - stake.lastRewardTime;
            pendingRewards = stake.accumulatedRewards + 
                (stake.amount * stakingAPY * timeStaked) / (365 days * 10000);
            stakingDuration = block.timestamp - stake.startTime;
        }
    }
    
    /**
     * @notice Calcola prezzo per numero di tokens
     */
    function calculateTokenPrice(uint256 tokenAmount) external view returns (uint256) {
        return (tokenAmount * soldoutTokenPrice) / 10**decimals();
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔐 ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Aggiorna prezzo token (solo MAESTRO)
     */
    function updateTokenPrice(uint256 _newPrice) external onlyRole(MAESTRO_ROLE) {
        soldoutTokenPrice = _newPrice;
        emit PriceUpdated(_newPrice);
    }
    
    /**
     * @notice Aggiorna APY staking (solo admin)
     */
    function updateStakingAPY(uint256 _newAPY) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingAPY = _newAPY;
    }
    
    /**
     * @notice Aggiungi fondi al reward pool (solo admin)
     */
    function addToRewardPool() external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        rewardPool += msg.value;
    }
    
    /**
     * @notice Aggiorna milestone manualmente (solo MAESTRO)
     */
    function forceUpdateMilestones() external onlyRole(MAESTRO_ROLE) {
        _checkAndUpdateMilestones();
    }
}