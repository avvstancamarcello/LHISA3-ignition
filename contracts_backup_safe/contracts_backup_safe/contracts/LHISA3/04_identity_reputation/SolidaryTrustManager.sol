// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca Lawyer - ITALY Florence
// Canto IV - Cerchi della Fiducia Umana - Divina Commedia della Solidarietà Blockchain

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title SolidaryTrustManager
 * @dev Sistema avanzato di gestione fiducia cross-chain per ecosistema Solidary
 * @notice Implementa algoritmi ML per trust score, fraud detection e dispute resolution
 */
contract SolidaryTrustManager is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔐 ROLES & CONSTANTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    bytes32 public constant TRUST_ORACLE = keccak256("TRUST_ORACLE");
    bytes32 public constant FRAUD_INVESTIGATOR = keccak256("FRAUD_INVESTIGATOR");
    bytes32 public constant DISPUTE_ARBITRATOR = keccak256("DISPUTE_ARBITRATOR");
    bytes32 public constant TRUST_ANALYZER = keccak256("TRUST_ANALYZER");
    
    uint256 public constant MAX_TRUST_SCORE = 10000; // 100.00%
    uint256 public constant TRUST_DECAY_RATE = 1; // Daily decay rate
    uint256 public constant MIN_INTERACTION_THRESHOLD = 5; // Min interactions for trust calc
    uint256 public constant FRAUD_DETECTION_THRESHOLD = 2000; // 20% fraud probability threshold
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 TRUST SYSTEM STRUCTURES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    struct TrustProfile {
        address userAddress;
        uint256 baseTrustScore;          // Core trust score (0-10000)
        uint256 reputationScore;         // Cross-chain reputation
        uint256 socialScore;             // Social network trust
        uint256 behaviorScore;           // Behavioral analysis score
        uint256 verificationScore;       // Identity verification level
        uint256 totalInteractions;       // Total number of interactions
        uint256 positiveInteractions;    // Successful interactions
        uint256 negativeInteractions;    // Failed/disputed interactions
        uint256 lastUpdateTimestamp;     // Last score update
        uint256 trustDecayDate;          // Last decay application
        bool isFlagged;                  // Flagged for suspicious activity
        bool isVerified;                 // KYC/Identity verified
        TrustLevel trustLevel;           // Current trust level
        mapping(address => InteractionRecord) interactions; // Peer interactions
    }
    
    enum TrustLevel {
        UNKNOWN,        // 0-1000: New user, minimal trust
        NEWCOMER,       // 1001-3000: Basic trust established
        MEMBER,         // 3001-6000: Trusted community member
        VETERAN,        // 6001-8000: Highly trusted veteran
        GUARDIAN,       // 8001-9500: Community guardian
        LEGEND          // 9501-10000: Legendary trust status
    }
    
    struct InteractionRecord {
        address counterparty;
        uint256 interactionCount;
        uint256 successfulCount;
        uint256 disputedCount;
        uint256 lastInteractionTime;
        uint256 totalValue;              // Total value of interactions
        InteractionType lastType;
        bool hasActiveDispute;
    }
    
    enum InteractionType {
        DONATION,
        NFT_TRADE,
        GOVERNANCE_VOTE,
        COLLABORATION,
        SERVICE_EXCHANGE,
        REPUTATION_ENDORSEMENT,
        CULTURAL_ACTIVITY,
        SOCIAL_INTERACTION
    }
    
    struct FraudAlert {
        uint256 alertId;
        address suspiciousAddress;
        FraudType fraudType;
        uint256 riskScore;           // 0-10000 risk probability
        uint256 alertTimestamp;
        string description;
        bool isInvestigated;
        bool isConfirmed;
        address investigator;
    }
    
    enum FraudType {
        SYBIL_ATTACK,           // Multiple fake accounts
        WASH_TRADING,           // Artificial transaction volume
        REPUTATION_GAMING,      // Gaming reputation systems
        IMPERSONATION,          // Identity impersonation
        SOCIAL_ENGINEERING,     // Social manipulation
        SMART_CONTRACT_EXPLOIT, // Contract exploitation
        COLLUSION,             // Coordinated manipulation
        OTHER_SUSPICIOUS       // Other suspicious behavior
    }
    
    struct Dispute {
        uint256 disputeId;
        address plaintiff;
        address defendant;
        InteractionType interactionType;
        uint256 disputedAmount;
        string description;
        uint256 creationTime;
        uint256 resolutionTime;
        DisputeStatus status;
        address arbitrator;
        DisputeResolution resolution;
        mapping(address => bool) evidenceSubmitted;
        string[] evidenceURIs;
    }
    
    enum DisputeStatus {
        OPEN,
        UNDER_REVIEW,
        EVIDENCE_COLLECTION,
        ARBITRATION,
        RESOLVED,
        APPEALED,
        CLOSED
    }
    
    struct DisputeResolution {
        address winner;
        uint256 compensationAmount;
        string reasoning;
        bool requiresRemediation;
        uint256 trustPenalty;        // Trust score penalty for losing party
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 💾 STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    mapping(address => TrustProfile) public trustProfiles;
    mapping(uint256 => FraudAlert) public fraudAlerts;
    mapping(uint256 => Dispute) public disputes;
    mapping(address => uint256[]) public userDisputes;
    mapping(TrustLevel => uint256) public trustLevelCounts;
    
    uint256 public currentAlertId;
    uint256 public currentDisputeId;
    uint256 public totalUsers;
    uint256 public totalFraudAlerts;
    uint256 public totalDisputes;
    uint256 public totalResolvedDisputes;
    
    // ML Model parameters (simplified)
    uint256 public behaviorWeight = 3000;      // 30%
    uint256 public reputationWeight = 2500;    // 25%
    uint256 public socialWeight = 2000;        // 20%
    uint256 public verificationWeight = 1500;  // 15%
    uint256 public interactionWeight = 1000;   // 10%
    
    // Contract references
    address public reputationManager;
    address public impactLogger;
    address public solidaryHub;
    address public bbtmInterface;
    address public algorandBridge;
    
    // System settings
    bool public trustSystemActive;
    bool public fraudDetectionActive;
    bool public disputeSystemActive;
    uint256 public trustUpdateInterval = 1 days;
    
    // Events
    event TrustScoreUpdated(address indexed user, uint256 oldScore, uint256 newScore, TrustLevel newLevel);
    event InteractionRecorded(address indexed user1, address indexed user2, InteractionType interactionType, uint256 value);
    event FraudAlertRaised(uint256 indexed alertId, address indexed suspiciousAddress, FraudType fraudType, uint256 riskScore);
    event DisputeOpened(uint256 indexed disputeId, address indexed plaintiff, address indexed defendant);
    event DisputeResolved(uint256 indexed disputeId, address indexed winner, uint256 compensation);
    event UserVerified(address indexed user, uint256 verificationScore);
    event TrustLevelChanged(address indexed user, TrustLevel oldLevel, TrustLevel newLevel);
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏗️ INITIALIZATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        address admin,
        address _reputationManager,
        address _impactLogger,
        address _solidaryHub,
        address _bbtmInterface,
        address _algorandBridge
    ) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(TRUST_ORACLE, admin);
        _grantRole(FRAUD_INVESTIGATOR, admin);
        _grantRole(DISPUTE_ARBITRATOR, admin);
        _grantRole(TRUST_ANALYZER, admin);
        
        reputationManager = _reputationManager;
        impactLogger = _impactLogger;
        solidaryHub = _solidaryHub;
        bbtmInterface = _bbtmInterface;
        algorandBridge = _algorandBridge;
        
        currentAlertId = 1;
        currentDisputeId = 1;
        trustSystemActive = true;
        fraudDetectionActive = true;
        disputeSystemActive = true;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🤝 TRUST SCORE CALCULATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Calcola il trust score composito usando algoritmo ML
     * @param user Indirizzo utente
     * @return trustScore Score di fiducia finale (0-10000)
     */
    function calculateTrustScore(address user) public view returns (uint256) {
        TrustProfile storage profile = trustProfiles[user];
        
        if (profile.totalInteractions < MIN_INTERACTION_THRESHOLD) {
            return profile.verificationScore; // Solo verification per nuovi utenti
        }
        
        // Weighted average of all components
        uint256 compositeScore = (
            profile.behaviorScore * behaviorWeight +
            profile.reputationScore * reputationWeight +
            profile.socialScore * socialWeight +
            profile.verificationScore * verificationWeight +
            _calculateInteractionScore(user) * interactionWeight
        ) / 10000;
        
        // Apply penalties for flags or negative interactions
        if (profile.isFlagged) {
            compositeScore = (compositeScore * 7000) / 10000; // 30% penalty
        }
        
        // Apply time decay
        compositeScore = _applyTimeDecay(compositeScore, profile.lastUpdateTimestamp);
        
        return compositeScore > MAX_TRUST_SCORE ? MAX_TRUST_SCORE : compositeScore;
    }
    
    /**
     * @dev Aggiorna il trust score di un utente
     * @param user Indirizzo utente
     */
    function updateTrustScore(address user) external {
        require(
            hasRole(TRUST_ORACLE, msg.sender) || 
            msg.sender == user || 
            block.timestamp >= trustProfiles[user].lastUpdateTimestamp + trustUpdateInterval,
            "Update not authorized or too frequent"
        );
        
        TrustProfile storage profile = trustProfiles[user];
        uint256 oldScore = profile.baseTrustScore;
        TrustLevel oldLevel = profile.trustLevel;
        
        // Calculate new trust score
        uint256 newScore = calculateTrustScore(user);
        profile.baseTrustScore = newScore;
        profile.lastUpdateTimestamp = block.timestamp;
        
        // Update trust level
        TrustLevel newLevel = _calculateTrustLevel(newScore);
        if (newLevel != oldLevel) {
            trustLevelCounts[oldLevel]--;
            trustLevelCounts[newLevel]++;
            profile.trustLevel = newLevel;
            emit TrustLevelChanged(user, oldLevel, newLevel);
        }
        
        // Sync with cross-chain reputation
        _syncCrossChainReputation(user, newScore);
        
        emit TrustScoreUpdated(user, oldScore, newScore, newLevel);
    }
    
    /**
     * @dev Registra un'interazione tra due utenti
     * @param user1 Primo utente
     * @param user2 Secondo utente
     * @param interactionType Tipo di interazione
     * @param value Valore dell'interazione
     * @param successful Se l'interazione è stata positiva
     */
    function recordInteraction(
        address user1,
        address user2,
        InteractionType interactionType,
        uint256 value,
        bool successful
    ) external onlyRole(TRUST_ORACLE) {
        require(user1 != user2, "Cannot interact with self");
        
        _updateInteractionRecord(user1, user2, interactionType, value, successful);
        _updateInteractionRecord(user2, user1, interactionType, value, successful);
        
        // Update behavior scores based on interaction
        if (successful) {
            _increaseBehaviorScore(user1, interactionType, value);
            _increaseBehaviorScore(user2, interactionType, value);
        } else {
            _decreaseBehaviorScore(user1, interactionType, value);
            _decreaseBehaviorScore(user2, interactionType, value);
        }
        
        emit InteractionRecorded(user1, user2, interactionType, value);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔍 FRAUD DETECTION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Sistema automatico di rilevamento frodi
     * @param suspiciousAddress Indirizzo sospetto
     * @param fraudType Tipo di frode rilevata
     * @param evidenceURI URI con evidenze
     * @return alertId ID dell'alert generato
     */
    function raiseFraudAlert(
        address suspiciousAddress,
        FraudType fraudType,
        string memory evidenceURI
    ) external onlyRole(FRAUD_INVESTIGATOR) returns (uint256) {
        uint256 riskScore = _calculateFraudRisk(suspiciousAddress, fraudType);
        
        uint256 alertId = currentAlertId++;
        FraudAlert storage alert = fraudAlerts[alertId];
        alert.alertId = alertId;
        alert.suspiciousAddress = suspiciousAddress;
        alert.fraudType = fraudType;
        alert.riskScore = riskScore;
        alert.alertTimestamp = block.timestamp;
        alert.description = evidenceURI;
        alert.investigator = msg.sender;
        
        totalFraudAlerts++;
        
        // Auto-flag if risk score is high
        if (riskScore >= FRAUD_DETECTION_THRESHOLD) {
            trustProfiles[suspiciousAddress].isFlagged = true;
        }
        
        emit FraudAlertRaised(alertId, suspiciousAddress, fraudType, riskScore);
        return alertId;
    }
    
    /**
     * @dev Analisi comportamentale automatica per rilevamento pattern sospetti
     * @param user Utente da analizzare
     * @return riskScore Score di rischio (0-10000)
     */
    function analyzeBehavioralPatterns(address user) external view returns (uint256) {
        TrustProfile storage profile = trustProfiles[user];
        
        uint256 riskScore = 0;
        
        // Pattern 1: Troppo poche interazioni positive
        if (profile.totalInteractions > 0) {
            uint256 successRate = (profile.positiveInteractions * 10000) / profile.totalInteractions;
            if (successRate < 5000) { // <50% success rate
                riskScore += 1000;
            }
        }
        
        // Pattern 2: Account troppo nuovo con alta attività
        if (block.timestamp - profile.lastUpdateTimestamp < 7 days && profile.totalInteractions > 50) {
            riskScore += 1500;
        }
        
        // Pattern 3: Score di reputation molto basso
        if (profile.reputationScore < 1000) {
            riskScore += 800;
        }
        
        // Pattern 4: Già flaggato in precedenza
        if (profile.isFlagged) {
            riskScore += 2000;
        }
        
        return riskScore > 10000 ? 10000 : riskScore;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // ⚖️ DISPUTE RESOLUTION SYSTEM
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Apre una disputa tra due utenti
     * @param defendant Utente accusato
     * @param interactionType Tipo di interazione disputata
     * @param disputedAmount Valore in disputa
     * @param description Descrizione della disputa
     * @return disputeId ID della disputa
     */
    function openDispute(
        address defendant,
        InteractionType interactionType,
        uint256 disputedAmount,
        string memory description
    ) external returns (uint256) {
        require(disputeSystemActive, "Dispute system not active");
        require(defendant != msg.sender, "Cannot dispute with self");
        
        uint256 disputeId = currentDisputeId++;
        Dispute storage dispute = disputes[disputeId];
        dispute.disputeId = disputeId;
        dispute.plaintiff = msg.sender;
        dispute.defendant = defendant;
        dispute.interactionType = interactionType;
        dispute.disputedAmount = disputedAmount;
        dispute.description = description;
        dispute.creationTime = block.timestamp;
        dispute.status = DisputeStatus.OPEN;
        
        // Add to user dispute lists
        userDisputes[msg.sender].push(disputeId);
        userDisputes[defendant].push(disputeId);
        
        // Mark interaction as disputed
        trustProfiles[msg.sender].interactions[defendant].hasActiveDispute = true;
        trustProfiles[defendant].interactions[msg.sender].hasActiveDispute = true;
        
        totalDisputes++;
        
        emit DisputeOpened(disputeId, msg.sender, defendant);
        return disputeId;
    }
    
    /**
     * @dev Risolve una disputa con decisione arbitraria
     * @param disputeId ID della disputa
     * @param winner Utente che vince la disputa
     * @param compensationAmount Compenso da assegnare
     * @param reasoning Motivazione della decisione
     * @param trustPenalty Penalità trust per chi perde
     */
    function resolveDispute(
        uint256 disputeId,
        address winner,
        uint256 compensationAmount,
        string memory reasoning,
        uint256 trustPenalty
    ) external onlyRole(DISPUTE_ARBITRATOR) {
        Dispute storage dispute = disputes[disputeId];
        require(dispute.status == DisputeStatus.OPEN || dispute.status == DisputeStatus.UNDER_REVIEW, "Dispute not resolvable");
        require(winner == dispute.plaintiff || winner == dispute.defendant, "Invalid winner");
        
        address loser = (winner == dispute.plaintiff) ? dispute.defendant : dispute.plaintiff;
        
        // Set resolution
        dispute.resolution.winner = winner;
        dispute.resolution.compensationAmount = compensationAmount;
        dispute.resolution.reasoning = reasoning;
        dispute.resolution.trustPenalty = trustPenalty;
        dispute.status = DisputeStatus.RESOLVED;
        dispute.resolutionTime = block.timestamp;
        dispute.arbitrator = msg.sender;
        
        // Apply trust penalties
        if (trustPenalty > 0) {
            TrustProfile storage loserProfile = trustProfiles[loser];
            loserProfile.baseTrustScore = loserProfile.baseTrustScore > trustPenalty ? 
                loserProfile.baseTrustScore - trustPenalty : 0;
            loserProfile.negativeInteractions++;
        }
        
        // Clear dispute flags
        trustProfiles[dispute.plaintiff].interactions[dispute.defendant].hasActiveDispute = false;
        trustProfiles[dispute.defendant].interactions[dispute.plaintiff].hasActiveDispute = false;
        
        totalResolvedDisputes++;
        
        emit DisputeResolved(disputeId, winner, compensationAmount);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔧 INTERNAL UTILITY FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function _updateInteractionRecord(
        address user,
        address counterparty,
        InteractionType interactionType,
        uint256 value,
        bool successful
    ) internal {
        TrustProfile storage profile = trustProfiles[user];
        InteractionRecord storage record = profile.interactions[counterparty];
        
        record.counterparty = counterparty;
        record.interactionCount++;
        record.lastInteractionTime = block.timestamp;
        record.totalValue += value;
        record.lastType = interactionType;
        
        if (successful) {
            record.successfulCount++;
            profile.positiveInteractions++;
        } else {
            record.disputedCount++;
            profile.negativeInteractions++;
        }
        
        profile.totalInteractions++;
        
        // Initialize user if first interaction
        if (profile.userAddress == address(0)) {
            profile.userAddress = user;
            profile.trustLevel = TrustLevel.UNKNOWN;
            trustLevelCounts[TrustLevel.UNKNOWN]++;
            totalUsers++;
        }
    }
    
    function _increaseBehaviorScore(address user, InteractionType interactionType, uint256 value) internal {
        TrustProfile storage profile = trustProfiles[user];
        uint256 increase = _calculateScoreIncrease(interactionType, value);
        profile.behaviorScore += increase;
        if (profile.behaviorScore > MAX_TRUST_SCORE) {
            profile.behaviorScore = MAX_TRUST_SCORE;
        }
    }
    
    function _decreaseBehaviorScore(address user, InteractionType interactionType, uint256 value) internal {
        TrustProfile storage profile = trustProfiles[user];
        uint256 decrease = _calculateScoreDecrease(interactionType, value);
        profile.behaviorScore = profile.behaviorScore > decrease ? profile.behaviorScore - decrease : 0;
    }
    
    function _calculateScoreIncrease(InteractionType interactionType, uint256 value) internal pure returns (uint256) {
        uint256 baseIncrease = 10;
        if (interactionType == InteractionType.DONATION) baseIncrease = 20;
        else if (interactionType == InteractionType.GOVERNANCE_VOTE) baseIncrease = 15;
        else if (interactionType == InteractionType.CULTURAL_ACTIVITY) baseIncrease = 25;
        
        return baseIncrease + (value / 1e18); // 1 point per ETH equivalent
    }
    
    function _calculateScoreDecrease(InteractionType interactionType, uint256 value) internal pure returns (uint256) {
        uint256 baseDecrease = 20;
        if (interactionType == InteractionType.NFT_TRADE) baseDecrease = 30;
        else if (interactionType == InteractionType.SERVICE_EXCHANGE) baseDecrease = 25;
        
        return baseDecrease + (value / 5e17); // 1 point per 0.5 ETH equivalent
    }
    
    function _calculateInteractionScore(address user) internal view returns (uint256) {
        TrustProfile storage profile = trustProfiles[user];
        if (profile.totalInteractions == 0) return 0;
        
        return (profile.positiveInteractions * MAX_TRUST_SCORE) / profile.totalInteractions;
    }
    
    function _applyTimeDecay(uint256 score, uint256 lastUpdate) internal view returns (uint256) {
        uint256 daysPassed = (block.timestamp - lastUpdate) / 1 days;
        uint256 decayAmount = daysPassed * TRUST_DECAY_RATE;
        
        return score > decayAmount ? score - decayAmount : 0;
    }
    
    function _calculateTrustLevel(uint256 score) internal pure returns (TrustLevel) {
        if (score <= 1000) return TrustLevel.UNKNOWN;
        else if (score <= 3000) return TrustLevel.NEWCOMER;
        else if (score <= 6000) return TrustLevel.MEMBER;
        else if (score <= 8000) return TrustLevel.VETERAN;
        else if (score <= 9500) return TrustLevel.GUARDIAN;
        else return TrustLevel.LEGEND;
    }
    
    function _calculateFraudRisk(address user, FraudType fraudType) internal view returns (uint256) {
        uint256 baseRisk = 1000;
        
        if (fraudType == FraudType.SYBIL_ATTACK) baseRisk = 3000;
        else if (fraudType == FraudType.SMART_CONTRACT_EXPLOIT) baseRisk = 5000;
        else if (fraudType == FraudType.WASH_TRADING) baseRisk = 2500;
        
        // Adjust based on user's current trust
        uint256 userTrust = trustProfiles[user].baseTrustScore;
        if (userTrust > 5000) {
            baseRisk = (baseRisk * 7000) / 10000; // Reduce risk for trusted users
        }
        
        return baseRisk;
    }
    
    function _syncCrossChainReputation(address user, uint256 trustScore) internal {
        // Sync with ReputationManager
        (bool success, ) = reputationManager.call(
            abi.encodeWithSignature(
                "updateCrossChainReputation(address,uint256)",
                user,
                trustScore
            )
        );
        
        // Sync with BBTM Network
        if (bbtmInterface != address(0)) {
            (success, ) = bbtmInterface.call(
                abi.encodeWithSignature(
                    "updateUserAuthority(address,uint256)",
                    user,
                    trustScore
                )
            );
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 👁️ VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function getTrustProfile(address user) external view returns (
        uint256 baseTrustScore,
        uint256 reputationScore,
        uint256 socialScore,
        uint256 behaviorScore,
        uint256 verificationScore,
        uint256 totalInteractions,
        uint256 positiveInteractions,
        bool isFlagged,
        bool isVerified,
        TrustLevel trustLevel
    ) {
        TrustProfile storage profile = trustProfiles[user];
        return (
            profile.baseTrustScore,
            profile.reputationScore,
            profile.socialScore,
            profile.behaviorScore,
            profile.verificationScore,
            profile.totalInteractions,
            profile.positiveInteractions,
            profile.isFlagged,
            profile.isVerified,
            profile.trustLevel
        );
    }
    
    function getFraudAlert(uint256 alertId) external view returns (FraudAlert memory) {
        return fraudAlerts[alertId];
    }
    
    function getDispute(uint256 disputeId) external view returns (
        uint256 id,
        address plaintiff,
        address defendant,
        InteractionType interactionType,
        uint256 disputedAmount,
        string memory description,
        DisputeStatus status,
        address arbitrator
    ) {
        Dispute storage dispute = disputes[disputeId];
        return (
            dispute.disputeId,
            dispute.plaintiff,
            dispute.defendant,
            dispute.interactionType,
            dispute.disputedAmount,
            dispute.description,
            dispute.status,
            dispute.arbitrator
        );
    }
    
    function getUserDisputes(address user) external view returns (uint256[] memory) {
        return userDisputes[user];
    }
    
    function getSystemStats() external view returns (
        uint256 users,
        uint256 alerts,
        uint256 totalDisputesCount,
        uint256 resolvedDisputesCount
    ) {
        return (totalUsers, totalFraudAlerts, totalDisputes, totalResolvedDisputes);
    }
    
    function getTrustLevelDistribution() external view returns (uint256[6] memory) {
        return [
            trustLevelCounts[TrustLevel.UNKNOWN],
            trustLevelCounts[TrustLevel.NEWCOMER],
            trustLevelCounts[TrustLevel.MEMBER],
            trustLevelCounts[TrustLevel.VETERAN],
            trustLevelCounts[TrustLevel.GUARDIAN],
            trustLevelCounts[TrustLevel.LEGEND]
        ];
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // ⚙️ ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function setMLWeights(
        uint256 _behaviorWeight,
        uint256 _reputationWeight,
        uint256 _socialWeight,
        uint256 _verificationWeight,
        uint256 _interactionWeight
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_behaviorWeight + _reputationWeight + _socialWeight + _verificationWeight + _interactionWeight == 10000, "Weights must sum to 100%");
        
        behaviorWeight = _behaviorWeight;
        reputationWeight = _reputationWeight;
        socialWeight = _socialWeight;
        verificationWeight = _verificationWeight;
        interactionWeight = _interactionWeight;
    }
    
    function setSystemStatus(bool trustActive, bool fraudActive, bool disputeActive) 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        trustSystemActive = trustActive;
        fraudDetectionActive = fraudActive;
        disputeSystemActive = disputeActive;
    }
    
    function verifyUser(address user, uint256 verificationScore) 
        external onlyRole(TRUST_ORACLE) 
    {
        require(verificationScore <= MAX_TRUST_SCORE, "Verification score too high");
        
        TrustProfile storage profile = trustProfiles[user];
        profile.isVerified = true;
        profile.verificationScore = verificationScore;
        
        emit UserVerified(user, verificationScore);
    }
    
    function updateContractReferences(
        address _reputationManager,
        address _impactLogger,
        address _solidaryHub,
        address _bbtmInterface,
        address _algorandBridge
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_reputationManager != address(0)) reputationManager = _reputationManager;
        if (_impactLogger != address(0)) impactLogger = _impactLogger;
        if (_solidaryHub != address(0)) solidaryHub = _solidaryHub;
        if (_bbtmInterface != address(0)) bbtmInterface = _bbtmInterface;
        if (_algorandBridge != address(0)) algorandBridge = _algorandBridge;
    }
}