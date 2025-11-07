// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca, Firenze, Italy

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title AlgorandSolidaryBridge
 * @dev Bridge per integrazione nativa con Algorand blockchain
 * @notice Gestisce sincronizzazione reputazione e transazioni cross-chain
 */
contract AlgorandSolidaryBridge is Initializable, AccessControlUpgradeable {
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔐 ROLES & CONSTANTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    bytes32 public constant ALGORAND_VALIDATOR = keccak256("ALGORAND_VALIDATOR");
    bytes32 public constant BRIDGE_OPERATOR = keccak256("BRIDGE_OPERATOR");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    
    // Algorand specific constants
    uint256 public constant ALGORAND_BLOCK_TIME = 4500; // 4.5 seconds in milliseconds
    uint256 public constant ALGO_DECIMALS = 6; // ALGO has 6 decimals
    uint256 public constant SLDY_DECIMALS = 18; // SLDY has 18 decimals
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    struct AlgorandUser {
        string algorandAddress;      // Algorand wallet address  
        address solidaryAddress;     // Ethereum address
        uint256 reputationScore;     // Cross-chain reputation
        uint256 algoBalance;         // ALGO balance on Algorand
        uint256 lastSyncBlock;       // Last synchronization block
        bool isVerified;             // KYC verification status
    }
    
    struct CrossChainTransaction {
        bytes32 algorandTxnId;       // Algorand transaction ID
        address solidaryUser;        // Solidary user address
        uint256 amount;              // Amount in micro-ALGOs
        string transactionType;      // "reputation", "payment", "governance"
        uint256 timestamp;           // Transaction timestamp
        bool processed;              // Processing status
        bytes signature;             // Validator signature
    }
    
    // Mappings
    mapping(address => AlgorandUser) public solidaryToAlgorand;
    mapping(string => address) public algorandToSolidary;
    mapping(bytes32 => CrossChainTransaction) public crossChainTxns;
    mapping(bytes32 => bool) public processedTxns;
    mapping(address => uint256) public crossChainReputation;
    
    // Contracts references
    address public reputationManager;
    address public impactLogger;
    address public solidaryToken;
    address public solidaryHub;
    
    // Bridge state
    uint256 public totalBridgedUsers;
    uint256 public totalCrossChainTxns;
    uint256 public conversionRate; // ALGO to SLDY rate (scaled by 1e18)
    bool public bridgeActive;
    
    // Events
    event UserBridged(address indexed solidaryUser, string algorandAddress);
    event CrossChainSync(bytes32 indexed txnId, address indexed user, string syncType);
    event ReputationSynced(address indexed user, uint256 oldScore, uint256 newScore);
    event AlgorandPaymentProcessed(bytes32 indexed txnId, address indexed user, uint256 amount);
    event ConversionRateUpdated(uint256 oldRate, uint256 newRate);
    
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
        address _solidaryToken,
        address _solidaryHub
    ) public initializer {
        __AccessControl_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(BRIDGE_OPERATOR, admin);
        _grantRole(ALGORAND_VALIDATOR, admin);
        
        reputationManager = _reputationManager;
        impactLogger = _impactLogger;
        solidaryToken = _solidaryToken;
        solidaryHub = _solidaryHub;
        
        // Initial conversion rate: 1 ALGO = 100 SLDY
        conversionRate = 100 * 1e18;
        bridgeActive = true;
        totalBridgedUsers = 0;
        totalCrossChainTxns = 0;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌉 BRIDGE OPERATIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Collega un utente Solidary con il suo indirizzo Algorand
     * @param algorandAddress Indirizzo wallet Algorand dell'utente
     */
    function bridgeUser(string memory algorandAddress) external {
        require(bytes(algorandAddress).length > 0, "Invalid Algorand address");
        require(
            bytes(solidaryToAlgorand[msg.sender].algorandAddress).length == 0,
            "User already bridged"
        );
        require(algorandToSolidary[algorandAddress] == address(0), "Algorand address already used");
        
        solidaryToAlgorand[msg.sender] = AlgorandUser({
            algorandAddress: algorandAddress,
            solidaryAddress: msg.sender,
            reputationScore: 0,
            algoBalance: 0,
            lastSyncBlock: block.number,
            isVerified: false
        });
        
        algorandToSolidary[algorandAddress] = msg.sender;
        totalBridgedUsers++;
        
        emit UserBridged(msg.sender, algorandAddress);
    }
    
    /**
     * @dev Sincronizza reputazione da Algorand a Solidary
     * @param algorandTxnId ID transazione Algorand
     * @param solidaryUser Indirizzo utente Solidary
     * @param reputationScore Nuovo score reputazione
     * @param signature Firma del validator
     */
    function syncReputationFromAlgorand(
        bytes32 algorandTxnId,
        address solidaryUser,
        uint256 reputationScore,
        bytes memory signature
    ) external onlyRole(ALGORAND_VALIDATOR) {
        require(!processedTxns[algorandTxnId], "Transaction already processed");
        require(solidaryUser != address(0), "Invalid user address");
        
        // Verifica che l'utente sia bridgato
        require(
            bytes(solidaryToAlgorand[solidaryUser].algorandAddress).length > 0,
            "User not bridged"
        );
        
        // Memorizza la transazione cross-chain
        crossChainTxns[algorandTxnId] = CrossChainTransaction({
            algorandTxnId: algorandTxnId,
            solidaryUser: solidaryUser,
            amount: reputationScore,
            transactionType: "reputation",
            timestamp: block.timestamp,
            processed: true,
            signature: signature
        });
        
        processedTxns[algorandTxnId] = true;
        
        // Aggiorna reputazione locale
        uint256 oldScore = crossChainReputation[solidaryUser];
        crossChainReputation[solidaryUser] = reputationScore;
        solidaryToAlgorand[solidaryUser].reputationScore = reputationScore;
        
        // Propaga al ReputationManager
        (bool success, ) = reputationManager.call(
            abi.encodeWithSignature(
                "updateCrossChainReputation(address,uint256)",
                solidaryUser,
                reputationScore
            )
        );
        require(success, "Reputation update failed");
        
        totalCrossChainTxns++;
        
        emit CrossChainSync(algorandTxnId, solidaryUser, "reputation");
        emit ReputationSynced(solidaryUser, oldScore, reputationScore);
    }
    
    /**
     * @dev Processa pagamento da Algorand
     * @param algorandTxnId ID transazione Algorand
     * @param solidaryUser Indirizzo utente che riceve
     * @param algoAmount Quantità ALGO (in micro-ALGO)
     * @param signature Firma validator
     */
    function processAlgorandPayment(
        bytes32 algorandTxnId,
        address solidaryUser,
        uint256 algoAmount,
        bytes memory signature
    ) external onlyRole(ALGORAND_VALIDATOR) {
        require(!processedTxns[algorandTxnId], "Transaction already processed");
        require(solidaryUser != address(0), "Invalid user address");
        require(algoAmount > 0, "Amount must be positive");
        
        // Converti micro-ALGO in SLDY
        uint256 sldyAmount = convertAlgoToSldy(algoAmount);
        
        // Memorizza transazione
        crossChainTxns[algorandTxnId] = CrossChainTransaction({
            algorandTxnId: algorandTxnId,
            solidaryUser: solidaryUser,
            amount: algoAmount,
            transactionType: "payment",
            timestamp: block.timestamp,
            processed: true,
            signature: signature
        });
        
        processedTxns[algorandTxnId] = true;
        
        // Minta SLDY equivalenti
        (bool success, ) = solidaryToken.call(
            abi.encodeWithSignature(
                "mint(address,uint256)",
                solidaryUser,
                sldyAmount
            )
        );
        require(success, "SLDY minting failed");
        
        // Log dell'impatto
        (success, ) = impactLogger.call(
            abi.encodeWithSignature(
                "logImpact(string,string,uint256)",
                "cross_chain_payment",
                "Payment from Algorand network",
                sldyAmount
            )
        );
        
        totalCrossChainTxns++;
        
        emit AlgorandPaymentProcessed(algorandTxnId, solidaryUser, algoAmount);
        emit CrossChainSync(algorandTxnId, solidaryUser, "payment");
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔄 CONVERSION & UTILITY FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Converte micro-ALGO in SLDY
     * @param microAlgoAmount Quantità in micro-ALGO (1 ALGO = 1,000,000 micro-ALGO)
     * @return sldyAmount Quantità equivalente in SLDY
     */
    function convertAlgoToSldy(uint256 microAlgoAmount) public view returns (uint256) {
        // microAlgo to ALGO: divide by 1e6
        // ALGO to SLDY: multiply by conversionRate  
        // Adjust for SLDY decimals (18) vs ALGO decimals (6)
        return (microAlgoAmount * conversionRate) / 1e6;
    }
    
    /**
     * @dev Converte SLDY in micro-ALGO
     * @param sldyAmount Quantità SLDY
     * @return microAlgoAmount Quantità equivalente in micro-ALGO
     */
    function convertSldyToAlgo(uint256 sldyAmount) public view returns (uint256) {
        return (sldyAmount * 1e6) / conversionRate;
    }
    
    /**
     * @dev Aggiorna il tasso di conversione ALGO/SLDY
     * @param newRate Nuovo tasso (scaled by 1e18)
     */
    function updateConversionRate(uint256 newRate) external onlyRole(BRIDGE_OPERATOR) {
        require(newRate > 0, "Rate must be positive");
        uint256 oldRate = conversionRate;
        conversionRate = newRate;
        emit ConversionRateUpdated(oldRate, newRate);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 👁️ VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Ottiene informazioni utente bridgato
     */
    function getBridgedUser(address solidaryUser) 
        external view returns (AlgorandUser memory) {
        return solidaryToAlgorand[solidaryUser];
    }
    
    /**
     * @dev Ottiene indirizzo Solidary da indirizzo Algorand
     */
    function getSolidaryUser(string memory algorandAddress) 
        external view returns (address) {
        return algorandToSolidary[algorandAddress];
    }
    
    /**
     * @dev Verifica se una transazione è stata processata
     */
    function isTransactionProcessed(bytes32 txnId) external view returns (bool) {
        return processedTxns[txnId];
    }
    
    /**
     * @dev Ottiene statistiche del bridge
     */
    function getBridgeStats() external view returns (
        uint256 users,
        uint256 transactions,
        uint256 rate,
        bool active
    ) {
        return (totalBridgedUsers, totalCrossChainTxns, conversionRate, bridgeActive);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // ⚙️ ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Attiva/disattiva il bridge
     */
    function setBridgeStatus(bool active) external onlyRole(BRIDGE_OPERATOR) {
        bridgeActive = active;
    }
    
    /**
     * @dev Aggiorna i contratti di riferimento
     */
    function updateContractReferences(
        address _reputationManager,
        address _impactLogger,
        address _solidaryToken,
        address _solidaryHub
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_reputationManager != address(0)) reputationManager = _reputationManager;
        if (_impactLogger != address(0)) impactLogger = _impactLogger;
        if (_solidaryToken != address(0)) solidaryToken = _solidaryToken;
        if (_solidaryHub != address(0)) solidaryHub = _solidaryHub;
    }
    
    /**
     * @dev Verifica un utente come KYC completato
     */
    function verifyUser(address solidaryUser) external onlyRole(BRIDGE_OPERATOR) {
        require(
            bytes(solidaryToAlgorand[solidaryUser].algorandAddress).length > 0,
            "User not bridged"
        );
        solidaryToAlgorand[solidaryUser].isVerified = true;
    }
}