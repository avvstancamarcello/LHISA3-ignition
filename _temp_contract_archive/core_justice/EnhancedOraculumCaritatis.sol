// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

/**
 * @title EnhancedOraculumCaritatis
 * @notice Sistema avanzato di verifica identità per aiuti umanitari:
 *         - registrazione enti verificatori (Caritas, ONG)
 *         - attestazione “BlessedSoul” con prove su IPFS (no dati sensibili on-chain)
 *         - statistiche per regione/contesto (guerre, disastri naturali)
 *         - integrazione (hook) con ReputationManager e Hub
 *         - emergenza: pausa e sospensione verificatori
 *
 * Sicurezza:
 *  - UUPS Upgradeable
 *  - AccessControl (DEFAULT_ADMIN_ROLE, VERIFICATOR_ROLE, AUDITOR_ROLE)
 *  - Pausable (emergenza)
 *  - NESSUN segreto on-chain: solo CID/pointer
 */

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract EnhancedOraculumCaritatis is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for address;

    // ───────────────────────── Roles ─────────────────────────
    bytes32 public constant VERIFICATOR_ROLE = keccak256("VERIFICATOR_ROLE");
    bytes32 public constant AUDITOR_ROLE     = keccak256("AUDITOR_ROLE");

    // ───────────────────────── Data ─────────────────────────
    struct BlessedSoul {
        bool    isPrivileged;
        uint256 blessingTimestamp;
        address verifiedBy;
        string  regionCode;        // es. "UA-12"
        string  crisisType;        // "war","earthquake","famine",...
        uint256 privilegeLevel;    // 1..10
        string  verificationCID;   // Prove su IPFS (no dati personali)
        uint256 lastVerification;
    }

    struct Verificator {
        string  organizationName;  // es. "Caritas Internationalis"
        string  regionAuthority;   // es. "Europe-Emergency"
        uint256 verificationCount;
        bool    isActive;
        string  credentialsCID;    // credenziali/verifiche su IPFS
    }

    mapping(address => BlessedSoul) public blessedSouls;        // wallet → stato
    mapping(address => Verificator) public verificators;        // verificatore → profilo
    mapping(string => address[]) public regionBlessedSouls;     // regione → elenco wallet

    // Riferimenti ecosistema
    address public solidaryHub;              // EnhancedSolidaryHub
    address public impactLogger;             // opzionale
    address public reputationManager;        // EnhancedReputationManager (opzionale)

    // Statistiche
    uint256 public totalBlessedSouls;
    uint256 public totalVerifications;

    // Storage pointers (NO secrets reali)
    string public ipfsBaseURI;

    // Eventi
    event SoulBlessed(address indexed soul, address indexed verificator, string region, string crisisType, string verificationCID);
    event BlessingUpdated(address indexed soul, uint256 newPrivilegeLevel);
    event BlessingRevoked(address indexed soul, address indexed by, string reason);
    event VerificatorRegistered(address indexed verificator, string organization);
    event VerificatorStatusChanged(address indexed verificator, bool isActive);
    event CrossChainVerification(address indexed soul, uint256 chainId, bool verified);
    event StorageConfigured(string ipfsBaseURI);
    event IntegrationLinked(address hub, address impactLogger, address reputationManager);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    // ───────────────────── Initialization ───────────────────
    function initialize(
        address admin,
        address _solidaryHub,
        address _impactLogger,
        address _reputationManager
    ) public initializer {
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(VERIFICATOR_ROLE, admin); // l’admin è il primo verificatore “bootstrap”
        _grantRole(AUDITOR_ROLE, admin);

        solidaryHub       = _solidaryHub;
        impactLogger      = _impactLogger;
        reputationManager = _reputationManager;

        emit IntegrationLinked(_solidaryHub, _impactLogger, _reputationManager);
    }

    // ───────────────────── Verificatori ─────────────────────
    function registerVerificator(
        address verificator,
        string memory organizationName,
        string memory regionAuthority,
        string memory credentialsData
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(verificator != address(0), "invalid verificator");

        string memory credentialsCID = _uploadToIPFS(bytes(credentialsData));
        verificators[verificator] = Verificator({
            organizationName: organizationName,
            regionAuthority: regionAuthority,
            verificationCount: 0,
            isActive: true,
            credentialsCID: credentialsCID
        });

        _grantRole(VERIFICATOR_ROLE, verificator);
        emit VerificatorRegistered(verificator, organizationName);
        emit VerificatorStatusChanged(verificator, true);
    }

    function setVerificatorActive(address verificator, bool active)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(verificators[verificator].organizationName.bytesLength() != 0, "not registered");
        verificators[verificator].isActive = active;
        if (!active && hasRole(VERIFICATOR_ROLE, verificator)) {
            // lasciamo il ruolo ma il flag attivo = false blocca le azioni
        }
        emit VerificatorStatusChanged(verificator, active);
    }

    // ───────────────────── Blessings ────────────────────────
    function blessSoul(
        address soul,
        string memory regionCode,
        string memory crisisType,
        uint256 privilegeLevel,
        string memory verificationData
    ) external whenNotPaused onlyRole(VERIFICATOR_ROLE) returns (string memory verificationCID) {
        require(soul != address(0), "invalid soul");
        require(privilegeLevel >= 1 && privilegeLevel <= 10, "privilege 1..10");
        require(verificators[msg.sender].isActive, "verificator inactive");

        verificationCID = _storeVerificationProof(verificationData);

        blessedSouls[soul] = BlessedSoul({
            isPrivileged: true,
            blessingTimestamp: block.timestamp,
            verifiedBy: msg.sender,
            regionCode: regionCode,
            crisisType: crisisType,
            privilegeLevel: privilegeLevel,
            verificationCID: verificationCID,
            lastVerification: block.timestamp
        });

        regionBlessedSouls[regionCode].push(soul);
        totalBlessedSouls++;
        verificators[msg.sender].verificationCount++;

        _logHumanitarianImpact(soul, regionCode, crisisType, privilegeLevel);
        _notifyReputationPositive(soul, privilegeLevel); // opzionale: +reputazione

        emit SoulBlessed(soul, msg.sender, regionCode, crisisType, verificationCID);
    }

    function updateBlessing(
        address soul,
        uint256 newPrivilegeLevel,
        string memory newVerificationData
    ) external whenNotPaused onlyRole(VERIFICATOR_ROLE) returns (string memory newCID) {
        require(blessedSouls[soul].isPrivileged, "no blessing");
        require(verificators[msg.sender].isActive, "verificator inactive");
        require(newPrivilegeLevel >= 1 && newPrivilegeLevel <= 10, "privilege 1..10");

        newCID = _storeVerificationProof(newVerificationData);
        blessedSouls[soul].privilegeLevel   = newPrivilegeLevel;
        blessedSouls[soul].verificationCID  = newCID;
        blessedSouls[soul].lastVerification = block.timestamp;
        totalVerifications++;

        _notifyReputationPositive(soul, (newPrivilegeLevel >= 7 ? 2 : 1));
        emit BlessingUpdated(soul, newPrivilegeLevel);
    }

    function revokeBlessing(address soul, string calldata reason)
        external
        onlyRole(AUDITOR_ROLE)
    {
        require(blessedSouls[soul].isPrivileged, "not blessed");
        blessedSouls[soul].isPrivileged = false;
        blessedSouls[soul].lastVerification = block.timestamp;
        _notifyReputationNegative(soul, 5); // penalità moderata
        emit BlessingRevoked(soul, msg.sender, reason);
    }

    // ───────────────────── Cross-chain log ──────────────────
    function verifySoulAcrossChains(
        address soul,
        uint256 chainId,
        bool isVerified
    ) external onlyRole(VERIFICATOR_ROLE) {
        require(verificators[msg.sender].isActive, "verificator inactive");
        blessedSouls[soul].lastVerification = block.timestamp;
        totalVerifications++;
        emit CrossChainVerification(soul, chainId, isVerified);
    }

    // ───────────────────── Views ────────────────────────────
    function getRegionStatistics(string memory regionCode)
        external
        view
        returns (uint256 totalSouls, uint256 averagePrivilegeLevel, string memory commonCrisisType)
    {
        address[] memory souls = regionBlessedSouls[regionCode];
        uint256 totalPrivilege = 0;
        uint256 activeCount = 0;
        for (uint256 i = 0; i < souls.length; i++) {
            BlessedSoul memory s = blessedSouls[souls[i]];
            if (s.isPrivileged) {
                totalPrivilege += s.privilegeLevel;
                activeCount++;
            }
        }
        totalSouls = souls.length;
        averagePrivilegeLevel = activeCount > 0 ? totalPrivilege / activeCount : 0;
        commonCrisisType = souls.length > 0 ? blessedSouls[souls[0]].crisisType : "none";
    }

    // ───────────────────── Integration & storage ────────────
    function linkIntegration(address _hub, address _impactLogger, address _reputationManager)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        solidaryHub       = _hub;
        impactLogger      = _impactLogger;
        reputationManager = _reputationManager;
        emit IntegrationLinked(_hub, _impactLogger, _reputationManager);
    }

    function configureStorage(string calldata _ipfsBaseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ipfsBaseURI = _ipfsBaseURI; // solo pointer; niente chiavi on-chain
        emit StorageConfigured(_ipfsBaseURI);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) { _unpause(); }

    // ───────────────────── Internal helpers ────────────────
    function _storeVerificationProof(string memory verificationData) internal view returns (string memory) {
        // salvare SOLO un CID/IPFS-friendly JSON con prove off-chain
        bytes memory proofData = abi.encodePacked(
            '{"verifier":"', _addrToString(msg.sender),
            '","timestamp":', block.timestamp.toString(),
            ',"data":"', verificationData, '"}'
        );
        return _uploadToIPFS(proofData);
    }

    function _logHumanitarianImpact(
        address soul,
        string memory regionCode,
        string memory crisisType,
        uint256 privilegeLevel
    ) internal {
        if (impactLogger != address(0)) {
            // placeholder: in produzione, chiama il logger con ABI concreta
            // bytes memory payload = abi.encodeWithSignature(
            //   "logImpact(string,string,string,uint256,uint256,string,uint256,string)",
            //   "humanitarian","identity_verification",
            //   string(abi.encodePacked("Verified soul in ", regionCode)),
            //   1, 0, regionCode, 1, "humanitarian_verification"
            // );
            // (bool ok,) = impactLogger.call(payload);
            // ok; // ignore
            soul; regionCode; crisisType; privilegeLevel;
        }
    }

    function _notifyReputationPositive(address subject, uint256 magnitude) internal {
        if (reputationManager != address(0)) {
            // bytes memory payload = abi.encodeWithSignature(
            //   "attest(address,int256,uint256,string,string)",
            //   subject, int256(10 * magnitude), 10, "identity", "" // delta, weight
            // );
            // (bool ok,) = reputationManager.call(payload);
            // ok;
            subject; magnitude;
        }
    }

    function _notifyReputationNegative(address subject, uint256 magnitude) internal {
        if (reputationManager != address(0)) {
            // bytes memory payload = abi.encodeWithSignature(
            //   "attest(address,int256,uint256,string,string)",
            //   subject, -int256(10 * magnitude), 10, "identity", ""
            // );
            // (bool ok,) = reputationManager.call(payload);
            // ok;
            subject; magnitude;
        }
    }

    function _uploadToIPFS(bytes memory data) internal view returns (string memory cid) {
        // simulazione: genera un “CID” deterministic-like (NO upload reale on-chain)
        bytes32 hash = keccak256(abi.encodePacked(data, block.timestamp, totalBlessedSouls));
        cid = string(abi.encodePacked("simulated:ipfs:", _bytes32ToHex(hash)));
        return cid;
    }

    // ───────────────────── Utils ───────────────────────────
    function _bytes32ToHex(bytes32 v) internal pure returns (string memory) {
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
        return v < 10 ? bytes1(v + 0x30) : bytes1(v + 0x57);
    }
    function _addrToString(address a) internal pure returns (string memory) {
        return StringsUpgradeable.toHexString(uint256(uint160(a)), 20);
    }

    // ───────────────────── UUPS auth ───────────────────────
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
