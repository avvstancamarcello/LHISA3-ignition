// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca – Lawyer, Italy (Florence)

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol"; 
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../core_justice/RefundManager.sol";

/**
 * @title VotoGratis - Entertainment Voting Revolution
 * @dev Smart contract per sistema di voto gratuito per programmi TV, talent show, reality
 * Sostituisce il costoso voto via SMS con voto gratuito via wallet + ricompense
 * 
 * Features:
 * - Voto completamente gratuito (solo gas fee)
 * - Sistema ricompense per spettatori attivi
 * - Anti-manipolazione e anti-bot
 * - Integrazione broadcaster
 * - Real-time results
 * - Gamification e loyalty rewards
 * 
 * Target: TV Shows, Reality, Talent, Concorsi, Sport Events
 * Disrupts: SMS voting industry (miliardi di euro/anno)
 */
contract VotoGratis is 
    Initializable,
    ERC20Upgradeable, 
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    RefundManager 
{
    // ═══════════════════════════════════════════════════════════════════════════════
    // ROLES & CONSTANTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    bytes32 public constant SHOW_CREATOR_ROLE = keccak256("SHOW_CREATOR_ROLE");
    bytes32 public constant BROADCASTER_ROLE = keccak256("BROADCASTER_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    bytes32 public constant DRAW_OWNER_ROLE = keccak256("DRAW_OWNER_ROLE");
    bytes32 public constant SPONSOR_ROLE = keccak256("SPONSOR_ROLE");    

    
    uint256 public constant GRATIS_TOKEN_REWARD = 10 * 10**18; // 10 GRATIS per voto
    uint256 public constant LOYALTY_MULTIPLIER_THRESHOLD = 100; // 100 voti per 2x rewards
    uint256 public constant MAX_VOTES_PER_SHOW = 1000; // Limite anti-spam
    uint256 public constant SHOW_DURATION_MAX = 24 hours; // Durata massima show
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // STRUCTURES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    enum ShowStatus { CREATED, ACTIVE, PAUSED, ENDED, CANCELLED }
    enum VoteType { SINGLE_CHOICE, MULTIPLE_CHOICE, RANKING, RATING }
    
    struct TVShow {
        bytes32 showId;
        string name;
        string description;
        address broadcaster;
        uint256 startTime;
        uint256 endTime;
        ShowStatus status;
        VoteType voteType;
        uint256 totalVotes;
        uint256 totalRewards;
        string[] contestants;
        mapping(string => uint256) contestantVotes;
        mapping(address => bool) hasVoted;
        mapping(address => uint256) userVotes;
        bool rewardsEnabled;
        uint256 rewardPool;
    }
    
    struct UserStats {
        uint256 totalVotes;
        uint256 totalRewards;
        uint256 showsParticipated;
        uint256 loyaltyLevel;
        uint256 lastActivityTime;
    }
    
    struct Broadcaster {
        string name;
        bool verified;
        uint256 totalShows;
        uint256 totalAudience;
        address paymentAddress;
        uint256 revenueShare; // Percentage (in basis points, 10000 = 100%)
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    mapping(bytes32 => TVShow) public tvShows;
    mapping(address => UserStats) public userStats;
    mapping(address => Broadcaster) public broadcasters;
    mapping(address => bytes32[]) public userShowHistory;
    
    bytes32[] public activeShows;
    bytes32[] public allShows;
    
    uint256 public totalRewardsDistributed;
    uint256 public totalShowsCreated;
    uint256 public totalUsers;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    event ShowCreated(bytes32 indexed showId, string name, address broadcaster, uint256 startTime);
    event VoteCast(bytes32 indexed showId, address indexed voter, string contestant, uint256 timestamp);
    event RewardDistributed(address indexed user, uint256 amount, bytes32 indexed showId);
    event ShowEnded(bytes32 indexed showId, string winner, uint256 totalVotes);
    event BroadcasterRegistered(address indexed broadcaster, string name);
    event LoyaltyLevelUp(address indexed user, uint256 newLevel);
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // INITIALIZATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        address _creatorWallet,
        address _solidaryWallet,
        uint256 _refundDeadline,
        uint256 _initialThreshold, // <-- Aggiungere questo parametro
        address _drawOwner,
        address _sponsor
    ) public initializer {
        __RefundManager_init(_creatorWallet, _solidaryWallet, _refundDeadline, _initialThreshold); // <-- Passare il nuovo parametro
        __ERC20_init("IVOTE Democracy Token", "IVOTE");
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DRAW_OWNER_ROLE, _drawOwner);
        _grantRole(SPONSOR_ROLE, _sponsor);

        _mint(address(this), 1000000000 * 10**decimals());
    }   
     
    // ═══════════════════════════════════════════════════════════════════════════════
    // BROADCASTER MANAGEMENT
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Registra un broadcaster (TV channel, streaming platform, etc.)
     */
    function registerBroadcaster(
        address broadcasterAddress,
        string memory name,
        uint256 revenueShare
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(revenueShare <= 10000, "Revenue share cannot exceed 100%");
        
        broadcasters[broadcasterAddress] = Broadcaster({
            name: name,
            verified: true,
            totalShows: 0,
            totalAudience: 0,
            paymentAddress: broadcasterAddress,
            revenueShare: revenueShare
        });
        
        _grantRole(BROADCASTER_ROLE, broadcasterAddress);
        
        emit BroadcasterRegistered(broadcasterAddress, name);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // SHOW MANAGEMENT 
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Crea un nuovo show TV per il voto
     */
    function createShow(
        string memory name,
        string memory description,
        uint256 duration,
        VoteType voteType,
        string[] memory contestants,
        bool rewardsEnabled
    ) external onlyRole(BROADCASTER_ROLE) returns (bytes32 showId) {
        require(duration <= SHOW_DURATION_MAX, "Show duration too long");
        require(contestants.length >= 2, "Need at least 2 contestants");
        require(contestants.length <= 20, "Too many contestants");
        
        showId = keccak256(abi.encodePacked(
            name, 
            msg.sender, 
            block.timestamp,
            blockhash(block.number - 1)
        ));
        
        TVShow storage newShow = tvShows[showId];
        newShow.showId = showId;
        newShow.name = name;
        newShow.description = description;
        newShow.broadcaster = msg.sender;
        newShow.startTime = block.timestamp;
        newShow.endTime = block.timestamp + duration;
        newShow.status = ShowStatus.CREATED;
        newShow.voteType = voteType;
        newShow.contestants = contestants;
        newShow.rewardsEnabled = rewardsEnabled;
        
        if (rewardsEnabled) {
            // Allocate reward pool (1000 GRATIS per contestant)
            newShow.rewardPool = contestants.length * 1000 * 10**decimals();
        }
        
        allShows.push(showId);
        totalShowsCreated++;
        broadcasters[msg.sender].totalShows++;
        
        emit ShowCreated(showId, name, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Attiva uno show per iniziare il voto
     */
    function startShow(bytes32 showId) external {
        TVShow storage show = tvShows[showId];
        require(show.broadcaster == msg.sender, "Only broadcaster can start show");
        require(show.status == ShowStatus.CREATED, "Show already started or ended");
        require(block.timestamp >= show.startTime, "Show start time not reached");
        
        show.status = ShowStatus.ACTIVE;
        activeShows.push(showId);
    }
    
    /**
     * @dev Termina uno show e distribuisce ricompense
     */
    function endShow(bytes32 showId) external {
        TVShow storage show = tvShows[showId];
        require(
            show.broadcaster == msg.sender || hasRole(MODERATOR_ROLE, msg.sender),
            "Only broadcaster or moderator can end show"
        );
        require(show.status == ShowStatus.ACTIVE, "Show not active");
        
        show.status = ShowStatus.ENDED;
        _removeFromActiveShows(showId);
        
        // Trova il vincitore
        string memory winner = _determineWinner(showId);
        
        // Distribuisci ricompense se abilitate
        if (show.rewardsEnabled && show.totalVotes > 0) {
            _distributeShowRewards(showId);
        }
        
        emit ShowEnded(showId, winner, show.totalVotes);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // VOTING SYSTEM
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Vota per un concorrente - COMPLETAMENTE GRATUITO!
     */
    function voteForContestant(
        bytes32 showId,
        string memory contestant
    ) external nonReentrant {
        TVShow storage show = tvShows[showId];
        
        // Validazioni
        require(show.status == ShowStatus.ACTIVE, "Show not active");
        require(block.timestamp <= show.endTime, "Voting period ended");
        require(!show.hasVoted[msg.sender], "Already voted in this show");
        require(_isValidContestant(showId, contestant), "Invalid contestant");
        
        // Anti-spam: limite voti per show
        require(show.totalVotes < MAX_VOTES_PER_SHOW, "Vote limit reached");
        
        // Registra voto
        show.hasVoted[msg.sender] = true;
        show.contestantVotes[contestant]++;
        show.totalVotes++;
        show.userVotes[msg.sender] = 1;
        
        // Aggiorna statistiche utente
        UserStats storage stats = userStats[msg.sender];
        if (stats.totalVotes == 0) {
            totalUsers++; // Nuovo utente
        }
        stats.totalVotes++;
        stats.lastActivityTime = block.timestamp;
        
        // Aggiungi show alla cronologia utente
        userShowHistory[msg.sender].push(showId);
        
        // Distribuisci ricompensa GRATIS token
        if (show.rewardsEnabled) {
            uint256 reward = _calculateReward(msg.sender);
            _mint(msg.sender, reward);
            stats.totalRewards += reward;
            show.totalRewards += reward;
            totalRewardsDistributed += reward;
            
            emit RewardDistributed(msg.sender, reward, showId);
        }
        
        // Check loyalty level up
        _checkLoyaltyLevelUp(msg.sender);
        
        emit VoteCast(showId, msg.sender, contestant, block.timestamp);
    }
    
    /**
     * @dev Calcola ricompensa basata su loyalty e attività
     */
    function _calculateReward(address user) internal view returns (uint256) {
        UserStats memory stats = userStats[user];
        uint256 baseReward = GRATIS_TOKEN_REWARD;
        
        // Loyalty multiplier
        if (stats.totalVotes >= LOYALTY_MULTIPLIER_THRESHOLD) {
            baseReward = baseReward * 2; // 2x reward per utenti loyalty
        }
        
        // Early voter bonus (primi 100 voti)
        if (stats.totalVotes < 100) {
            baseReward = baseReward + (baseReward * 50 / 100); // +50% bonus
        }
        
        return baseReward;
    }
    
    /**
     * @dev Controlla e aggiorna loyalty level
     */
    function _checkLoyaltyLevelUp(address user) internal {
        UserStats storage stats = userStats[user];
        uint256 currentLevel = stats.loyaltyLevel;
        uint256 newLevel = stats.totalVotes / 50; // Level up ogni 50 voti
        
        if (newLevel > currentLevel) {
            stats.loyaltyLevel = newLevel;
            emit LoyaltyLevelUp(user, newLevel);
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // RESULTS & ANALYTICS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Ottieni risultati in tempo reale
     */
    function getShowResults(bytes32 showId) external view returns (
        string[] memory contestants,
        uint256[] memory votes,
        uint256 totalVotes,
        string memory leader
    ) {
        TVShow storage show = tvShows[showId];
        contestants = show.contestants;
        votes = new uint256[](contestants.length);
        
        uint256 maxVotes = 0;
        string memory currentLeader = "";
        
        for (uint256 i = 0; i < contestants.length; i++) {
            uint256 contestantVotes = show.contestantVotes[contestants[i]];
            votes[i] = contestantVotes;
            
            if (contestantVotes > maxVotes) {
                maxVotes = contestantVotes;
                currentLeader = contestants[i];
            }
        }
        
        return (contestants, votes, show.totalVotes, currentLeader);
    }
    
    /**
     * @dev Determina il vincitore
     */
    function _determineWinner(bytes32 showId) internal view returns (string memory) {
        TVShow storage show = tvShows[showId];
        string memory winner = "";
        uint256 maxVotes = 0;
        
        for (uint256 i = 0; i < show.contestants.length; i++) {
            string memory contestant = show.contestants[i];
            uint256 votes = show.contestantVotes[contestant];
            
            if (votes > maxVotes) {
                maxVotes = votes;
                winner = contestant;
            }
        }
        
        return winner;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // HELPER FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function _isValidContestant(bytes32 showId, string memory contestant) internal view returns (bool) {
        TVShow storage show = tvShows[showId];
        for (uint256 i = 0; i < show.contestants.length; i++) {
            if (keccak256(bytes(show.contestants[i])) == keccak256(bytes(contestant))) {
                return true;
            }
        }
        return false;
    }
    
    function _removeFromActiveShows(bytes32 showId) internal {
        for (uint256 i = 0; i < activeShows.length; i++) {
            if (activeShows[i] == showId) {
                activeShows[i] = activeShows[activeShows.length - 1];
                activeShows.pop();
                break;
            }
        }
    }
    
    function _distributeShowRewards(bytes32 showId) internal view {
        // TVShow storage show = tvShows[showId];
        // Logic per distribuire ricompense bonus ai partecipanti
        // TODO: Implementare distribuzione proporzionale
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // REFUND SYSTEM INTEGRATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Override RefundManager hook per gestire refund specifici
     */
    function _processRefundHook(address user, uint256 /*amount*/) internal override {
        // Burn GRATIS tokens dell'utente in caso di refund
        uint256 userBalance = balanceOf(user);
        if (userBalance > 0) {
            _burn(user, userBalance);
        }
        
        // Reset statistiche utente
        delete userStats[user];
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function getActiveShows() external view returns (bytes32[] memory) {
        return activeShows;
    }
    
    function getUserStats(address user) external view returns (UserStats memory) {
        return userStats[user];
    }
    
    function getBroadcaster(address broadcaster) external view returns (Broadcaster memory) {
        return broadcasters[broadcaster];
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // UPGRADE FUNCTIONALITY
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function _authorizeUpgrade(address newImplementation) internal override(RefundManager, UUPSUpgradeable) onlyRole(DEFAULT_ADMIN_ROLE) {}
}
