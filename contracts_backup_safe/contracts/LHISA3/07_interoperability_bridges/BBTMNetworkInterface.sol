// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca, Firenze, Italy

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title BBTMNetworkInterface
 * @dev Interface per integrazione con rete superveloce BBTM
 * @notice Gestisce protocollo di autorevolezza e validazioni ultra-rapide
 */
contract BBTMNetworkInterface is Initializable, AccessControlUpgradeable {
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔐 ROLES & CONSTANTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    bytes32 public constant BBTM_VALIDATOR = keccak256("BBTM_VALIDATOR");
    bytes32 public constant AUTHORITY_MANAGER = keccak256("AUTHORITY_MANAGER");
    bytes32 public constant CONSENSUS_ORACLE = keccak256("CONSENSUS_ORACLE");
    bytes32 public constant NETWORK_MONITOR = keccak256("NETWORK_MONITOR");
    
    // BBTM Network Constants
    uint256 public constant BBTM_BLOCK_TIME = 100; // 100ms target block time
    uint256 public constant MAX_TPS = 100000; // 100k transactions per second
    uint256 public constant FINALITY_TIME = 2000; // 2 seconds for finality
    uint256 public constant AUTHORITY_THRESHOLD = 1000; // Minimum authority score
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 AUTHORITY PROTOCOL STRUCTURES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    struct AuthorityNode {
        address validator;              // Validator address
        uint256 technicalSkill;        // Technical validation capability
        uint256 socialReputation;      // Social community standing
        uint256 impactContribution;    // Measured social/environmental impact
        uint256 stakingPower;          // Economic stake in network
        uint256 validatedBlocks;       // Number of blocks validated
        uint256 lastActivity;          // Last validation timestamp
        bool isActive;                 // Current active status
        uint256 authorityScore;        // Composite authority score
        string bbtmAddress;            // BBTM network address
    }
    
    struct ConsensusMetrics {
        uint256 networkThroughput;     // Current TPS
        uint256 averageLatency;        // Average transaction latency (ms)
        uint256 validatorCount;        // Active validator count
        uint256 consensusRound;        // Current consensus round
        uint256 lastBlockTime;         // Last block timestamp
        bool networkHealthy;           // Overall network health
    }
    
    struct ReputationUpdate {
        address user;
        uint256 oldReputation;
        uint256 newReputation;
        string updateReason;
        uint256 timestamp;
        bytes32 bbtmTxHash;
        bool verified;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 💾 STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    mapping(address => AuthorityNode) public validators;
    mapping(string => address) public bbtmToSolidity;
    mapping(bytes32 => ReputationUpdate) public reputationUpdates;
    mapping(address => uint256) public userAuthorityScores;
    
    address[] public activeValidators;
    ConsensusMetrics public networkMetrics;
    
    // Contract references
    address public solidaryHub;
    address public reputationManager;
    address public impactLogger;
    
    // Network statistics
    uint256 public totalValidatedTransactions;
    uint256 public totalAuthorityNodes;
    uint256 public networkUptime;
    uint256 public deploymentTime;
    
    // Events
    event ValidatorRegistered(address indexed validator, string bbtmAddress, uint256 initialAuthority);
    event AuthorityScoreUpdated(address indexed validator, uint256 oldScore, uint256 newScore);
    event ConsensusRoundCompleted(uint256 indexed round, uint256 throughput, uint256 latency);
    event ReputationSyncedFromBBTM(address indexed user, uint256 newReputation, bytes32 bbtmTxHash);
    event NetworkHealthUpdated(bool healthy, uint256 throughput, uint256 validators);
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏗️ INITIALIZATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        address admin,
        address _solidaryHub,
        address _reputationManager,
        address _impactLogger
    ) public initializer {
        __AccessControl_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(BBTM_VALIDATOR, admin);
        _grantRole(AUTHORITY_MANAGER, admin);
        _grantRole(CONSENSUS_ORACLE, admin);
        _grantRole(NETWORK_MONITOR, admin);
        
        solidaryHub = _solidaryHub;
        reputationManager = _reputationManager;
        impactLogger = _impactLogger;
        
        deploymentTime = block.timestamp;
        
        // Initialize network metrics
        networkMetrics = ConsensusMetrics({
            networkThroughput: 0,
            averageLatency: 0,
            validatorCount: 0,
            consensusRound: 0,
            lastBlockTime: block.timestamp,
            networkHealthy: true
        });
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏛️ AUTHORITY PROTOCOL IMPLEMENTATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Registra un nuovo validator nel protocollo di autorevolezza BBTM
     * @param bbtmAddress Indirizzo del validator sulla rete BBTM
     * @param technicalSkill Score abilità tecniche (0-1000)
     * @param socialReputation Score reputazione sociale (0-1000)
     * @param stakingAmount Quantità di stake economico
     */
    function registerValidator(
        string memory bbtmAddress,
        uint256 technicalSkill,
        uint256 socialReputation,
        uint256 stakingAmount
    ) external {
        require(bytes(bbtmAddress).length > 0, "Invalid BBTM address");
        require(validators[msg.sender].validator == address(0), "Validator already registered");
        require(bbtmToSolidity[bbtmAddress] == address(0), "BBTM address already used");
        
        // Ottieni impact score dal sistema Solidary
        uint256 impactScore = _getImpactScore(msg.sender);
        
        // Calcola authority score composto
        uint256 authorityScore = calculateAuthorityScore(
            technicalSkill,
            socialReputation,
            impactScore,
            stakingAmount
        );
        
        require(authorityScore >= AUTHORITY_THRESHOLD, "Insufficient authority score");
        
        validators[msg.sender] = AuthorityNode({
            validator: msg.sender,
            technicalSkill: technicalSkill,
            socialReputation: socialReputation,
            impactContribution: impactScore,
            stakingPower: stakingAmount,
            validatedBlocks: 0,
            lastActivity: block.timestamp,
            isActive: true,
            authorityScore: authorityScore,
            bbtmAddress: bbtmAddress
        });
        
        bbtmToSolidity[bbtmAddress] = msg.sender;
        activeValidators.push(msg.sender);
        totalAuthorityNodes++;
        networkMetrics.validatorCount++;
        
        emit ValidatorRegistered(msg.sender, bbtmAddress, authorityScore);
    }
    
    /**
     * @dev Calcola l'authority score composto secondo il protocollo BBTM
     * @param technical Abilità tecniche (peso 30%)
     * @param social Reputazione sociale (peso 40%)
     * @param impact Contributo impatto (peso 30%)
     * @param staking Moltiplicatore di staking
     */
    function calculateAuthorityScore(
        uint256 technical,
        uint256 social,
        uint256 impact,
        uint256 staking
    ) public pure returns (uint256) {
        // Formula: (technical*0.3 + social*0.4 + impact*0.3) * stakingMultiplier
        uint256 baseScore = (technical * 30 + social * 40 + impact * 30) / 100;
        uint256 stakingMultiplier = (staking / 1000) + 100; // Min 1x, scales with stake
        return (baseScore * stakingMultiplier) / 100;
    }
    
    /**
     * @dev Aggiorna le metriche di consenso dalla rete BBTM
     * @param throughput TPS attuale
     * @param latency Latenza media in ms
     * @param round Round di consenso corrente
     */
    function updateConsensusMetrics(
        uint256 throughput,
        uint256 latency,
        uint256 round
    ) external onlyRole(CONSENSUS_ORACLE) {
        networkMetrics.networkThroughput = throughput;
        networkMetrics.averageLatency = latency;
        networkMetrics.consensusRound = round;
        networkMetrics.lastBlockTime = block.timestamp;
        
        // Valuta health della rete
        networkMetrics.networkHealthy = (
            throughput > 1000 && // Min 1k TPS
            latency < 500 &&     // Max 500ms latency
            networkMetrics.validatorCount >= 3 // Min 3 validators
        );
        
        emit ConsensusRoundCompleted(round, throughput, latency);
        emit NetworkHealthUpdated(networkMetrics.networkHealthy, throughput, networkMetrics.validatorCount);
    }
    
    /**
     * @dev Sincronizza aggiornamento reputazione dalla rete BBTM
     * @param user Utente da aggiornare
     * @param newReputation Nuovo score reputazione
     * @param bbtmTxHash Hash transazione BBTM
     * @param updateReason Ragione dell'aggiornamento
     */
    function syncReputationFromBBTM(
        address user,
        uint256 newReputation,
        bytes32 bbtmTxHash,
        string memory updateReason
    ) external onlyRole(BBTM_VALIDATOR) {
        require(user != address(0), "Invalid user address");
        require(newReputation <= 10000, "Reputation score too high"); // Max 10k
        
        uint256 oldReputation = userAuthorityScores[user];
        
        ReputationUpdate memory update = ReputationUpdate({
            user: user,
            oldReputation: oldReputation,
            newReputation: newReputation,
            updateReason: updateReason,
            timestamp: block.timestamp,
            bbtmTxHash: bbtmTxHash,
            verified: true
        });
        
        reputationUpdates[bbtmTxHash] = update;
        userAuthorityScores[user] = newReputation;
        
        // Propaga al ReputationManager di Solidary
        _propagateReputationUpdate(user, newReputation);
        
        emit ReputationSyncedFromBBTM(user, newReputation, bbtmTxHash);
    }
    
    /**
     * @dev Registra validazione di un blocco BBTM
     * @param validator Validator che ha validato
     * @param blockHash Hash del blocco validato
     * @param transactionCount Numero transazioni nel blocco
     */
    function recordBlockValidation(
        address validator,
        bytes32 blockHash,
        uint256 transactionCount
    ) external onlyRole(BBTM_VALIDATOR) {
        require(validators[validator].isActive, "Validator not active");
        
        validators[validator].validatedBlocks++;
        validators[validator].lastActivity = block.timestamp;
        totalValidatedTransactions += transactionCount;
        
        // Aumenta leggermente l'authority score per attività
        uint256 bonus = transactionCount / 100; // 1 punto per 100 transazioni
        validators[validator].authorityScore += bonus;
        
        emit AuthorityScoreUpdated(
            validator, 
            validators[validator].authorityScore - bonus,
            validators[validator].authorityScore
        );
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔧 UTILITY & INTERNAL FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function _getImpactScore(address user) internal view returns (uint256) {
        // Integrazione con ImpactLogger per ottenere score impatto
        (bool success, bytes memory data) = impactLogger.staticcall(
            abi.encodeWithSignature("getUserImpactScore(address)", user)
        );
        
        if (success && data.length > 0) {
            return abi.decode(data, (uint256));
        }
        return 0; // Default se non disponibile
    }
    
    function _propagateReputationUpdate(address user, uint256 newReputation) internal {
        (bool success, ) = reputationManager.call(
            abi.encodeWithSignature(
                "updateCrossChainReputation(address,uint256)",
                user,
                newReputation
            )
        );
        // Non revert se fallisce, per evitare blocchi
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 👁️ VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Ottiene informazioni validator
     */
    function getValidator(address validator) external view returns (AuthorityNode memory) {
        return validators[validator];
    }
    
    /**
     * @dev Ottiene metriche rete BBTM
     */
    function getNetworkMetrics() external view returns (ConsensusMetrics memory) {
        return networkMetrics;
    }
    
    /**
     * @dev Ottiene uptime della rete
     */
    function getNetworkUptime() external view returns (uint256) {
        return block.timestamp - deploymentTime;
    }
    
    /**
     * @dev Verifica se la rete è performante
     */
    function isHighPerformance() external view returns (bool) {
        return (
            networkMetrics.networkThroughput >= 50000 && // 50k+ TPS
            networkMetrics.averageLatency <= 200 &&      // <200ms latency
            networkMetrics.networkHealthy
        );
    }
    
    /**
     * @dev Ottiene lista validator attivi
     */
    function getActiveValidators() external view returns (address[] memory) {
        return activeValidators;
    }
    
    /**
     * @dev Calcola performance score della rete
     */
    function calculateNetworkPerformanceScore() external view returns (uint256) {
        if (!networkMetrics.networkHealthy) return 0;
        
        uint256 throughputScore = (networkMetrics.networkThroughput * 100) / MAX_TPS;
        uint256 latencyScore = networkMetrics.averageLatency > 0 ? 
            (1000 - networkMetrics.averageLatency) / 10 : 100;
        uint256 validatorScore = (networkMetrics.validatorCount * 20); // 20 points per validator
        
        return (throughputScore + latencyScore + validatorScore) / 3;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // ⚙️ ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Aggiorna authority score di un validator
     */
    function updateValidatorAuthority(address validator, uint256 newScore) 
        external onlyRole(AUTHORITY_MANAGER) {
        require(validators[validator].validator != address(0), "Validator not found");
        
        uint256 oldScore = validators[validator].authorityScore;
        validators[validator].authorityScore = newScore;
        
        emit AuthorityScoreUpdated(validator, oldScore, newScore);
    }
    
    /**
     * @dev Attiva/disattiva validator
     */
    function setValidatorStatus(address validator, bool active) 
        external onlyRole(AUTHORITY_MANAGER) {
        require(validators[validator].validator != address(0), "Validator not found");
        validators[validator].isActive = active;
        
        if (active) {
            validators[validator].lastActivity = block.timestamp;
        }
    }
    
    /**
     * @dev Aggiorna riferimenti contratti
     */
    function updateContractReferences(
        address _solidaryHub,
        address _reputationManager,
        address _impactLogger
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_solidaryHub != address(0)) solidaryHub = _solidaryHub;
        if (_reputationManager != address(0)) reputationManager = _reputationManager;
        if (_impactLogger != address(0)) impactLogger = _impactLogger;
    }
}