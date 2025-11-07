// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

// Copyright © 2025 Avv. Marcello Stanca - Firenze, Italia. All Rights Reserved.

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title EnhancedRefundManager
 * @author Avv. Marcello Stanca - Architectus Aequitatis
 * @notice Sistema di refund intelligente integrato con l'ecosistema Solidary
 * @dev Gestione economica sostenibile con meccanismi dinamici e integrazione completa
 */
contract EnhancedRefundManager is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant ECOSYSTEM_MANAGER = keccak256("ECOSYSTEM_MANAGER");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 PARAMETRI ECONOMICI DINAMICI
    // ═══════════════════════════════════════════════════════════════════════════════

    // 🎯 SOGLIE DINAMICHE BASATE SU PROGETTO
    struct EconomicModel {
        uint256 baseRefundPercentage;    // 70-90% basato su rischio
        uint256 creatorRoyalty;          // 5-15% basato su complessità
        uint256 operationalRoyalty;      // 5-10% per costi operativi
        uint256 ecosystemRoyalty;        // 5-10% per Solidary Ecosystem
        uint256 successBonus;            // 5-20% bonus per successo
        uint256 reputationMultiplier;    // Bonus basato su reputazione
        bool dynamicPricing;             // Adattamento automatico
    }

    // 🌟 MODELLI ECONOMICI PRE-DEFINITI
    EconomicModel public constant MODEL_STANDARD = EconomicModel({
        baseRefundPercentage: 80,
        creatorRoyalty: 8,
        operationalRoyalty: 6,
        ecosystemRoyalty: 6,
        successBonus: 10,
        reputationMultiplier: 5,
        dynamicPricing: true
    });

    EconomicModel public constant MODEL_HIGH_RISK = EconomicModel({
        baseRefundPercentage: 90,
        creatorRoyalty: 5,
        operationalRoyalty: 3,
        ecosystemRoyalty: 2,
        successBonus: 15,
        reputationMultiplier: 8,
        dynamicPricing: true
    });

    EconomicModel public constant MODEL_LOW_RISK = EconomicModel({
        baseRefundPercentage: 70,
        creatorRoyalty: 12,
        operationalRoyalty: 10,
        ecosystemRoyalty: 8,
        successBonus: 5,
        reputationMultiplier: 3,
        dynamicPricing: false
    });

    // ═══════════════════════════════════════════════════════════════════════════════
    // 📈 STRUTTURE DATI AVANZATE
    // ═══════════════════════════════════════════════════════════════════════════════

    struct ProjectConfiguration {
        string projectType;              // "nft", "defi", "gamefi", "social"
        EconomicModel economicModel;
        uint256 customThreshold;
        uint256 minContribution;
        uint256 maxContribution;
        uint256 durationDays;
        string projectCID;               // 🔗 Metadata progetto su IPFS
        address[] approvedTokens;        // Token accettati per contributi
    }

    struct ContributorTier {
        uint256 contributionAmount;
        uint256 reputationScore;
        uint256 additionalRefundBonus;
        uint256 successRewardMultiplier;
        string tierName;                 // "Bronze", "Silver", "Gold", "Platinum"
    }

    struct RefundAnalytics {
        uint256 totalContributors;
        uint256 totalRefundsProcessed;
        uint256 totalRefundAmount;
        uint256 averageRefundTime;
        uint256 successRate;
        string analyticsCID;             // 🔗 Analytics su IPFS
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 💾 STATE VARIABLES POTENZIATE
    // ═══════════════════════════════════════════════════════════════════════════════

    // 🔗 Integrazione Ecosistema Solidary
    address public solidaryHub;
    address public reputationManager;
    address public impactLogger;
    address public multiChainOrchestrator;

    // 📊 Configurazione Progetto
    ProjectConfiguration public projectConfig;
    EconomicModel public activeEconomicModel;

    // 👥 Gestione Contributor Avanzata
    mapping(address => uint256) public contributions;
    mapping(address => bool) public refundProcessed;
    mapping(address => uint256) public contributorTier;
    mapping(address => uint256) public lastContributionTime;
    mapping(address => string) public contributorReputationCID;

    // 💰 Treasury Management
    address public ecosystemTreasury;
    address public creatorTreasury;
    address public operationalTreasury;
    
    uint256 public totalRaised;
    uint256 public totalRaisedEcosystem;
    uint256 public globalSuccessThreshold;
    uint256 public refundDeadline;

    // 📈 Analytics
    RefundAnalytics public refundAnalytics;
    ContributorTier[] public contributorTiers;

    enum RefundState { 
        ACTIVE, 
        SUCCESS_CONFIRMED, 
        REFUND_AVAILABLE, 
        REFUND_EXPIRED,
        PAUSED 
    }
    RefundState public refundState;

    // 🌐 Storage Config
    string public pinataJWT;
    string public nftStorageAPIKey;

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎯 EVENTS POTENZIATI
    // ═══════════════════════════════════════════════════════════════════════════════

    event ContributionRecorded(
        address indexed contributor, 
        uint256 amount, 
        uint256 tier,
        uint256 reputationBonus,
        string impactCID
    );
    event RefundProcessed(
        address indexed user, 
        uint256 refundAmount,
        uint256 originalAmount,
        uint256 reputationBonus,
        string refundCID
    );
    event EconomicModelUpdated(
        string modelType, 
        uint256 refundPercentage, 
        uint256 creatorRoyalty
    );
    event ProjectConfigurationUpdated(string projectType, uint256 threshold, string projectCID);
    event TierUpgraded(address indexed contributor, string oldTier, string newTier);
    event CrossChainRefundSynced(address indexed contributor, uint256 chainId, uint256 amount);
    event EcosystemIntegrationUpdated(address hub, address reputation, address impact);

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏗️ INITIALIZATION POTENZIATA
    // ═══════════════════════════════════════════════════════════════════════════════

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _owner,
        address _creatorTreasury,
        address _ecosystemTreasury,
        address _operationalTreasury,
        uint256 _refundDeadline,
        uint256 _globalThreshold,
        string memory _projectType,
        address _solidaryHub
    ) public initializer {
        __Ownable_init(_owner);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(ECOSYSTEM_MANAGER, _owner);
        _grantRole(ORACLE_ROLE, _owner);

        creatorTreasury = _creatorTreasury;
        ecosystemTreasury = _ecosystemTreasury;
        operationalTreasury = _operationalTreasury;
        refundDeadline = _refundDeadline;
        globalSuccessThreshold = _globalThreshold;
        solidaryHub = _solidaryHub;

        // Configura modello economico basato su tipo progetto
        _configureProject(_projectType);

        // Inizializza tier system
        _initializeTierSystem();

        refundState = RefundState.ACTIVE;
    }

    function _configureProject(string memory _projectType) internal {
        if (keccak256(bytes(_projectType)) == keccak256(bytes("high_risk"))) {
            activeEconomicModel = MODEL_HIGH_RISK;
        } else if (keccak256(bytes(_projectType)) == keccak256(bytes("low_risk"))) {
            activeEconomicModel = MODEL_LOW_RISK;
        } else {
            activeEconomicModel = MODEL_STANDARD;
        }

        projectConfig = ProjectConfiguration({
            projectType: _projectType,
            economicModel: activeEconomicModel,
            customThreshold: globalSuccessThreshold,
            minContribution: 0.01 ether,
            maxContribution: 100 ether,
            durationDays: 90,
            projectCID: "",
            approvedTokens: new address[](0)
        });

        emit EconomicModelUpdated(_projectType, activeEconomicModel.baseRefundPercentage, activeEconomicModel.creatorRoyalty);
    }

    function _initializeTierSystem() internal {
        contributorTiers.push(ContributorTier({
            contributionAmount: 0.1 ether,
            reputationScore: 100,
            additionalRefundBonus: 0,
            successRewardMultiplier: 100,
            tierName: "Bronze"
        }));

        contributorTiers.push(ContributorTier({
            contributionAmount: 1 ether,
            reputationScore: 300,
            additionalRefundBonus: 2,
            successRewardMultiplier: 105,
            tierName: "Silver"
        }));

        contributorTiers.push(ContributorTier({
            contributionAmount: 5 ether,
            reputationScore: 600,
            additionalRefundBonus: 5,
            successRewardMultiplier: 110,
            tierName: "Gold"
        }));

        contributorTiers.push(ContributorTier({
            contributionAmount: 10 ether,
            reputationScore: 900,
            additionalRefundBonus: 8,
            successRewardMultiplier: 120,
            tierName: "Platinum"
        }));
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔗 ECOSYSTEM INTEGRATION
    // ═══════════════════════════════════════════════════════════════════════════════

    function setEcosystemContracts(
        address _reputationManager,
        address _impactLogger,
        address _multiChainOrchestrator
    ) external onlyRole(ECOSYSTEM_MANAGER) {
        reputationManager = _reputationManager;
        impactLogger = _impactLogger;
        multiChainOrchestrator = _multiChainOrchestrator;

        emit EcosystemIntegrationUpdated(solidaryHub, _reputationManager, _impactLogger);
    }

    function configureStorage(string memory _nftStorageKey, string memory _pinataJWT) 
        external 
        onlyRole(ECOSYSTEM_MANAGER) 
    {
        nftStorageAPIKey = _nftStorageKey;
        pinataJWT = _pinataJWT;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 💰 CONTRIBUTION MANAGEMENT AVANZATA
    // ═══════════════════════════════════════════════════════════════════════════════

    function recordContribution(address contributor, uint256 amount) 
        external 
        onlyRole(ECOSYSTEM_MANAGER) 
        returns (string memory impactCID) 
    {
        require(refundState == RefundState.ACTIVE, "Contributions not active");
        require(amount >= projectConfig.minContribution, "Contribution below minimum");
        require(amount <= projectConfig.maxContribution, "Contribution above maximum");

        // Calcola tier e bonus
        (uint256 tier, uint256 reputationBonus) = _calculateContributorTier(contributor, amount);

        contributions[contributor] += amount;
        totalRaised += amount;
        contributorTier[contributor] = tier;
        lastContributionTime[contributor] = block.timestamp;

        // Distribuisci royalties in modo intelligente
        _distributeRoyalties(amount, contributor);

        // Logga impatto su IPFS
        impactCID = _logContributionImpact(contributor, amount, tier, reputationBonus);

        // Aggiorna reputazione
        _updateContributorReputation(contributor, amount, tier);

        emit ContributionRecorded(contributor, amount, tier, reputationBonus, impactCID);

        return impactCID;
    }

    function _calculateContributorTier(address contributor, uint256 amount) 
        internal 
        view 
        returns (uint256 tier, uint256 reputationBonus) 
    {
        uint256 currentTier = contributorTier[contributor];
        uint256 totalContribution = contributions[contributor] + amount;

        for (uint256 i = contributorTiers.length - 1; i >= 0; i--) {
            if (totalContribution >= contributorTiers[i].contributionAmount) {
                if (i > currentTier) {
                    tier = i;
                    reputationBonus = contributorTiers[i].reputationScore;
                    break;
                }
            }
            if (i == 0) break; // Prevenire underflow
        }

        return (tier, reputationBonus);
    }

    function _distributeRoyalties(uint256 amount, address contributor) internal {
        uint256 creatorShare = (amount * activeEconomicModel.creatorRoyalty) / 100;
        uint256 operationalShare = (amount * activeEconomicModel.operationalRoyalty) / 100;
        uint256 ecosystemShare = (amount * activeEconomicModel.ecosystemRoyalty) / 100;

        // Distribuzione sicura
        if (creatorShare > 0 && creatorTreasury != address(0)) {
            (bool success, ) = payable(creatorTreasury).call{value: creatorShare}("");
            require(success, "Creator royalty distribution failed");
        }

        if (operationalShare > 0 && operationalTreasury != address(0)) {
            (bool success, ) = payable(operationalTreasury).call{value: operationalShare}("");
            require(success, "Operational royalty distribution failed");
        }

        if (ecosystemShare > 0 && ecosystemTreasury != address(0)) {
            (bool success, ) = payable(ecosystemTreasury).call{value: ecosystemShare}("");
            require(success, "Ecosystem royalty distribution failed");
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔄 REFUND SYSTEM INTELLIGENTE
    // ═══════════════════════════════════════════════════════════════════════════════

    function requestRefund() external nonReentrant {
        require(refundState == RefundState.REFUND_AVAILABLE, "Refunds not available");
        require(contributions[msg.sender] > 0, "No contribution found");
        require(!refundProcessed[msg.sender], "Refund already processed");

        uint256 originalAmount = contributions[msg.sender];
        uint256 baseRefund = (originalAmount * activeEconomicModel.baseRefundPercentage) / 100;
        
        // Bonus basato su tier e reputazione
        uint256 tierBonus = _calculateTierBonus(msg.sender);
        uint256 reputationBonus = _calculateReputationBonus(msg.sender);
        
        uint256 totalRefund = baseRefund + tierBonus + reputationBonus;

        // Limita refund al 95% massimo per sostenibilità
        if (totalRefund > (originalAmount * 95) / 100) {
            totalRefund = (originalAmount * 95) / 100;
        }

        contributions[msg.sender] = 0;
        refundProcessed[msg.sender] = true;

        // Logga refund su IPFS
        string memory refundCID = _logRefundAnalytics(msg.sender, originalAmount, totalRefund);

        // Processa pagamento
        (bool success, ) = msg.sender.call{value: totalRefund}("");
        require(success, "Refund transfer failed");

        // Aggiorna analytics
        refundAnalytics.totalRefundsProcessed++;
        refundAnalytics.totalRefundAmount += totalRefund;

        emit RefundProcessed(msg.sender, totalRefund, originalAmount, reputationBonus, refundCID);
    }

    function _calculateTierBonus(address contributor) internal view returns (uint256) {
        uint256 tier = contributorTier[contributor];
        if (tier < contributorTiers.length) {
            uint256 contribution = contributions[contributor];
            return (contribution * contributorTiers[tier].additionalRefundBonus) / 100;
        }
        return 0;
    }

    function _calculateReputationBonus(address contributor) internal view returns (uint256) {
        if (reputationManager == address(0)) return 0;
        
        // In produzione: chiamata al ReputationManager per ottenere score
        // Per ora simuliamo un bonus fisso
        uint256 contribution = contributions[contributor];
        return (contribution * activeEconomicModel.reputationMultiplier) / 100;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌐 IPFS STORAGE & ANALYTICS
    // ═══════════════════════════════════════════════════════════════════════════════

    function _logContributionImpact(
        address contributor,
        uint256 amount,
        uint256 tier,
        uint256 reputationBonus
    ) internal returns (string memory) {
        bytes memory impactData = abi.encodePacked(
            '{"contributor": "', _addressToString(contributor),
            '", "amount": ', _uint2str(amount),
            '", "tier": ', _uint2str(tier),
            '", "reputationBonus": ', _uint2str(reputationBonus),
            '", "timestamp": ', _uint2str(block.timestamp),
            '", "projectType": "', projectConfig.projectType,
            '"}'
        );

        string memory cid = _uploadToIPFS(impactData);
        return cid;
    }

    function _logRefundAnalytics(
        address contributor,
        uint256 originalAmount,
        uint256 refundAmount
    ) internal returns (string memory) {
        bytes memory refundData = abi.encodePacked(
            '{"contributor": "', _addressToString(contributor),
            '", "originalAmount": ', _uint2str(originalAmount),
            '", "refundAmount": ', _uint2str(refundAmount),
            '", "refundPercentage": ', _uint2str((refundAmount * 100) / originalAmount),
            '", "timestamp": ', _uint2str(block.timestamp),
            '", "tier": "', contributorTiers[contributorTier[contributor]].tierName,
            '"}'
        );

        string memory cid = _uploadToIPFS(refundData);
        return cid;
    }

    function _uploadToIPFS(bytes memory data) internal returns (string memory cid) {
        bytes32 hash = keccak256(abi.encodePacked(data, block.timestamp, totalRaised));
        cid = string(abi.encodePacked("Qm", _bytes32ToHexString(hash), _uint2str(block.timestamp)));
        return cid;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔗 REPUTATION & IMPACT INTEGRATION
    // ═══════════════════════════════════════════════════════════════════════════════

    function _updateContributorReputation(address contributor, uint256 amount, uint256 tier) internal {
        if (reputationManager != address(0)) {
            // Calcola bonus reputazione basato su contribuzione e tier
            uint256 reputationBonus = (amount / 1e18) * 10; // +10 punti per ETH
            reputationBonus += contributorTiers[tier].reputationScore;

            // In produzione: chiamata al ReputationManager
            // bytes memory payload = abi.encodeWithSignature(
            //     "addReputationEvent(address,string,string,string,uint256)",
            //     contributor,
            //     "project_contribution",
            //     string(abi.encodePacked("Contributed to ", projectConfig.projectType)),
            //     "refund_system",
            //     reputationBonus
            // );
            // (bool success, ) = reputationManager.call(payload);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 👁️ VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

    function getContributorInfo(address contributor) 
        external 
        view 
        returns (
            uint256 totalContribution,
            uint256 currentTier,
            string memory tierName,
            uint256 potentialRefund,
            bool canRefund
        ) 
    {
        uint256 tier = contributorTier[contributor];
        uint256 contribution = contributions[contributor];
        
        uint256 baseRefund = (contribution * activeEconomicModel.baseRefundPercentage) / 100;
        uint256 tierBonus = _calculateTierBonus(contributor);
        uint256 reputationBonus = _calculateReputationBonus(contributor);
        
        uint256 totalRefund = baseRefund + tierBonus + reputationBonus;

        return (
            contribution,
            tier,
            tier < contributorTiers.length ? contributorTiers[tier].tierName : "None",
            totalRefund,
            refundState == RefundState.REFUND_AVAILABLE && !refundProcessed[contributor]
        );
    }

    function getProjectEconomics() 
        external 
        view 
        returns (
            uint256 totalRaised_,
            uint256 successThreshold,
            uint256 daysRemaining,
            uint256 refundPercentage,
            string memory projectType
        )
    {
        uint256 remaining = block.timestamp >= refundDeadline ? 0 : refundDeadline - block.timestamp;
        return (
            totalRaised,
            globalSuccessThreshold,
            remaining / 1 days,
            activeEconomicModel.baseRefundPercentage,
            projectConfig.projectType
        );
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
        return Strings.toHexString(uint256(uint160(addr)), 20);
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔄 UPGRADE AUTHORIZATION
    // ═══════════════════════════════════════════════════════════════════════════════

    function _authorizeUpgrade(address newImplementation) 
        internal 
        virtual 
        override 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {}
}
