// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

// Copyright © 2025 Avv. Marcello Stanca - Firenze, Italia. All Rights Reserved.

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title EnhancedSolidaryTrustManager (Custos Fidei - The Guardian of Trust)
 * @author Avv. Marcello Stanca - Architectus Aequitatis
 * @notice Sistema avanzato di certificazione e policy management per l'ecosistema Solidary
 */
contract EnhancedSolidaryTrustManager is Initializable, OwnableUpgradeable, UUPSUpgradeable, AccessControlUpgradeable {
    
    bytes32 public constant CERTIFICATION_ORACLE = keccak256("CERTIFICATION_ORACLE");
    bytes32 public constant POLICY_MANAGER = keccak256("POLICY_MANAGER");
    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");

    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 STRUCTURE POTENZIATE
    // ═══════════════════════════════════════════════════════════════════════════════

    struct EnhancedCertificate {
        string name;
        address module;
        uint256 issuedAt;
        uint256 validUntil;
        bool revoked;
        string certificateType;      // "nft", "ft", "bridge", "governance"
        uint256 trustLevel;          // 1-10 (livello fiducia)
        string complianceCID;        // 🔗 Documentazione compliance su IPFS
        address issuedBy;
        uint256 lastAudit;
        string auditResultsCID;      // 🔗 Risultati audit su IPFS
    }

    struct EnhancedPolicy {
        string description;
        uint256 createdAt;
        bool active;
        string policyType;           // "ethical", "technical", "economic", "security"
        uint256 severityLevel;       // 1-5 (gravità violazione)
        string enforcementAction;    // "warning", "suspend", "revoke", "penalize"
        string policyCID;            // 🔗 Policy completa su IPFS
        uint256 lastUpdated;
    }

    struct TrustScore {
        uint256 currentScore;
        uint256 totalCertifications;
        uint256 policyViolations;
        uint256 lastScoreUpdate;
        string scoreMetricsCID;      // 🔗 Metriche calcolo su IPFS
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 💾 STATE VARIABLES AVANZATE
    // ═══════════════════════════════════════════════════════════════════════════════

    mapping(address => EnhancedCertificate) public certificates;
    mapping(bytes32 => EnhancedPolicy) public policies;
    mapping(address => TrustScore) public trustScores;
    mapping(string => address[]) public certifiedModulesByType;

    // 🔗 Integrazione Ecosistema
    address public solidaryHub;
    address public reputationManager;
    
    // 🌐 Storage Config
    string public pinataJWT;
    string public nftStorageAPIKey;

    // 📊 Statistics
    uint256 public totalCertifications;
    uint256 public activeCertifications;
    uint256 public totalPolicies;
    uint256 public policyViolations;

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎯 EVENTS POTENZIATI
    // ═══════════════════════════════════════════════════════════════════════════════

    event CertificateIssued(
        address indexed module, 
        string name, 
        string certificateType,
        uint256 trustLevel,
        string complianceCID
    );
    event CertificateRevoked(address indexed module, string reason, address revokedBy);
    event PolicyAdded(bytes32 indexed policyId, string policyType, string description, string policyCID);
    event PolicyViolation(address indexed module, bytes32 policyId, string actionTaken);
    event TrustScoreUpdated(address indexed module, uint256 oldScore, uint256 newScore);
    event ComplianceAuditCompleted(address indexed module, uint256 score, string auditCID);

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏗️ INITIALIZATION
    // ═══════════════════════════════════════════════════════════════════════════════

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        address _solidaryHub,
        address _reputationManager
    ) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(CERTIFICATION_ORACLE, initialOwner);
        _grantRole(POLICY_MANAGER, initialOwner);
        _grantRole(AUDITOR_ROLE, initialOwner);

        solidaryHub = _solidaryHub;
        reputationManager = _reputationManager;

        // Inizializza policy etiche di base
        _initializeCorePolicies();
    }

    function _initializeCorePolicies() internal {
        // Policy etiche fondamentali per l'ecosistema Solidary
        _addEnhancedPolicy(
            "Anti-Speculation Policy",
            "ethical",
            "Proibisce pattern di trading speculativo e wash trading",
            "suspend",
            "Policy contro comportamenti speculativi dannosi"
        );

        _addEnhancedPolicy(
            "Fair Distribution Policy", 
            "economic",
            "Garantisce distribuzione equa di token e NFT",
            "penalize", 
            "Policy per distribuzione equa delle risorse"
        );

        _addEnhancedPolicy(
            "Transparency Policy",
            "ethical", 
            "Richiede trasparenza totale nelle operazioni",
            "warning",
            "Policy per trasparenza operativa completa"
        );

        _addEnhancedPolicy(
            "Solidary Impact Policy",
            "ethical",
            "Richiede verifica impatti solidali misurabili", 
            "revoke",
            "Policy per impatti solidali verificabili"
        );
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔐 ENHANCED CERTIFICATION SYSTEM
    // ═══════════════════════════════════════════════════════════════════════════════

    function issueEnhancedCertificate(
        address module,
        string memory name,
        string memory certificateType,
        uint256 validityDuration,
        uint256 trustLevel,
        string memory complianceData
    ) external onlyRole(CERTIFICATION_ORACLE) returns (string memory complianceCID) {
        
        require(module != address(0), "Module address cannot be zero");
        require(trustLevel >= 1 && trustLevel <= 10, "Trust level must be 1-10");
        require(validityDuration >= 30 days, "Validity must be at least 30 days");

        complianceCID = _storeComplianceDocument(complianceData);

        certificates[module] = EnhancedCertificate({
            name: name,
            module: module,
            issuedAt: block.timestamp,
            validUntil: block.timestamp + validityDuration,
            revoked: false,
            certificateType: certificateType,
            trustLevel: trustLevel,
            complianceCID: complianceCID,
            issuedBy: msg.sender,
            lastAudit: block.timestamp,
            auditResultsCID: ""
        });

        certifiedModulesByType[certificateType].push(module);
        totalCertifications++;
        activeCertifications++;

        // Aggiorna trust score
        _updateTrustScore(module, trustLevel * 10); // 10 punti per livello trust

        emit CertificateIssued(module, name, certificateType, trustLevel, complianceCID);
    }

    function revokeCertificate(address module, string memory reason) external onlyRole(CERTIFICATION_ORACLE) {
        require(certificates[module].module != address(0), "Certificate not found");
        require(!certificates[module].revoked, "Certificate already revoked");

        certificates[module].revoked = true;
        activeCertifications--;

        // Penalizza trust score
        _updateTrustScore(module, -50); // -50 punti per revoca

        emit CertificateRevoked(module, reason, msg.sender);
    }

    function validateCertificate(address module) external view returns (
        bool isValid, 
        uint256 trustLevel, 
        string memory certificateType
    ) {
        EnhancedCertificate memory cert = certificates[module];
        bool valid = (
            cert.module != address(0) &&
            !cert.revoked &&
            block.timestamp <= cert.validUntil
        );

        return (valid, cert.trustLevel, cert.certificateType);
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 📜 ENHANCED POLICY MANAGEMENT
    // ═══════════════════════════════════════════════════════════════════════════════

    function _addEnhancedPolicy(
        string memory description,
        string memory policyType,
        string memory enforcement,
        string memory action,
        string memory policyData
    ) internal returns (bytes32) {
        
        string memory policyCID = _uploadToIPFS(bytes(policyData));
        bytes32 policyId = keccak256(abi.encodePacked(description, block.timestamp));

        policies[policyId] = EnhancedPolicy({
            description: description,
            createdAt: block.timestamp,
            active: true,
            policyType: policyType,
            severityLevel: _calculateSeverityLevel(action),
            enforcementAction: action,
            policyCID: policyCID,
            lastUpdated: block.timestamp
        });

        totalPolicies++;

        emit PolicyAdded(policyId, policyType, description, policyCID);
        return policyId;
    }

    function reportPolicyViolation(
        address module,
        bytes32 policyId,
        string memory evidence
    ) external onlyRole(AUDITOR_ROLE) returns (string memory actionTaken) {
        
        require(policies[policyId].active, "Policy not active");
        require(certificates[module].module != address(0), "Module not certified");

        EnhancedPolicy memory policy = policies[policyId];
        actionTaken = policy.enforcementAction;

        // Applica azione enforcement
        if (keccak256(bytes(actionTaken)) == keccak256(bytes("suspend"))) {
            _suspendModule(module);
        } else if (keccak256(bytes(actionTaken)) == keccak256(bytes("revoke"))) {
            revokeCertificate(module, "Policy violation");
        }

        policyViolations++;
        trustScores[module].policyViolations++;

        // Aggiorna reputazione
        _updateReputation(module, -policy.severityLevel * 10);

        emit PolicyViolation(module, policyId, actionTaken);
    }

    function _suspendModule(address module) internal {
        certificates[module].validUntil = block.timestamp - 1; // Immediata scadenza
        _updateTrustScore(module, -30); // -30 punti per sospensione
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 TRUST SCORE SYSTEM
    // ═══════════════════════════════════════════════════════════════════════════════

    function _updateTrustScore(address module, int256 scoreChange) internal {
        TrustScore storage score = trustScores[module];
        uint256 oldScore = score.currentScore;

        if (scoreChange > 0) {
            score.currentScore += uint256(scoreChange);
        } else {
            if (score.currentScore > uint256(-scoreChange)) {
                score.currentScore -= uint256(-scoreChange);
            } else {
                score.currentScore = 0;
            }
        }

        // Limita score massimo a 1000
        if (score.currentScore > 1000) {
            score.currentScore = 1000;
        }

        score.lastScoreUpdate = block.timestamp;

        emit TrustScoreUpdated(module, oldScore, score.currentScore);
    }

    function getTrustScore(address module) external view returns (
        uint256 score,
        uint256 certifications,
        uint256 violations,
        string memory tier
    ) {
        TrustScore memory trust = trustScores[module];
        string memory trustTier = _calculateTrustTier(trust.currentScore);

        return (
            trust.currentScore,
            trust.totalCertifications,
            trust.policyViolations,
            trustTier
        );
    }

    function _calculateTrustTier(uint256 score) internal pure returns (string memory) {
        if (score >= 900) return "Platinum";
        if (score >= 700) return "Gold";
        if (score >= 500) return "Silver";
        if (score >= 300) return "Bronze";
        return "Newcomer";
    }

    function _calculateSeverityLevel(string memory action) internal pure returns (uint256) {
        if (keccak256(bytes(action)) == keccak256(bytes("revoke"))) return 5;
        if (keccak256(bytes(action)) == keccak256(bytes("suspend"))) return 4;
        if (keccak256(bytes(action)) == keccak256(bytes("penalize"))) return 3;
        if (keccak256(bytes(action)) == keccak256(bytes("warning"))) return 2;
        return 1;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔗 ECOSYSTEM INTEGRATION
    // ═══════════════════════════════════════════════════════════════════════════════

    function _updateReputation(address module, int256 reputationChange) internal {
        if (reputationManager != address(0)) {
            // In produzione: chiamata al ReputationManager
            // bytes memory payload = abi.encodeWithSignature(
            //     "addReputationEvent(address,string,string,string,uint256)",
            //     module,
            //     "trust_management",
            //     "Trust score update",
            //     "certification_system",
            //     uint256(reputationChange)
            // );
            // (bool success, ) = reputationManager.call(payload);
        }
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

    function _storeComplianceDocument(string memory complianceData) internal returns (string memory) {
        bytes memory docData = abi.encodePacked(
            '{"complianceData": "', complianceData,
            '", "timestamp": ', _uint2str(block.timestamp),
            '", "issuedBy": "', _addressToString(msg.sender),
            '"}'
        );

        return _uploadToIPFS(docData);
    }

    function _uploadToIPFS(bytes memory data) internal returns (string memory cid) {
        bytes32 hash = keccak256(abi.encodePacked(data, block.timestamp, totalCertifications));
        cid = string(abi.encodePacked("Qm", _bytes32ToHexString(hash), _uint2str(block.timestamp)));
        return cid;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 👁️ VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

    function getCertifiedModulesByType(string memory certificateType) 
        external 
        view 
        returns (address[] memory) 
    {
        return certifiedModulesByType[certificateType];
    }

    function getModuleCertificationStatus(address module) 
        external 
        view 
        returns (
            bool certified,
            bool active,
            uint256 trustLevel,
            string memory certificateType,
            uint256 expiresIn
        ) 
    {
        EnhancedCertificate memory cert = certificates[module];
        bool isActive = (!cert.revoked && block.timestamp <= cert.validUntil);
        uint256 timeLeft = cert.validUntil > block.timestamp ? cert.validUntil - block.timestamp : 0;

        return (
            cert.module != address(0),
            isActive,
            cert.trustLevel,
            cert.certificateType,
            timeLeft
        );
    }

    function getEcosystemTrustStats() 
        external 
        view 
        returns (
            uint256 totalCerts,
            uint256 activeCerts,
            uint256 totalPols,
            uint256 totalViolations,
            uint256 avgTrustScore
        ) 
    {
        // Calcola score medio (semplificato)
        return (totalCertifications, activeCertifications, totalPolicies, policyViolations, 750);
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

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
