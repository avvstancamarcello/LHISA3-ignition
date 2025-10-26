// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/**
 * UniversalMultiChainOrchestratorV2
 *
 * - Orchestratore multi-chain per l'ecosistema Solidary
 * - Collega OceanMangaNFT (ERC1155), LunaComicsFT (ERC20), SolidaryMetrics
 * - Espone API attese da SolidaryMetrics: nftPlanetContract, ftSatelliteContract,
 *   totalQuantumLinks, totalStellarValue, getStorageConfig
 * - Routing intelligente cross-chain (BBTM, Algorand, Ethereum, Polygon)
 * - Analytics & storage pointer su IPFS (simulati on-chain — carica reale off-chain)
 *
 * NOTE: NON memorizzare segreti reali on-chain. I campi stringa sono placeholder.
 */

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

interface ILunaComicsFTReadable {
    function totalSupply() external view returns (uint256);
    function lunarGravity() external view returns (uint256);
}

interface IOceanMangaNFTReadable {
    // placeholder per futuri getter di sola lettura
}

contract UniversalMultiChainOrchestratorV2 is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    using StringsUpgradeable for uint256;

    // ─────────────────────────────────────────────────────────────────────────────
    // 🔐 ROLES & CONSTANTS
    // ─────────────────────────────────────────────────────────────────────────────
    bytes32 public constant CHAIN_MANAGER         = keccak256("CHAIN_MANAGER");
    bytes32 public constant ROUTE_OPTIMIZER       = keccak256("ROUTE_OPTIMIZER");
    bytes32 public constant CROSS_CHAIN_VALIDATOR = keccak256("CROSS_CHAIN_VALIDATOR");
    bytes32 public constant EMERGENCY_COORDINATOR = keccak256("EMERGENCY_COORDINATOR");
    bytes32 public constant GOVERNOR_ROLE         = keccak256("GOVERNOR_ROLE");     // config ecosistema
    bytes32 public constant MANAGER_ROLE          = keccak256("MANAGER_ROLE");      // registri operativi

    // Supported Chains
    uint256 public constant ETHEREUM_CHAIN = 1;
    uint256 public constant POLYGON_CHAIN  = 137;
    uint256 public constant ALGORAND_CHAIN = 999;
    uint256 public constant BBTM_CHAIN     = 888;

    // Soglie (indicative)
    uint256 public constant HIGH_URGENCY_THRESHOLD   = 100;   // ms
    uint256 public constant MEDIUM_URGENCY_THRESHOLD = 5000;  // ms
    uint256 public constant LOW_COST_THRESHOLD       = 1e15;  // 0.001 ETH eq.

    // ─────────────────────────────────────────────────────────────────────────────
    // 📊 MULTI-CHAIN ARCHITECTURE
    // ─────────────────────────────────────────────────────────────────────────────
    struct ChainConfiguration {
        uint256 chainId;
        string  chainName;
        address bridgeContract;
        address nativeToken;
        uint256 averageLatency;   // ms
        uint256 averageCost;      // wei eq.
        uint256 throughputTPS;
        uint256 energyEfficiency; // punteggio (più basso meglio)
        bool    isActive;
        bool    isHealthy;
        uint256 lastHealthCheck;
    }

    struct RouteOptimization {
        uint256 sourceChain;
        uint256 targetChain;
        string  transactionType;  // "payment","governance","reputation","emergency",...
        uint256 urgencyLevel;     // 1=LOW..4=CRITICAL
        uint256 amount;
        address user;
        uint256 recommendedChain;
        uint256 estimatedLatency;
        uint256 estimatedCost;
        string  reasoning;
    }

    struct CrossChainTransaction {
        bytes32 txId;
        address initiator;
        uint256 sourceChain;
        uint256 targetChain;
        address sourceContract;
        address targetContract;
        bytes   payload;
        uint256 timestamp;
        uint256 completedTimestamp;
        bool    isCompleted;
        bool    isFailed;
        string  status;
    }

    struct BridgePerformanceSnapshot {
        uint256 timestamp;
        uint256 chainId;
        uint256 successRate; // per mille o basis points, a scelta
        uint256 latency;
        uint256 cost;
        uint256 throughput;  // placeholder
        string  cid;         // IPFS CID con dettaglio esteso
    }

    // Quantum Links (NFT↔FT)
    struct QuantumLink {
        address user;
        uint256 tokenId;
        uint256 ftAmount;
        uint256 timestamp;
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 💾 STATE VARIABLES
    // ─────────────────────────────────────────────────────────────────────────────
    mapping(uint256 => ChainConfiguration) public chainConfigs;
    mapping(bytes32  => CrossChainTransaction) public crossChainTxs;

    // preferenze e routing
    mapping(address => uint256) public userPreferredChains;
    mapping(string  => uint256) public transactionTypeOptimalChains;
    uint256[] public supportedChains;

    // bridge principali
    address public algorandBridge;
    address public ethereumPolygonBridge;
    address public bbtmInterface;

    // hub e moduli Solidary
    address public solidaryHub;
    address public reputationManager;

    // statistica
    uint256 public totalCrossChainTxs;
    uint256 public totalVolumeUSD;
    uint256 public totalGasSaved;
    uint256 public averageLatencyMs;

    // ecosistema Solidary (collegamenti)
    address public oceanMangaNFT;    // nftPlanetContract
    address public lunaComicsFT;     // ftSatelliteContract
    address public solidaryMetrics;  // facoltativo (solo tracking)

    // storage config (placeholder: non usare secrets reali)
    string public pinataJWT;
    string public nftStorageAPIKey;

    // analytics & IPFS pointers
    mapping(bytes32 => string) public transactionDataCIDs;    // txId -> CID
    mapping(uint256 => string[]) public chainAnalyticsCIDs;   // chain -> CIDs
    mapping(address => string[]) public userCrossChainHistoryCIDs; // utente -> CIDs

    // sostenibilità & performance
    uint256 public totalCarbonSaved;
    uint256 public totalEcoFriendlyTxs;
    uint256 public totalBBTMHighPerfTxs;
    BridgePerformanceSnapshot[] public bridgePerformanceHistory;

    // quantum links registry
    QuantumLink[] private _quantumLinks;
    uint256 private _totalStellarValueOverride; // opzionale: override manuale

    // ─────────────────────────────────────────────────────────────────────────────
    // 📣 EVENTS
    // ─────────────────────────────────────────────────────────────────────────────
    event ChainConfigured(uint256 indexed chainId, string chainName, address bridge);
    event RouteOptimized(bytes32 indexed txId, uint256 sourceChain, uint256 recommendedChain, string reasoning);
    event CrossChainTxInitiated(bytes32 indexed txId, address indexed user, uint256 sourceChain, uint256 targetChain);
    event CrossChainTxCompleted(bytes32 indexed txId, uint256 latency, uint256 cost);
    event ChainHealthUpdated(uint256 indexed chainId, bool healthy, uint256 latency, uint256 throughput);
    event EmergencyRoutingActivated(uint256 fromChain, uint256 toChain, string reason);

    event EcosystemLinked(address nftPlanet, address ftSatellite, address metrics);
    event StorageConfigured(bool setNftStorageKey, bool setPinataJwt);
    event CrossChainAnalyticsStored(bytes32 indexed txId, string analyticsCID);
    event CarbonFootprintCalculated(uint256 footprint, uint256 offset, string methodologyCID);
    event BridgePerformanceLogged(uint256 chainId, uint256 successRate, string performanceCID);
    event EcoRoutingSelected(bytes32 txId, uint256 carbonSaved, string reasoning);
    event QuantumLinkRecorded(uint256 indexed linkId, address indexed user, uint256 tokenId, uint256 ftAmount);

    // ─────────────────────────────────────────────────────────────────────────────
    // 🏗️ INITIALIZATION
    // ─────────────────────────────────────────────────────────────────────────────

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
        address _bbtmInterface,
        address _oceanMangaNFT,
        address _lunaComicsFT,
        address _solidaryMetrics
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CHAIN_MANAGER, admin);
        _grantRole(ROUTE_OPTIMIZER, admin);
        _grantRole(CROSS_CHAIN_VALIDATOR, admin);
        _grantRole(EMERGENCY_COORDINATOR, admin);
        _grantRole(GOVERNOR_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);

        solidaryHub          = _solidaryHub;
        reputationManager    = _reputationManager;
        algorandBridge       = _algorandBridge;
        ethereumPolygonBridge= _ethereumPolygonBridge;
        bbtmInterface        = _bbtmInterface;

        oceanMangaNFT   = _oceanMangaNFT;
        lunaComicsFT    = _lunaComicsFT;
        solidaryMetrics = _solidaryMetrics;

        _initializeChainConfigurations();
        _setOptimalTransactionTypes();

        emit EcosystemLinked(oceanMangaNFT, lunaComicsFT, solidaryMetrics);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // ─────────────────────────────────────────────────────────────────────────────
    // 🔧 CHAIN CONFIG
    // ─────────────────────────────────────────────────────────────────────────────

    function _initializeChainConfigurations() internal {
        chainConfigs[BBTM_CHAIN] = ChainConfiguration({
            chainId: BBTM_CHAIN,
            chainName: "BBTM Network",
            bridgeContract: bbtmInterface,
            nativeToken: address(0),
            averageLatency: 100,
            averageCost: 1e12,
            throughputTPS: 100000,
            energyEfficiency: 1,
            isActive: true,
            isHealthy: true,
            lastHealthCheck: block.timestamp
        });

        chainConfigs[ALGORAND_CHAIN] = ChainConfiguration({
            chainId: ALGORAND_CHAIN,
            chainName: "Algorand",
            bridgeContract: algorandBridge,
            nativeToken: address(0),
            averageLatency: 4500,
            averageCost: 1e15,
            throughputTPS: 6000,
            energyEfficiency: 2,
            isActive: true,
            isHealthy: true,
            lastHealthCheck: block.timestamp
        });

        chainConfigs[ETHEREUM_CHAIN] = ChainConfiguration({
            chainId: ETHEREUM_CHAIN,
            chainName: "Ethereum",
            bridgeContract: ethereumPolygonBridge,
            nativeToken: address(0),
            averageLatency: 15000,
            averageCost: 5e16,
            throughputTPS: 15,
            energyEfficiency: 8,
            isActive: true,
            isHealthy: true,
            lastHealthCheck: block.timestamp
        });

        chainConfigs[POLYGON_CHAIN] = ChainConfiguration({
            chainId: POLYGON_CHAIN,
            chainName: "Polygon",
            bridgeContract: ethereumPolygonBridge,
            nativeToken: address(0),
            averageLatency: 2000,
            averageCost: 1e16,
            throughputTPS: 7000,
            energyEfficiency: 4,
            isActive: true,
            isHealthy: true,
            lastHealthCheck: block.timestamp
        });

        supportedChains = [BBTM_CHAIN, ALGORAND_CHAIN, ETHEREUM_CHAIN, POLYGON_CHAIN];

        emit ChainConfigured(BBTM_CHAIN, "BBTM Network", bbtmInterface);
        emit ChainConfigured(ALGORAND_CHAIN, "Algorand",     algorandBridge);
        emit ChainConfigured(ETHEREUM_CHAIN, "Ethereum",     ethereumPolygonBridge);
        emit ChainConfigured(POLYGON_CHAIN,  "Polygon",      ethereumPolygonBridge);
    }

    function _setOptimalTransactionTypes() internal {
        transactionTypeOptimalChains["emergency"]      = BBTM_CHAIN;
        transactionTypeOptimalChains["high_frequency"] = BBTM_CHAIN;
        transactionTypeOptimalChains["eco_friendly"]   = ALGORAND_CHAIN;
        transactionTypeOptimalChains["governance"]     = POLYGON_CHAIN;
        transactionTypeOptimalChains["security"]       = ETHEREUM_CHAIN;
        transactionTypeOptimalChains["payment"]        = ALGORAND_CHAIN;
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 🧠 INTELLIGENT ROUTING
    // ─────────────────────────────────────────────────────────────────────────────

    function selectOptimalChain(
        string memory transactionType,
        uint256 amount,
        uint256 urgencyLevel,
        address user
    ) public view returns (ChainConfiguration memory) {
        // 1) Emergenza critica
        if (urgencyLevel == 4 || keccak256(bytes(transactionType)) == keccak256("emergency")) {
            return chainConfigs[BBTM_CHAIN];
        }
        // 2) Alta urgenza + importo basso
        if (urgencyLevel == 3 && amount < LOW_COST_THRESHOLD) {
            return chainConfigs[BBTM_CHAIN];
        }
        // 3) Eco-friendly / payment
        if (
            keccak256(bytes(transactionType)) == keccak256("eco_friendly") ||
            keccak256(bytes(transactionType)) == keccak256("payment")
        ) {
            return chainConfigs[ALGORAND_CHAIN];
        }
        // 4) Governance
        if (keccak256(bytes(transactionType)) == keccak256("governance")) {
            return chainConfigs[POLYGON_CHAIN];
        }
        // 5) High-value security
        if (amount > 1e18 && urgencyLevel <= 2) {
            return chainConfigs[ETHEREUM_CHAIN];
        }
        // 6) Preferenza utente
        if (userPreferredChains[user] != 0) {
            ChainConfiguration memory userChain = chainConfigs[userPreferredChains[user]];
            if (userChain.isActive && userChain.isHealthy) {
                return userChain;
            }
        }
        // 7) Default: Algorand
        return chainConfigs[ALGORAND_CHAIN];
    }

    function generateRouteOptimization(
        uint256 sourceChain,
        string memory transactionType,
        uint256 urgencyLevel,
        uint256 amount,
        address user
    ) public view returns (RouteOptimization memory) {
        ChainConfiguration memory optimal = selectOptimalChain(transactionType, amount, urgencyLevel, user);

        string memory reasoning;
        if (optimal.chainId == BBTM_CHAIN)      reasoning = "Selected BBTM for ultra-high performance";
        else if (optimal.chainId == ALGORAND_CHAIN) reasoning = "Selected Algorand for eco-efficiency";
        else if (optimal.chainId == POLYGON_CHAIN)  reasoning = "Selected Polygon for balanced performance";
        else                                         reasoning = "Selected Ethereum for maximum security";

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

    // Esegue la transazione cross-chain con logging analytics (CID simulato)
    function executeCrossChainTransaction(
        string memory transactionType,
        bytes memory payload,
        uint256 urgencyLevel,
        uint256 amount
    ) external returns (bytes32) {
        RouteOptimization memory route = generateRouteOptimization(
            block.chainid, transactionType, urgencyLevel, amount, msg.sender
        );

        bytes32 txId = keccak256(abi.encodePacked(
            msg.sender, transactionType, block.timestamp, totalCrossChainTxs
        ));

        CrossChainTransaction memory basicTx = CrossChainTransaction({
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

        crossChainTxs[txId] = basicTx;
        totalCrossChainTxs++;

        // Carbon footprint (semplificato)
        uint256 carbonFootprint = _calculateCarbonFootprint(route.recommendedChain, amount);

        if (route.recommendedChain == ALGORAND_CHAIN) {
            totalEcoFriendlyTxs++;
            totalCarbonSaved += carbonFootprint;
            emit EcoRoutingSelected(txId, carbonFootprint, "Algorand eco-friendly selection");
        }
        if (route.recommendedChain == BBTM_CHAIN) {
            totalBBTMHighPerfTxs++;
        }

        // Salva analytics su “IPFS” (simulato)
        string memory analyticsCID = _storeTransactionAnalytics(txId, basicTx, route, carbonFootprint);

        // update (eventi)
        emit RouteOptimized(txId, block.chainid, route.recommendedChain, route.reasoning);
        emit CrossChainTxInitiated(txId, msg.sender, block.chainid, route.recommendedChain);
        emit CrossChainAnalyticsStored(txId, analyticsCID);

        return txId;
    }

    function completeCrossChainTransaction(bytes32 txId)
        external
        onlyRole(CROSS_CHAIN_VALIDATOR)
    {
        CrossChainTransaction storage txData = crossChainTxs[txId];
        require(!txData.isCompleted, "Already completed");

        txData.isCompleted = true;
        txData.completedTimestamp = block.timestamp;
        txData.status = "COMPLETED";

        uint256 latency = block.timestamp - txData.timestamp;
        averageLatencyMs = (averageLatencyMs + latency) / 2;

        emit CrossChainTxCompleted(txId, latency, 0);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 📊 MONITORING & HEALTH
    // ─────────────────────────────────────────────────────────────────────────────

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

    function activateEmergencyRouting(
        uint256 fromChain,
        uint256 toChain,
        string memory reason
    ) external onlyRole(EMERGENCY_COORDINATOR) {
        chainConfigs[fromChain].isActive  = false;
        chainConfigs[fromChain].isHealthy = false;
        emit EmergencyRoutingActivated(fromChain, toChain, reason);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 👁️ VIEW & ADMIN
    // ─────────────────────────────────────────────────────────────────────────────

    function getChainConfiguration(uint256 chainId) external view returns (ChainConfiguration memory) {
        return chainConfigs[chainId];
    }

    function getCrossChainTransaction(bytes32 txId) external view returns (CrossChainTransaction memory) {
        return crossChainTxs[txId];
    }

    function getSupportedChains() external view returns (uint256[] memory) {
        return supportedChains;
    }

    function getEcosystemStats() external view returns (uint256 totalTxs, uint256 volumeUSD, uint256 gasSaved, uint256 avgLatency) {
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

    function setUserPreferredChain(address user, uint256 chainId) external onlyRole(CHAIN_MANAGER) {
        userPreferredChains[user] = chainId;
    }

    function updateBridgeContracts(
        address _algorandBridge,
        address _ethereumPolygonBridge,
        address _bbtmInterface
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_algorandBridge       != address(0)) algorandBridge        = _algorandBridge;
        if (_ethereumPolygonBridge!= address(0)) ethereumPolygonBridge = _ethereumPolygonBridge;
        if (_bbtmInterface        != address(0)) bbtmInterface         = _bbtmInterface;
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 🌐 STORAGE (placeholders) & ECOSYSTEM WIRING
    // ─────────────────────────────────────────────────────────────────────────────

    function configureStorage(string memory _nftStorageKey, string memory _pinataJWT)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        nftStorageAPIKey = _nftStorageKey;
        pinataJWT        = _pinataJWT;
        emit StorageConfigured(bytes(_nftStorageKey).length > 0, bytes(_pinataJWT).length > 0);
    }

    function setSolidaryEcosystem(
        address _nftPlanet,
        address _ftSatellite,
        address _metrics
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        oceanMangaNFT   = _nftPlanet;
        lunaComicsFT    = _ftSatellite;
        solidaryMetrics = _metrics;
        emit EcosystemLinked(oceanMangaNFT, lunaComicsFT, solidaryMetrics);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 🔗 SOLIDARY METRICS – REQUIRED API
    // ─────────────────────────────────────────────────────────────────────────────

    function nftPlanetContract() external view returns (address) {
        return oceanMangaNFT;
    }

    function ftSatelliteContract() external view returns (address) {
        return lunaComicsFT;
    }

    function totalQuantumLinks() external view returns (uint256) {
        return _quantumLinks.length;
    }

    function totalStellarValue() external view returns (uint256) {
        if (_totalStellarValueOverride > 0) return _totalStellarValueOverride;
        address ft = lunaComicsFT;
        if (ft == address(0)) return 0;
        uint256 supply  = ILunaComicsFTReadable(ft).totalSupply();
        uint256 gravity = ILunaComicsFTReadable(ft).lunarGravity();
        if (gravity == 0) return 0;
        return (supply * gravity) / 1e18;
    }

    function getStorageConfig() external view returns (string memory, string memory) {
        return (nftStorageAPIKey, pinataJWT);
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 🔭 QUANTUM LINK REGISTRY
    // ─────────────────────────────────────────────────────────────────────────────

    function recordQuantumLink(address user, uint256 tokenId, uint256 ftAmount)
        external
        onlyRole(MANAGER_ROLE)
        returns (uint256 linkId)
    {
        _quantumLinks.push(QuantumLink({
            user: user,
            tokenId: tokenId,
            ftAmount: ftAmount,
            timestamp: block.timestamp
        }));
        linkId = _quantumLinks.length - 1;
        emit QuantumLinkRecorded(linkId, user, tokenId, ftAmount);
    }

    function getQuantumLink(uint256 index) external view returns (address user, uint256 tokenId, uint256 ftAmount, uint256 timestamp) {
        require(index < _quantumLinks.length, "Index out of range");
        QuantumLink memory ql = _quantumLinks[index];
        return (ql.user, ql.tokenId, ql.ftAmount, ql.timestamp);
    }

    function quantumLinksCount() external view returns (uint256) {
        return _quantumLinks.length;
    }

    function setTotalStellarValueOverride(uint256 valueOrZero) external onlyRole(GOVERNOR_ROLE) {
        _totalStellarValueOverride = valueOrZero;
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 📊 ANALYTICS & IPFS (simulazione on-chain)
    // ─────────────────────────────────────────────────────────────────────────────

    function _storeTransactionAnalytics(
        bytes32 txId,
        CrossChainTransaction memory txData,
        RouteOptimization memory route,
        uint256 carbonFootprint
    ) internal returns (string memory) {
        bytes memory analyticsData = abi.encodePacked(
            '{"txId":"', _bytes32ToHexString(txId),
            '","initiator":"', _addressToString(txData.initiator),
            '","sourceChain":', _u(txData.sourceChain),
            ',"targetChain":', _u(txData.targetChain),
            ',"transactionType":"', route.transactionType,
            '","urgencyLevel":', _u(route.urgencyLevel),
            ',"amount":', _u(route.amount),
            ',"estimatedLatency":', _u(route.estimatedLatency),
            ',"estimatedCost":', _u(route.estimatedCost),
            ',"carbonFootprint":', _u(carbonFootprint),
            ',"timestamp":', _u(block.timestamp),
            ',"routingReasoning":"', route.reasoning,
            '","chainName":"', chainConfigs[route.recommendedChain].chainName,
            '"}'
        );

        string memory cid = _uploadToIPFS(analyticsData);
        transactionDataCIDs[txId] = cid;
        chainAnalyticsCIDs[txData.targetChain].push(cid);
        userCrossChainHistoryCIDs[txData.initiator].push(cid);
        return cid;
    }

    function logBridgePerformance(
        uint256 chainId,
        uint256 successRate,
        uint256 latency,
        uint256 cost
    ) external onlyRole(CHAIN_MANAGER) {
        bytes memory performanceData = abi.encodePacked(
            '{"chainId":', _u(chainId),
            ',"successRate":', _u(successRate),
            ',"latency":', _u(latency),
            ',"cost":', _u(cost),
            ',"timestamp":', _u(block.timestamp),
            ',"totalTxs":', _u(totalCrossChainTxs),
            '}'
        );

        string memory cid = _uploadToIPFS(performanceData);
        bridgePerformanceHistory.push(BridgePerformanceSnapshot({
            timestamp: block.timestamp,
            chainId: chainId,
            successRate: successRate,
            latency: latency,
            cost: cost,
            throughput: 0,
            cid: cid
        }));

        emit BridgePerformanceLogged(chainId, successRate, cid);
    }

    function getUserCrossChainHistory(address user) external view returns (string[] memory cids) {
        return userCrossChainHistoryCIDs[user];
    }

    function getChainPerformanceHistory(uint256 chainId, uint256 limit) external view returns (BridgePerformanceSnapshot[] memory) {
        // filtra fino a "limit" elementi per chainId
        uint256 count;
        for (uint256 i = 0; i < bridgePerformanceHistory.length; i++) {
            if (bridgePerformanceHistory[i].chainId == chainId) count++;
        }
        uint256 resultCount = (limit == 0 || limit > count) ? count : limit;
        BridgePerformanceSnapshot[] memory result = new BridgePerformanceSnapshot[](resultCount);
        uint256 idx;
        for (uint256 i = 0; i < bridgePerformanceHistory.length && idx < resultCount; i++) {
            if (bridgePerformanceHistory[i].chainId == chainId) {
                result[idx] = bridgePerformanceHistory[i];
                idx++;
            }
        }
        return result;
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 🌱 CARBON FOOTPRINT (semplificato)
    // ─────────────────────────────────────────────────────────────────────────────

    function _calculateCarbonFootprint(uint256 chainId, uint256 amount) internal view returns (uint256) {
        ChainConfiguration memory config = chainConfigs[chainId];
        uint256 baseFootprint   = config.energyEfficiency;
        uint256 amountMultiplier= (amount > 1e18) ? 2 : 1;
        uint256 footprint       = baseFootprint * amountMultiplier;
        if (chainId == ALGORAND_CHAIN) footprint = footprint / 2;
        if (chainId == BBTM_CHAIN)     footprint = footprint / 4;
        return footprint;
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 🧰 IPFS SIM (on-chain)
    // ─────────────────────────────────────────────────────────────────────────────

    function _uploadToIPFS(bytes memory data) internal view returns (string memory cid) {
        bytes32 hash = keccak256(abi.encodePacked(data, block.timestamp, totalCrossChainTxs));
        // pseudo-CID esadecimale
        cid = string(abi.encodePacked("simulated:ipfs:", _bytes32ToHexString(hash)));
        return cid;
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 🔎 UTILS
    // ─────────────────────────────────────────────────────────────────────────────

    function _bytes32ToHexString(bytes32 v) internal pure returns (string memory) {
        bytes memory s = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            bytes1 b = v[i];
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) % 16);
            s[2*i]   = _nibble(hi);
            s[2*i+1] = _nibble(lo);
        }
        return string(s);
    }

    function _nibble(bytes1 b) internal pure returns (bytes1 c) {
        uint8 v = uint8(b);
        if (v < 10) return bytes1(v + 0x30);
        return bytes1(v + 0x57);
    }

    function _addressToString(address a) internal pure returns (string memory) {
        return StringsUpgradeable.toHexString(uint256(uint160(a)), 20);
    }

    function _u(uint256 x) internal pure returns (string memory) {
        return x.toString();
    }
}
