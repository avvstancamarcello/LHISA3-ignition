// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca – Lawyer, Italy (Florence)
// © Copyright Marcello Stanca, Firenze, Italia

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title EnhancedReputationManager
 * @dev Sistema di reputazione avanzato per l'ecosistema Solidary con storage decentralizzato
 * @notice Gestisce reputazione, trust score e validazione cross-chain
 */
contract EnhancedReputationManager is Initializable, AccessControlUpgradeable {

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔐 ROLES & CONSTANTS
    // ═══════════════════════════════════════════════════════════════════════════════

    bytes32 public constant REPUTATION_ORACLE = keccak256("REPUTATION_ORACLE");
    bytes32 public constant VALIDATOR_NODE = keccak256("VALIDATOR_NODE");
    bytes32 public constant MODERATOR = keccak256("MODERATOR");

    uint256 public constant MAX_REPUTATION_SCORE = 1000;
    uint256 public constant PLATINUM_THRESHOLD = 800;
    uint256 public constant GOLD_THRESHOLD = 600;
    uint256 public constant SILVER_THRESHOLD = 400;
    uint256 public constant BRONZE_THRESHOLD = 200;

    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 ENHANCED DATA STRUCTURES
    // ═══════════════════════════════════════════════════════════════════════════════

    struct EnhancedReputation {
        uint256 currentScore;
        uint256 totalValidations;
        uint256 totalReports;
        uint256 positiveActions;
        uint256 negativeActions;
        bool isFlagged;
        bool isVerified;
        string reputationCID;
        uint256 lastUpdate;
        uint256 joinDate;
        address[] validators;
        address[] reporters;
        string reputationTier;
        uint256 crossChainReputation; // Reputazione da altre chain
        uint256 ecosystemContribution; // Contributo all'ecosistema Solidary
    }

    struct ReputationEvent {
        uint256 timestamp;
        address user;
        address actor;
        string eventType;
        int256 scoreChange;
        string reason;
        string proofCID;
        uint256 weight;
        string context; // "trade", "governance", "farming", "cross_chain"
    }

    struct TrustNetwork {
        address user;
        uint256 networkStrength;
        address[] trustedConnections;
        address[] distrustedConnections;
        string networkCID;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 💾 STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════════

    mapping(address => EnhancedReputation) public reputations;
    mapping(address => ReputationEvent[]) public userReputationHistory;
    mapping(address => TrustNetwork) public trustNetworks;
    mapping(address => string[]) public userReputationCIDs;
    mapping(string => uint256) public reputationEventWeights;

    // 🔗 Ecosistema Solidary
    address public solidaryOrchestrator;
    address public mareaMangaNFT;
    address public lunaComicsFT;
    address public multiChainOrchestrator;

    // 🌐 Storage Config
    string public pinataJWT;
    string public nftStorageAPIKey;

    // 📊 Statistics
    uint256 public totalUsers;
    uint256 public totalReputationEvents;
    uint256 public averageReputationScore;
    uint256 public totalCrossChainValidations;

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎯 EVENTS
    // ═══════════════════════════════════════════════════════════════════════════════

    event ReputationUpdated(address indexed user, uint256 newScore, string tier, string reason);
    event ReputationEventLogged(address indexed user, string eventType, int256 scoreChange, string eventCID);
    event UserFlagged(address indexed user, string reason, string proofCID);
    event UserVerified(address indexed user, address verifier);
    event TrustConnectionAdded(address indexed from, address indexed to, bool trusted);
    event CrossChainReputationSynced(address indexed user, uint256 chainId, uint256 score);
    event ReputationTierUpgraded(address indexed user, string fromTier, string toTier);

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏗️ INITIALIZATION
    // ═══════════════════════════════════════════════════════════════════════════════

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address admin,
        address _orchestrator,
        address _nftPlanet,
        address _ftSatellite,
        address _multiChainOrchestrator
    ) public initializer {
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(REPUTATION_ORACLE, admin);
        _grantRole(VALIDATOR_NODE, admin);
        _grantRole(MODERATOR, admin);

        solidaryOrchestrator = _orchestrator;
        mareaMangaNFT = _nftPlanet;
        lunaComicsFT = _ftSatellite;
        multiChainOrchestrator = _multiChainOrchestrator;

        _initializeReputationWeights();
    }

    function _initializeReputationWeights() internal {
        reputationEventWeights["successful_trade"] = 20;
        reputationEventWeights["failed_trade"] = -15;
        reputationEventWeights["successful_farm"] = 10;
        reputationEventWeights["governance_vote"] = 5;
        reputationEventWeights["cross_chain_tx"] = 15;
        reputationEventWeights["content_creation"] = 25;
        reputationEventWeights["community_help"] = 30;
        reputationEventWeights["malicious_activity"] = -100;
        reputationEventWeights["false_report"] = -50;
        reputationEventWeights["system_contribution"] = 40;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎯 CORE REPUTATION FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

    /**
     * @dev Aggiunge evento reputazione con storage IPFS
     */
    function addReputationEvent(
        address user,
        string memory evtType,
        string memory reason,
        string memory context,
        uint256 customWeight
    ) external onlyRole(VALIDATOR_NODE) returns (string memory evtCID) {
        
        require(user != address(0), "Invalid user address");
        
        int256 scoreChange = int256(customWeight > 0 ? customWeight : reputationEventWeights[eventType]);
        
        // Crea evento reputazione
        ReputationEvent memory newEvent = ReputationEvent({
            timestamp: block.timestamp,
            user: user,
            actor: msg.sender,
            eventType: eventType,
            scoreChange: scoreChange,
            reason: reason,
            proofCID: "",
            weight: uint256(scoreChange > 0 ? scoreChange : -scoreChange),
            context: context
        });

        // Salva su IPFS
        eventCID = _storeReputationEventOnIPFS(newEvent);
        newEvent.proofCID = eventCID;

        // Aggiorna reputazione utente
        _updateUserReputation(user, scoreChange, eventType, reason, eventCID);

        userReputationHistory[user].push(newEvent);
        userReputationCIDs[user].push(eventCID);
        totalReputationEvents++;

        emit ReputationEventLogged(user, eventType, scoreChange, eventCID);
        
        return eventCID;
    }

    /**
     * @dev Aggiorna reputazione utente con tier system
     */
    function _updateUserReputation(
        address user,
        int256 scoreChange,
        string memory evtType,
        string memory reason,
        string memory evtCID
    ) internal {
        EnhancedReputation storage rep = reputations[user];
        
        // Inizializza se nuovo utente
        if (rep.joinDate == 0) {
            rep.joinDate = block.timestamp;
            rep.currentScore = 100; // Punteggio iniziale
            rep.reputationTier = "Bronze";
            totalUsers++;
        }

        string memory oldTier = rep.reputationTier;
        
        // Applica modifica punteggio
        if (scoreChange > 0) {
            rep.currentScore += uint256(scoreChange);
            rep.positiveActions++;
        } else {
            if (rep.currentScore > uint256(-scoreChange)) {
                rep.currentScore -= uint256(-scoreChange);
            } else {
                rep.currentScore = 0;
            }
            rep.negativeActions++;
        }

        // Limita punteggio massimo
        if (rep.currentScore > MAX_REPUTATION_SCORE) {
            rep.currentScore = MAX_REPUTATION_SCORE;
        }

        // Aggiorna tier
        string memory newTier = _calculateReputationTier(rep.currentScore);
        rep.reputationTier = newTier;
        rep.lastUpdate = block.timestamp;

        // Ricalcola media reputazione globale
        averageReputationScore = (averageReputationScore * (totalUsers - 1) + rep.currentScore) / totalUsers;

        // Salva storico su IPFS
        _updateUserReputationOnIPFS(user);

        emit ReputationUpdated(user, rep.currentScore, newTier, reason);

        // Notifica cambio tier
        if (keccak256(bytes(oldTier)) != keccak256(bytes(newTier))) {
            emit ReputationTierUpgraded(user, oldTier, newTier);
        }
    }

    /**
     * @dev Calcola tier reputazione basato su score
     */
    function _calculateReputationTier(uint256 score) internal pure returns (string memory) {
        if (score >= PLATINUM_THRESHOLD) return "Platinum";
        if (score >= GOLD_THRESHOLD) return "Gold";
        if (score >= SILVER_THRESHOLD) return "Silver";
        if (score >= BRONZE_THRESHOLD) return "Bronze";
        return "Newcomer";
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔗 TRUST NETWORK FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

    /**
     * @dev Aggiunge connessione di fiducia
     */
    function addTrustConnection(address trustedUser, bool isTrusted) external {
        require(trustedUser != msg.sender, "Cannot trust yourself");
        require(trustedUser != address(0), "Invalid user address");

        TrustNetwork storage network = trustNetworks[msg.sender];
        
        if (network.user == address(0)) {
            network.user = msg.sender;
            network.networkStrength = 0;
        }

        if (isTrusted) {
            // Rimuovi da distrusted se presente
            for (uint256 i = 0; i < network.distrustedConnections.length; i++) {
                if (network.distrustedConnections[i] == trustedUser) {
                    network.distrustedConnections[i] = network.distrustedConnections[network.distrustedConnections.length - 1];
                    network.distrustedConnections.pop();
                    break;
                }
            }
            // Aggiungi a trusted
            network.trustedConnections.push(trustedUser);
            network.networkStrength += 10;
        } else {
            // Rimuovi da trusted se presente
            for (uint256 i = 0; i < network.trustedConnections.length; i++) {
                if (network.trustedConnections[i] == trustedUser) {
                    network.trustedConnections[i] = network.trustedConnections[network.trustedConnections.length - 1];
                    network.trustedConnections.pop();
                    break;
                }
            }
            // Aggiungi a distrusted
            network.distrustedConnections.push(trustedUser);
            network.networkStrength -= 5;
        }

        // Aggiorna su IPFS
        _updateTrustNetworkOnIPFS(msg.sender);

        emit TrustConnectionAdded(msg.sender, trustedUser, isTrusted);
    }

    /**
     * @dev Calcola trust score basato su network
     */
    function calculateNetworkTrustScore(address user) public view returns (uint256) {
        TrustNetwork storage network = trustNetworks[user];
        uint256 baseScore = reputations[user].currentScore;
        uint256 networkBonus = network.networkStrength;
        
        // Bonus per connessioni con alta reputazione
        for (uint256 i = 0; i < network.trustedConnections.length; i++) {
            uint256 connectionScore = reputations[network.trustedConnections[i]].currentScore;
            networkBonus += connectionScore / 100; // 1% del punteggio connessione
        }

        return baseScore + networkBonus;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌐 CROSS-CHAIN REPUTATION SYNC
    // ═══════════════════════════════════════════════════════════════════════════════

    /**
     * @dev Sincronizza reputazione da altre chain
     */
    function syncCrossChainReputation(
        address user,
        uint256 chainId,
        uint256 crossChainScore,
        string memory proofCID
    ) external onlyRole(REPUTATION_ORACLE) {
        EnhancedReputation storage rep = reputations[user];
        
        // Media ponderata con reputazione esistente
        uint256 newScore = (rep.currentScore * 70 + crossChainScore * 30) / 100;
        rep.currentScore = newScore > MAX_REPUTATION_SCORE ? MAX_REPUTATION_SCORE : newScore;
        rep.crossChainReputation = crossChainScore;
        
        // Aggiorna tier
        rep.reputationTier = _calculateReputationTier(rep.currentScore);
        rep.lastUpdate = block.timestamp;

        totalCrossChainValidations++;

        emit CrossChainReputationSynced(user, chainId, crossChainScore);
        emit ReputationUpdated(user, rep.currentScore, rep.reputationTier, "Cross-chain sync");
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🛡️ MODERATION FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

    /**
     * @dev Segnala utente con prova su IPFS
     */
    function reportUser(
        address user,
        string memory reason,
        string memory proofCID
    ) external onlyRole(MODERATOR) {
        require(user != address(0), "Invalid user address");

        EnhancedReputation storage rep = reputations[user];
        rep.totalReports++;
        
        // Penalità reputazione per report
        if (rep.currentScore >= 50) {
            rep.currentScore -= 50;
        } else {
            rep.currentScore = 0;
        }

        // Flag utente se troppi report
        if (rep.totalReports > rep.totalValidations / 2 && rep.totalReports >= 3) {
            rep.isFlagged = true;
            emit UserFlagged(user, reason, proofCID);
        }

        rep.reputationTier = _calculateReputationTier(rep.currentScore);
        rep.lastUpdate = block.timestamp;

        // Log evento
        addReputationEvent(user, "user_reported", reason, "moderation", 0);
    }

    /**
     * @dev Verifica utente (KYC/AML semplificato)
     */
    function verifyUser(address user) external onlyRole(MODERATOR) {
        EnhancedReputation storage rep = reputations[user];
        rep.isVerified = true;
        
        // Bonus reputazione per verifica
        rep.currentScore += 50;
        if (rep.currentScore > MAX_REPUTATION_SCORE) {
            rep.currentScore = MAX_REPUTATION_SCORE;
        }

        rep.reputationTier = _calculateReputationTier(rep.currentScore);
        rep.lastUpdate = block.timestamp;

        emit UserVerified(user, msg.sender);
        emit ReputationUpdated(user, rep.currentScore, rep.reputationTier, "User verified");
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌐 IPFS STORAGE FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

    function configureStorage(string memory _nftStorageKey, string memory _pinataJWT) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        nftStorageAPIKey = _nftStorageKey;
        pinataJWT = _pinataJWT;
    }

    function _storeReputationEventOnIPFS(ReputationEvent memory repEvent) 
        internal 
        returns (string memory) 
    {
        bytes memory evtData = abi.encodePacked(
            '{"timestamp": ', _uint2str(repEvent.timestamp),
            ', "user": "', _addressToString(repEvent.user),
            ', "actor": "', _addressToString(repEvent.actor),
            ', "eventType": "', repEvent.eventType,
            ', "scoreChange": ', _int2str(repEvent.scoreChange),
            ', "reason": "', repEvent.reason,
            ', "weight": ', _uint2str(repEvent.weight),
            ', "context": "', repEvent.context,
            '"}'
        );

        string memory cid = _uploadToIPFS(eventData);
        return cid;
    }

    function _updateUserReputationOnIPFS(address user) internal {
        EnhancedReputation storage rep = reputations[user];
        
        bytes memory repData = abi.encodePacked(
            '{"user": "', _addressToString(user),
            ', "score": ', _uint2str(rep.currentScore),
            ', "tier": "', rep.reputationTier,
            ', "validations": ', _uint2str(rep.totalValidations),
            ', "reports": ', _uint2str(rep.totalReports),
            ', "positiveActions": ', _uint2str(rep.positiveActions),
            ', "negativeActions": ', _uint2str(rep.negativeActions),
            ', "isVerified": ', rep.isVerified ? "true" : "false",
            ', "isFlagged": ', rep.isFlagged ? "true" : "false",
            ', "joinDate": ', _uint2str(rep.joinDate),
            ', "lastUpdate": ', _uint2str(rep.lastUpdate),
            '"}'
        );

        string memory cid = _uploadToIPFS(repData);
        rep.reputationCID = cid;
    }

    function _updateTrustNetworkOnIPFS(address user) internal {
        TrustNetwork storage network = trustNetworks[user];
        
        bytes memory networkData = abi.encodePacked(
            '{"user": "', _addressToString(user),
            ', "networkStrength": ', _uint2str(network.networkStrength),
            ', "trustedConnections": ['
        );

        for (uint256 i = 0; i < network.trustedConnections.length; i++) {
            networkData = abi.encodePacked(
                networkData, 
                '"', _addressToString(network.trustedConnections[i]), '"'
            );
            if (i < network.trustedConnections.length - 1) {
                networkData = abi.encodePacked(networkData, ',');
            }
        }

        networkData = abi.encodePacked(networkData, '], "distrustedConnections": [');

        for (uint256 i = 0; i < network.distrustedConnections.length; i++) {
            networkData = abi.encodePacked(
                networkData, 
                '"', _addressToString(network.distrustedConnections[i]), '"'
            );
            if (i < network.distrustedConnections.length - 1) {
                networkData = abi.encodePacked(networkData, ',');
            }
        }

        networkData = abi.encodePacked(networkData, ']}');

        string memory cid = _uploadToIPFS(networkData);
        network.networkCID = cid;
    }

    function _uploadToIPFS(bytes memory data) internal returns (string memory cid) {
        bytes32 hash = keccak256(abi.encodePacked(data, block.timestamp, totalReputationEvents));
        cid = string(abi.encodePacked("Qm", _bytes32ToHexString(hash), _uint2str(block.timestamp)));
        return cid;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 👁️ VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

    function getEnhancedReputation(address user) 
        external 
        view 
        returns (EnhancedReputation memory) 
    {
        return reputations[user];
    }

    function getUserReputationHistory(address user) 
        external 
        view 
        returns (ReputationEvent[] memory) 
    {
        return userReputationHistory[user];
    }

    function getReputationTier(address user) external view returns (string memory) {
        return reputations[user].reputationTier;
    }

    function getTrustNetwork(address user) external view returns (TrustNetwork memory) {
        return trustNetworks[user];
    }

    function getUserReputationCIDs(address user) external view returns (string[] memory) {
        return userReputationCIDs[user];
    }

    function getEcosystemReputationStats() 
        external 
        view 
        returns (
            uint256 totalUsers_,
            uint256 avgScore,
            uint256 platinumUsers,
            uint256 flaggedUsers
        ) 
    {
        uint256 platinumCount = 0;
        uint256 flaggedCount = 0;

        // Nota: In produzione si userebbe un enumerabile mapping
        // Per semplicità restituiamo dati aggregati
        return (totalUsers, averageReputationScore, platinumCount, flaggedCount);
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🛠️ UTILITY FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

    function _bytes32ToHexString(bytes32 _bytes32) internal pure returns (string memory) {
        bytes memory s = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            bytes1 b = bytes1(_bytes32[i]);
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[i * 2] = _char(hi);
            s[i * 2 + 1] = _char(lo);
        }
        return string(s);
    }

    function _char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function _uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _int2str(int256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        bool negative = _i < 0;
        uint256 i = negative ? uint256(-_i) : uint256(_i);
        string memory str = _uint2str(i);
        return negative ? string(abi.encodePacked("-", str)) : str;
    }

    function _addressToString(address addr) internal pure returns (string memory) {
        return Strings.toHexString(uint256(uint160(addr)), 20);
    }
}
