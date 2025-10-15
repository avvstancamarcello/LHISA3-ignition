// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca – Lawyer, Italy (Florence)
// © Copyright Marcello Stanca, Firenze, Italy

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title UniversalMultiChainOrchestrator
 * @dev Orchestratore centrale per tutte le interazioni cross-chain dell'ecosistema Solidary
 * @notice Coordina BBTM, Algorand, Ethereum, Polygon e gestisce routing intelligente
 */
contract UniversalMultiChainOrchestrator is Initializable, AccessControlUpgradeable {
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔐 ROLES & CONSTANTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    bytes32 public constant CHAIN_MANAGER = keccak256("CHAIN_MANAGER");
    bytes32 public constant ROUTE_OPTIMIZER = keccak256("ROUTE_OPTIMIZER");
    bytes32 public constant CROSS_CHAIN_VALIDATOR = keccak256("CROSS_CHAIN_VALIDATOR");
    bytes32 public constant EMERGENCY_COORDINATOR = keccak256("EMERGENCY_COORDINATOR");
    
    // Supported Chains
    uint256 public constant ETHEREUM_CHAIN = 1;
    uint256 public constant POLYGON_CHAIN = 137;
    uint256 public constant ALGORAND_CHAIN = 999;
    uint256 public constant BBTM_CHAIN = 888;
    
    // Performance Thresholds
    uint256 public constant HIGH_URGENCY_THRESHOLD = 100; // 100ms
    uint256 public constant MEDIUM_URGENCY_THRESHOLD = 5000; // 5 seconds
    uint256 public constant LOW_COST_THRESHOLD = 1e15; // 0.001 ETH equivalent
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 MULTI-CHAIN ARCHITECTURE
    // ═══════════════════════════════════════════════════════════════════════════════
    
    struct ChainConfiguration {
        uint256 chainId;
        string chainName;
        address bridgeContract;
        address nativeToken;
        uint256 averageLatency;      // in milliseconds
        uint256 averageCost;         // in wei equivalent
        uint256 throughputTPS;       // transactions per second
        uint256 energyEfficiency;    // carbon footprint score (lower is better)
        bool isActive;
        bool isHealthy;
        uint256 lastHealthCheck;
    }
    
    struct RouteOptimization {
        uint256 sourceChain;
        uint256 targetChain;
        string transactionType;      // "payment", "governance", "reputation", "emergency"
        uint256 urgencyLevel;        // 1=LOW, 2=MEDIUM, 3=HIGH, 4=CRITICAL
        uint256 amount;
        address user;
        uint256 recommendedChain;
        uint256 estimatedLatency;
        uint256 estimatedCost;
        string reasoning;
    }
    
    struct CrossChainTransaction {
        bytes32 txId;
        address initiator;
        uint256 sourceChain;
        uint256 targetChain;
        address sourceContract;
        address targetContract;
        bytes payload;
        uint256 timestamp;
        uint256 completedTimestamp;
        bool isCompleted;
        bool isFailed;
        string status;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 💾 STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    mapping(uint256 => ChainConfiguration) public chainConfigs;
    mapping(bytes32 => CrossChainTransaction) public crossChainTxs;
    mapping(address => uint256) public userPreferredChains;
    mapping(string => uint256) public transactionTypeOptimalChains;
    
    uint256[] public supportedChains;
    
    // Bridge contracts
    address public algorandBridge;
    address public ethereumPolygonBridge;
    address public bbtmInterface;
    address public solidaryHub;
    address public reputationManager;
    
    // Statistics
    uint256 public totalCrossChainTxs;
    uint256 public totalVolumeUSD;
    uint256 public totalGasSaved;
    uint256 public averageLatencyMs;
    
    // Events
    event ChainConfigured(uint256 indexed chainId, string chainName, address bridge);
    event RouteOptimized(bytes32 indexed txId, uint256 sourceChain, uint256 recommendedChain, string reasoning);
    event CrossChainTxInitiated(bytes32 indexed txId, address indexed user, uint256 sourceChain, uint256 targetChain);
    event CrossChainTxCompleted(bytes32 indexed txId, uint256 latency, uint256 cost);
    event ChainHealthUpdated(uint256 indexed chainId, bool healthy, uint256 latency, uint256 throughput);
    event EmergencyRoutingActivated(uint256 fromChain, uint256 toChain, string reason);
    
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
        address _algorandBridge,
        address _ethereumPolygonBridge,
        address _bbtmInterface
    ) public initializer {
        __AccessControl_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CHAIN_MANAGER, admin);
        _grantRole(ROUTE_OPTIMIZER, admin);
        _grantRole(CROSS_CHAIN_VALIDATOR, admin);
        _grantRole(EMERGENCY_COORDINATOR, admin);
        
        solidaryHub = _solidaryHub;
        reputationManager = _reputationManager;
        algorandBridge = _algorandBridge;
        ethereumPolygonBridge = _ethereumPolygonBridge;
        bbtmInterface = _bbtmInterface;
        
        _initializeChainConfigurations();
        _setOptimalTransactionTypes();
    }
    
    function _initializeChainConfigurations() internal {
        // BBTM - Ultra High Performance
        chainConfigs[BBTM_CHAIN] = ChainConfiguration({
            chainId: BBTM_CHAIN,
            chainName: "BBTM Network",
            bridgeContract: bbtmInterface,
            nativeToken: address(0), // TBD
            averageLatency: 100,     // 100ms
            averageCost: 1e12,       // 0.000001 ETH equivalent
            throughputTPS: 100000,   // 100k TPS
            energyEfficiency: 1,     // Best efficiency
            isActive: true,
            isHealthy: true,
            lastHealthCheck: block.timestamp
        });
        
        // Algorand - High Performance + Eco-Friendly
        chainConfigs[ALGORAND_CHAIN] = ChainConfiguration({
            chainId: ALGORAND_CHAIN,
            chainName: "Algorand",
            bridgeContract: algorandBridge,
            nativeToken: address(0), // ALGO token address
            averageLatency: 4500,    // 4.5 seconds
            averageCost: 1e15,       // 0.001 ETH equivalent
            throughputTPS: 6000,     // 6k TPS
            energyEfficiency: 2,     // Carbon negative
            isActive: true,
            isHealthy: true,
            lastHealthCheck: block.timestamp
        });
        
        // Ethereum - Security + Decentralization
        chainConfigs[ETHEREUM_CHAIN] = ChainConfiguration({
            chainId: ETHEREUM_CHAIN,
            chainName: "Ethereum",
            bridgeContract: ethereumPolygonBridge,
            nativeToken: address(0), // POL/MATIC token
            averageLatency: 15000,   // 15 seconds
            averageCost: 5e16,       // 0.05 ETH equivalent
            throughputTPS: 15,       // 15 TPS
            energyEfficiency: 8,     // Higher energy usage
            isActive: true,
            isHealthy: true,
            lastHealthCheck: block.timestamp
        });
        
        // Polygon - Balanced Performance
        chainConfigs[POLYGON_CHAIN] = ChainConfiguration({
            chainId: POLYGON_CHAIN,
            chainName: "Polygon",
            bridgeContract: ethereumPolygonBridge,
            nativeToken: address(0), // PET token
            averageLatency: 2000,    // 2 seconds
            averageCost: 1e16,       // 0.01 ETH equivalent
            throughputTPS: 7000,     // 7k TPS
            energyEfficiency: 4,     // Good efficiency
            isActive: true,
            isHealthy: true,
            lastHealthCheck: block.timestamp
        });
        
        supportedChains = [BBTM_CHAIN, ALGORAND_CHAIN, ETHEREUM_CHAIN, POLYGON_CHAIN];
    }
    
    function _setOptimalTransactionTypes() internal {
        transactionTypeOptimalChains["emergency"] = BBTM_CHAIN;      // Ultra-fast for emergencies
        transactionTypeOptimalChains["high_frequency"] = BBTM_CHAIN;  // High-freq trading/micro-tx
        transactionTypeOptimalChains["eco_friendly"] = ALGORAND_CHAIN; // Sustainable operations
        transactionTypeOptimalChains["governance"] = POLYGON_CHAIN;   // Balanced for voting
        transactionTypeOptimalChains["security"] = ETHEREUM_CHAIN;    // High-value transactions
        transactionTypeOptimalChains["payment"] = ALGORAND_CHAIN;     // Cost-effective payments
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🧠 INTELLIGENT ROUTING ALGORITHM
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Seleziona la chain ottimale basata su parametri intelligenti
     * @param transactionType Tipo transazione ("payment", "governance", "emergency", etc.)
     * @param amount Valore della transazione
     * @param urgencyLevel Livello urgenza (1-4)
     * @param user Utente che inizia la transazione
     * @return ChainConfiguration Configurazione della chain ottimale
     */
    function selectOptimalChain(
        string memory transactionType,
        uint256 amount,
        uint256 urgencyLevel,
        address user
    ) public view returns (ChainConfiguration memory) {
        
        // 1. Emergenze critiche -> BBTM
        if (urgencyLevel == 4 || keccak256(bytes(transactionType)) == keccak256("emergency")) {
            return chainConfigs[BBTM_CHAIN];
        }
        
        // 2. Alta urgenza + piccoli importi -> BBTM
        if (urgencyLevel == 3 && amount < LOW_COST_THRESHOLD) {
            return chainConfigs[BBTM_CHAIN];
        }
        
        // 3. Transazioni eco-friendly -> Algorand
        if (keccak256(bytes(transactionType)) == keccak256("eco_friendly") || 
            keccak256(bytes(transactionType)) == keccak256("payment")) {
            return chainConfigs[ALGORAND_CHAIN];
        }
        
        // 4. Governance -> Polygon (PET)
        if (keccak256(bytes(transactionType)) == keccak256("governance")) {
            return chainConfigs[POLYGON_CHAIN];
        }
        
        // 5. High-value security -> Ethereum
        if (amount > 1e18 && urgencyLevel <= 2) { // > 1 ETH equivalent
            return chainConfigs[ETHEREUM_CHAIN];
        }
        
        // 6. Check user preference
        if (userPreferredChains[user] != 0) {
            ChainConfiguration memory userChain = chainConfigs[userPreferredChains[user]];
            if (userChain.isActive && userChain.isHealthy) {
                return userChain;
            }
        }
        
        // 7. Default: Algorand (best balance)
        return chainConfigs[ALGORAND_CHAIN];
    }
    
    /**
     * @dev Genera ottimizzazione completa del route
     * @param sourceChain Chain di origine
     * @param transactionType Tipo transazione
     * @param urgencyLevel Livello urgenza
     * @param amount Valore transazione
     * @param user Utente
     * @return RouteOptimization Ottimizzazione completa del percorso
     */
    function generateRouteOptimization(
        uint256 sourceChain,
        string memory transactionType,
        uint256 urgencyLevel,
        uint256 amount,
        address user
    ) public view returns (RouteOptimization memory) {
        
        ChainConfiguration memory optimal = selectOptimalChain(transactionType, amount, urgencyLevel, user);
        
        string memory reasoning;
        if (optimal.chainId == BBTM_CHAIN) {
            reasoning = "Selected BBTM for ultra-high performance and minimal latency";
        } else if (optimal.chainId == ALGORAND_CHAIN) {
            reasoning = "Selected Algorand for eco-efficiency and cost optimization";
        } else if (optimal.chainId == POLYGON_CHAIN) {
            reasoning = "Selected Polygon for balanced performance and PET ecosystem";
        } else {
            reasoning = "Selected Ethereum for maximum security and decentralization";
        }
        
        return RouteOptimization({
            sourceChain: sourceChain,
            targetChain: optimal.chainId,
            transactionType: transactionType,
            urgencyLevel: urgencyLevel,
            amount: amount,
            user: user,
            recommendedChain: optimal.chainId,
            estimatedLatency: optimal.averageLatency,
            estimatedCost: optimal.averageCost,
            reasoning: reasoning
        });
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔄 CROSS-CHAIN EXECUTION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Esegue una transazione cross-chain ottimizzata
     * @param transactionType Tipo di transazione
     * @param payload Dati della transazione
     * @param urgencyLevel Livello di urgenza
     * @param amount Valore della transazione
     */
    function executeCrossChainTransaction(
        string memory transactionType,
        bytes memory payload,
        uint256 urgencyLevel,
        uint256 amount
    ) external returns (bytes32) {
        
        RouteOptimization memory route = generateRouteOptimization(
            block.chainid,
            transactionType,
            urgencyLevel,
            amount,
            msg.sender
        );
        
        bytes32 txId = keccak256(abi.encodePacked(
            msg.sender,
            transactionType,
            block.timestamp,
            totalCrossChainTxs
        ));
        
        crossChainTxs[txId] = CrossChainTransaction({
            txId: txId,
            initiator: msg.sender,
            sourceChain: block.chainid,
            targetChain: route.recommendedChain,
            sourceContract: address(this),
            targetContract: chainConfigs[route.recommendedChain].bridgeContract,
            payload: payload,
            timestamp: block.timestamp,
            completedTimestamp: 0,
            isCompleted: false,
            isFailed: false,
            status: "INITIATED"
        });
        
        totalCrossChainTxs++;
        
        emit RouteOptimized(txId, block.chainid, route.recommendedChain, route.reasoning);
        emit CrossChainTxInitiated(txId, msg.sender, block.chainid, route.recommendedChain);
        
        return txId;
    }
    
    /**
     * @dev Completa una transazione cross-chain
     * @param txId ID della transazione
     */
    function completeCrossChainTransaction(bytes32 txId) 
        external 
        onlyRole(CROSS_CHAIN_VALIDATOR) 
    {
        CrossChainTransaction storage txData = crossChainTxs[txId];
        require(!txData.isCompleted, "Transaction already completed");
        
        txData.isCompleted = true;
        txData.completedTimestamp = block.timestamp;
        txData.status = "COMPLETED";
        
        uint256 latency = block.timestamp - txData.timestamp;
        averageLatencyMs = (averageLatencyMs + latency) / 2;
        
        emit CrossChainTxCompleted(txId, latency, 0);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 MONITORING & HEALTH CHECKS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Aggiorna lo stato di salute di una chain
     * @param chainId ID della chain
     * @param isHealthy Stato di salute
     * @param latency Latenza corrente
     * @param throughput Throughput corrente
     */
    function updateChainHealth(
        uint256 chainId,
        bool isHealthy,
        uint256 latency,
        uint256 throughput
    ) external onlyRole(CHAIN_MANAGER) {
        ChainConfiguration storage config = chainConfigs[chainId];
        config.isHealthy = isHealthy;
        config.averageLatency = latency;
        config.throughputTPS = throughput;
        config.lastHealthCheck = block.timestamp;
        
        emit ChainHealthUpdated(chainId, isHealthy, latency, throughput);
    }
    
    /**
     * @dev Attiva routing di emergenza
     * @param fromChain Chain da evitare
     * @param toChain Chain alternativa
     * @param reason Motivo dell'emergenza
     */
    function activateEmergencyRouting(
        uint256 fromChain,
        uint256 toChain,
        string memory reason
    ) external onlyRole(EMERGENCY_COORDINATOR) {
        chainConfigs[fromChain].isActive = false;
        chainConfigs[fromChain].isHealthy = false;
        
        emit EmergencyRoutingActivated(fromChain, toChain, reason);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 👁️ VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function getChainConfiguration(uint256 chainId) 
        external 
        view 
        returns (ChainConfiguration memory) 
    {
        return chainConfigs[chainId];
    }
    
    function getCrossChainTransaction(bytes32 txId) 
        external 
        view 
        returns (CrossChainTransaction memory) 
    {
        return crossChainTxs[txId];
    }
    
    function getSupportedChains() external view returns (uint256[] memory) {
        return supportedChains;
    }
    
    function getEcosystemStats() external view returns (
        uint256 totalTxs,
        uint256 volumeUSD,
        uint256 gasSaved,
        uint256 avgLatency
    ) {
        return (totalCrossChainTxs, totalVolumeUSD, totalGasSaved, averageLatencyMs);
    }
    
    function calculateCarbonFootprint() external view returns (uint256) {
        uint256 totalFootprint = 0;
        for (uint256 i = 0; i < supportedChains.length; i++) {
            ChainConfiguration memory config = chainConfigs[supportedChains[i]];
            totalFootprint += config.energyEfficiency;
        }
        return totalFootprint;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // ⚙️ ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function setUserPreferredChain(address user, uint256 chainId) 
        external 
        onlyRole(CHAIN_MANAGER) 
    {
        userPreferredChains[user] = chainId;
    }
    
    function updateBridgeContracts(
        address _algorandBridge,
        address _ethereumPolygonBridge,
        address _bbtmInterface
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_algorandBridge != address(0)) algorandBridge = _algorandBridge;
        if (_ethereumPolygonBridge != address(0)) ethereumPolygonBridge = _ethereumPolygonBridge;
        if (_bbtmInterface != address(0)) bbtmInterface = _bbtmInterface;
    }
}
