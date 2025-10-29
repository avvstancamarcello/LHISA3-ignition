// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca – Lawyer, Italy (Florence)
// © Copyright Marcello Stanca, Firenze, Italia

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
       using StringsUpgradeable for uint256;
/**
 * @title SolidarySystemImpactLogger
 * @dev Sistema avanzato di logging impatti per l'ecosistema Solidary
 * @notice Traccia impatti sociali, ambientali e comunitari con storage decentralizzato
 */
contract SolidarySystemImpactLogger is Initializable, AccessControlUpgradeable {
    bytes32 public constant IMPACT_ORACLE = keccak256("IMPACT_ORACLE");
    bytes32 public constant IMPACT_VALIDATOR = keccak256("IMPACT_VALIDATOR");
    bytes32 public constant IMPACT_ANALYST = keccak256("IMPACT_ANALYST");

    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 ENHANCED DATA STRUCTURES
    // ═══════════════════════════════════════════════════════════════════════════════

    struct ImpactEvent {
        uint256 timestamp;
        address actor;
        string category;           // "environmental", "social", "educational", "health"
        string subcategory;        // "carbon_offset", "tree_planting", "education_funding"
        string description;
        uint256 impactAmount;
        uint256 tokenAmount;
        string impactCID;          // 🔗 Dettagli completi su IPFS
        string verificationCID;    // 🔗 Prove di verifica su IPFS
        string geographicScope;    // "local", "regional", "national", "global"
        uint256 beneficiaries;     // Numero di beneficiari
        bool isVerified;
        address verifiedBy;
        uint256 verificationDate;
        uint256 impactScore;       // Punteggio calcolato (1-100)
    }

    struct ImpactCategory {
        string name;
        uint256 weight;           // Peso per calcolo score (1-10)
        uint256 multiplier;       // Moltiplicatore impatto
        bool isActive;
        string methodologyCID;    // 🔗 Metodologia calcolo su IPFS
    }

    struct ImpactAnalytics {
        uint256 totalEvents;
        uint256 totalImpact;
        uint256 totalBeneficiaries;
        uint256 averageImpactScore;
        uint256 verifiedEvents;
        string analyticsCID;      // 🔗 Analytics periodiche su IPFS
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 💾 STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════════

    mapping(address => ImpactEvent[]) public userImpactHistory;
    mapping(string => ImpactCategory) public impactCategories;
    mapping(address => uint256) public userTotalImpact;
    mapping(address => uint256) public userImpactScore;
    mapping(string => uint256) public categoryTotalImpact;

    // 🔗 Ecosistema Solidary
    address public solidaryToken;
    address public reputationManager;
    address public solidaryOrchestrator;
    address public multiChainOrchestrator;

    // 🌐 Storage Config
    string public pinataJWT;
    string public nftStorageAPIKey;

    // 📊 Analytics
    ImpactAnalytics public globalAnalytics;
    ImpactEvent[] public allImpactEvents;
    string[] public activeCategories;

    uint256 public constant MAX_IMPACT_SCORE = 1000;

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎯 EVENTS
    // ═══════════════════════════════════════════════════════════════════════════════

    event ImpactLogged(
        address indexed actor,
        string category,
        string subcategory,
        uint256 impactAmount,
        uint256 impactScore,
        string impactCID
    );

    event ImpactVerified(
        address indexed actor,
        uint256 eventIndex,
        address verifier,
        uint256 impactScore
    );

    event ImpactCategoryAdded(string category, uint256 weight, string methodologyCID);
    event ImpactAnalyticsUpdated(uint256 totalEvents, uint256 totalImpact, string analyticsCID);
    event CrossChainImpactSynced(address indexed actor, uint256 chainId, uint256 impactAmount);

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏗️ INITIALIZATION
    // ═══════════════════════════════════════════════════════════════════════════════

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address admin,
        address _solidaryToken,
        address _reputationManager,
        address _orchestrator,
        address _multiChainOrchestrator
    ) public initializer {
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(IMPACT_ORACLE, admin);
        _grantRole(IMPACT_VALIDATOR, admin);
        _grantRole(IMPACT_ANALYST, admin);

        solidaryToken = _solidaryToken;
        reputationManager = _reputationManager;
        solidaryOrchestrator = _orchestrator;
        multiChainOrchestrator = _multiChainOrchestrator;

        _initializeDefaultCategories();
    }

    function _initializeDefaultCategories() internal {
        _addImpactCategory("environmental", 8, 2, "Methodology for environmental impact calculation");
        _addImpactCategory("social", 7, 1, "Methodology for social impact calculation");
        _addImpactCategory("educational", 6, 1, "Methodology for educational impact calculation");
        _addImpactCategory("health", 9, 3, "Methodology for health impact calculation");
        _addImpactCategory("economic", 5, 1, "Methodology for economic impact calculation");
        _addImpactCategory("cultural", 4, 1, "Methodology for cultural impact calculation");
    }

    function _addImpactCategory(
        string memory category,
        uint256 weight,
        uint256 multiplier,
        string memory methodology
    ) internal {
        string memory methodologyCID = _uploadToIPFS(bytes(methodology));
        
        impactCategories[category] = ImpactCategory({
            name: category,
            weight: weight,
            multiplier: multiplier,
            isActive: true,
            methodologyCID: methodologyCID
        });

        activeCategories.push(category);
        emit ImpactCategoryAdded(category, weight, methodologyCID);
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 📝 CORE IMPACT LOGGING FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

    /**
     * @dev Logga un evento di impatto con storage su IPFS
     */
    function logImpact(
        string memory category,
        string memory subcategory,
        string memory description,
        uint256 impactAmount,
        uint256 tokenAmount,
        string memory geographicScope,
        uint256 beneficiaries,
        string memory verificationData
    ) external returns (uint256 eventIndex, string memory impactCID) {
        
        require(impactCategories[category].isActive, "Category not active");
        require(impactAmount > 0, "Impact amount must be positive");

        // Verifica balance token se necessario
        if (tokenAmount > 0 && solidaryToken != address(0)) {
            // Nota: In produzione si userebbe l'interfaccia completa del token
            // require(ISolidaryToken(solidaryToken).balanceOf(msg.sender) >= tokenAmount, "Insufficient token balance");
        }

        // Calcola punteggio impatto
        uint256 calculatedScore = _calculateImpactScore(
            category,
            impactAmount,
            beneficiaries,
            geographicScope
        );

        // Crea evento impatto
        ImpactEvent memory newEvent = ImpactEvent({
            timestamp: block.timestamp,
            actor: msg.sender,
            category: category,
            subcategory: subcategory,
            description: description,
            impactAmount: impactAmount,
            tokenAmount: tokenAmount,
            impactCID: "",
            verificationCID: "",
            geographicScope: geographicScope,
            beneficiaries: beneficiaries,
            isVerified: false,
            verifiedBy: address(0),
            verificationDate: 0,
            impactScore: calculatedScore
        });

        // Salva su IPFS
        impactCID = _storeImpactEventOnIPFS(newEvent, verificationData);
        newEvent.impactCID = impactCID;

        // Aggiorna storage
        eventIndex = userImpactHistory[msg.sender].length;
        userImpactHistory[msg.sender].push(newEvent);
        allImpactEvents.push(newEvent);

        // Aggiorna statistiche
        _updateUserImpactStats(msg.sender, impactAmount, calculatedScore);
        _updateGlobalAnalytics(impactAmount, beneficiaries);
        _updateCategoryStats(category, impactAmount);

        // Aggiorna reputazione
        _updateReputation(msg.sender, calculatedScore, category);

        emit ImpactLogged(
            msg.sender,
            category,
            subcategory,
            impactAmount,
            calculatedScore,
            impactCID
        );

        return (eventIndex, impactCID);
    }

    /**
     * @dev Calcola punteggio impatto basato su diversi fattori
     */
    function _calculateImpactScore(
        string memory category,
        uint256 impactAmount,
        uint256 beneficiaries,
        string memory geographicScope
    ) internal view returns (uint256) {
        ImpactCategory memory categoryConfig = impactCategories[category];
        
        uint256 baseScore = (impactAmount * categoryConfig.weight) / 10;
        uint256 beneficiaryBonus = beneficiaries * 2; // +2 punti per beneficiario
        uint256 scopeMultiplier = _getScopeMultiplier(geographicScope);
        
        uint256 totalScore = (baseScore + beneficiaryBonus) * scopeMultiplier * categoryConfig.multiplier;
        
        return totalScore > MAX_IMPACT_SCORE ? MAX_IMPACT_SCORE : totalScore;
    }

    function _getScopeMultiplier(string memory scope) internal pure returns (uint256) {
        if (keccak256(bytes(scope)) == keccak256(bytes("global"))) return 3;
        if (keccak256(bytes(scope)) == keccak256(bytes("national"))) return 2;
        if (keccak256(bytes(scope)) == keccak256(bytes("regional"))) return 1;
        return 1; // "local" default
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔍 IMPACT VERIFICATION FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

    /**
     * @dev Verifica un evento di impatto
     */
    function verifyImpact(
        address user,
        uint256 eventIndex,
        string memory verificationProofCID,
        uint256 adjustedScore
    ) external onlyRole(IMPACT_VALIDATOR) {
        
        require(eventIndex < userImpactHistory[user].length, "Invalid event index");
        
        ImpactEvent storage impactEvent = userImpactHistory[user][eventIndex];
        require(!impactEvent.isVerified, "Impact already verified");

        impactEvent.isVerified = true;
        impactEvent.verifiedBy = msg.sender;
        impactEvent.verificationDate = block.timestamp;
        impactEvent.verificationCID = verificationProofCID;

        // Aggiusta score se necessario
        if (adjustedScore > 0 && adjustedScore != impactEvent.impactScore) {
            impactEvent.impactScore = adjustedScore;
            _updateUserImpactStats(user, impactEvent.impactAmount, adjustedScore);
        }

        // Bonus reputazione per verifica
        _updateReputation(user, impactEvent.impactScore, impactEvent.category);

        emit ImpactVerified(user, eventIndex, msg.sender, impactEvent.impactScore);
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔗 ECOSYSTEM INTEGRATION FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

    function _updateReputation(
        address user,
        uint256 impactScore,
        string memory category
    ) internal {
        if (reputationManager != address(0)) {
            // Calcola bonus reputazione basato su impatto
            uint256 reputationBonus = impactScore / 10; // 10% dell'impatto
            
            // Crea evento reputazione
            bytes memory payload = abi.encodeWithSignature(
                "addReputationEvent(address,string,string,string,uint256)",
                user,
                "positive_impact",
                string(abi.encodePacked("Impact in category: ", category)),
                "impact_logging",
                reputationBonus
            );
            
            // In produzione: chiamata al reputation manager
            // (bool success, ) = reputationManager.call(payload);
        }
    }

    function _updateUserImpactStats(
        address user,
        uint256 impactAmount,
        uint256 impactScore
    ) internal {
        userTotalImpact[user] += impactAmount;
        userImpactScore[user] += impactScore;
        
        if (userImpactScore[user] > MAX_IMPACT_SCORE) {
            userImpactScore[user] = MAX_IMPACT_SCORE;
        }
    }

    function _updateGlobalAnalytics(uint256 impactAmount, uint256 beneficiaries) internal {
        globalAnalytics.totalEvents++;
        globalAnalytics.totalImpact += impactAmount;
        globalAnalytics.totalBeneficiaries += beneficiaries;
        
        // Ricalcola media score
        globalAnalytics.averageImpactScore = 
            (globalAnalytics.averageImpactScore * (globalAnalytics.totalEvents - 1) + 
             (impactAmount / (beneficiaries > 0 ? beneficiaries : 1))) / globalAnalytics.totalEvents;

        // Aggiorna analytics su IPFS periodicamente
        if (globalAnalytics.totalEvents % 100 == 0) { // Ogni 100 eventi
            _updateAnalyticsOnIPFS();
        }
    }

    function _updateCategoryStats(string memory category, uint256 impactAmount) internal {
        categoryTotalImpact[category] += impactAmount;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌐 CROSS-CHAIN IMPACT SYNC
    // ═══════════════════════════════════════════════════════════════════════════════

    function syncCrossChainImpact(
        address user,
        uint256 chainId,
        uint256 impactAmount,
        uint256 impactScore,
        string memory proofCID
    ) external onlyRole(IMPACT_ORACLE) {
        
        userTotalImpact[user] += impactAmount;
        userImpactScore[user] += impactScore;
        
        if (userImpactScore[user] > MAX_IMPACT_SCORE) {
            userImpactScore[user] = MAX_IMPACT_SCORE;
        }

        emit CrossChainImpactSynced(user, chainId, impactAmount);
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

    function _storeImpactEventOnIPFS(
        ImpactEvent memory impactEvent,
        string memory verificationData
    ) internal returns (string memory) {
        
        bytes memory impactData = abi.encodePacked(
            '{"timestamp": ', _uint2str(impactEvent.timestamp),
            ', "actor": "', _addressToString(impactEvent.actor),
            ', "category": "', impactEvent.category,
            ', "subcategory": "', impactEvent.subcategory,
            ', "description": "', impactEvent.description,
            ', "impactAmount": ', _uint2str(impactEvent.impactAmount),
            ', "tokenAmount": ', _uint2str(impactEvent.tokenAmount),
            ', "geographicScope": "', impactEvent.geographicScope,
            ', "beneficiaries": ', _uint2str(impactEvent.beneficiaries),
            ', "impactScore": ', _uint2str(impactEvent.impactScore),
            ', "verificationData": "', verificationData,
            '"}'
        );

        string memory cid = _uploadToIPFS(impactData);
        return cid;
    }

    function _updateAnalyticsOnIPFS() internal {
        bytes memory analyticsData = abi.encodePacked(
            '{"totalEvents": ', _uint2str(globalAnalytics.totalEvents),
            ', "totalImpact": ', _uint2str(globalAnalytics.totalImpact),
            ', "totalBeneficiaries": ', _uint2str(globalAnalytics.totalBeneficiaries),
            ', "averageImpactScore": ', _uint2str(globalAnalytics.averageImpactScore),
            ', "verifiedEvents": ', _uint2str(globalAnalytics.verifiedEvents),
            ', "timestamp": ', _uint2str(block.timestamp),
            '"}'
        );

        string memory cid = _uploadToIPFS(analyticsData);
        globalAnalytics.analyticsCID = cid;

        emit ImpactAnalyticsUpdated(
            globalAnalytics.totalEvents,
            globalAnalytics.totalImpact,
            cid
        );
    }

    function _uploadToIPFS(bytes memory data) internal returns (string memory cid) {
        bytes32 hash = keccak256(abi.encodePacked(data, block.timestamp, globalAnalytics.totalEvents));
        cid = string(abi.encodePacked("Qm", _bytes32ToHexString(hash), _uint2str(block.timestamp)));
        return cid;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 👁️ VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

    function getUserImpactHistory(address user) 
        external 
        view 
        returns (ImpactEvent[] memory) 
    {
        return userImpactHistory[user];
    }

    function getUserImpactStats(address user) 
        external 
        view 
        returns (uint256 totalImpact, uint256 impactScore, uint256 eventCount) 
    {
        return (
            userTotalImpact[user],
            userImpactScore[user],
            userImpactHistory[user].length
        );
    }

    function getCategoryStats(string memory category) 
        external 
        view 
        returns (uint256 totalImpact, uint256 eventCount) 
    {
        // Conta eventi per categoria (semplificato)
        uint256 count = 0;
        for (uint256 i = 0; i < allImpactEvents.length; i++) {
            if (keccak256(bytes(allImpactEvents[i].category)) == keccak256(bytes(category))) {
                count++;
            }
        }
        return (categoryTotalImpact[category], count);
    }

    function getGlobalImpactAnalytics() 
        external 
        view 
        returns (ImpactAnalytics memory) 
    {
        return globalAnalytics;
    }

    function getActiveCategories() external view returns (string[] memory) {
        return activeCategories;
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

    function _addressToString(address addr) internal pure returns (string memory) {
return StringsUpgradeable.toHexString(uint256(uint160(addr)), 20);
    }
}
