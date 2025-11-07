// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/**
 * SolidaryMetrics.sol
 *
 * Upgradeable metrics contract that reads configuration from an orchestrator,
 * creates snapshots (with simulated IPFS upload), and stores snapshot metadata on-chain.
 *
 * Security / design:
 * - Uses AccessControlUpgradeable for roles
 * - Uses UUPSUpgradeable for upgrades; only admin role can authorize upgrades
 * - Snapshot creation is restricted by role and by a minimum interval to avoid spam
 * - Does not store secrets on-chain; orchestrator holds pointers/config
 *
 * NOTE: _uploadToIPFSSimulated is a placeholder. In production:
 *  - do the actual upload off-chain (backend on Heroku or similar) using the
 *    API keys stored securely (off-chain)
 *  - then call registerExternalCID(snapshotId, realCid) to store the real CID on-chain
 */

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

interface ISolidaryOrchestrator {
    function totalQuantumLinks() external view returns (uint256);
    function totalStellarValue() external view returns (uint256);

    // optional helpers that orchestrator may expose
    function getStorageConfig() external view returns (string memory nftStorageKey, string memory pinataJWT);
    function nftPlanetContract() external view returns (address);
    function ftSatelliteContract() external view returns (address);
}

contract SolidaryMetrics is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Roles
    bytes32 public constant SNAPSHOT_CREATOR_ROLE = keccak256("SNAPSHOT_CREATOR_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE"); // reserved for future use

    CountersUpgradeable.Counter private _snapshotIdCounter;

    ISolidaryOrchestrator public orchestrator;

    uint256 public snapshotIntervalSeconds; // minimum time between snapshots
    uint256 public lastSnapshotTimestamp;

    struct Snapshot {
        uint256 id;
        uint256 totalQuantumLinks;
        uint256 totalStellarValue;
        uint256 timestamp;
        string cid; // simulated/registered CID
    }

    mapping(uint256 => Snapshot) private snapshots;
    uint256 public totalSnapshots;

    // Events
    event SnapshotCreated(uint256 indexed id, string cid, uint256 timestamp);
    event OrchestratorUpdated(address indexed orchestrator);
    event SnapshotIntervalUpdated(uint256 newInterval);
    event ExternalCIDRegistered(uint256 indexed id, string cid, address indexed registrar);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin, address initialOrchestrator, uint256 initialIntervalSeconds) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(SNAPSHOT_CREATOR_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);

        snapshotIntervalSeconds = initialIntervalSeconds;
        orchestrator = ISolidaryOrchestrator(initialOrchestrator);

        emit OrchestratorUpdated(initialOrchestrator);
    }

    // ---------- Admin / Config ----------

    /**
     * Set orchestrator address (only admin)
     * Best practice: set this to the Orchestrator contract after Orchestrator deployment.
     */
    function setOrchestrator(address _orchestrator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        orchestrator = ISolidaryOrchestrator(_orchestrator);
        emit OrchestratorUpdated(_orchestrator);
    }

    function setSnapshotInterval(uint256 secondsInterval) external onlyRole(DEFAULT_ADMIN_ROLE) {
        snapshotIntervalSeconds = secondsInterval;
        emit SnapshotIntervalUpdated(secondsInterval);
    }

    // ---------- Snapshot Logic ----------

    /**
     * createSnapshot
     * - reads metrics from orchestrator (if configured)
     * - generates a simulated IPFS CID deterministically
     * - stores minimal metadata on-chain and emits event
     *
     * Access: only role SNAPSHOT_CREATOR_ROLE to avoid spam and keep control
     * Rate limiting: enforces snapshotIntervalSeconds between snapshots
     */
    function createSnapshot(string calldata extraNote) external onlyRole(SNAPSHOT_CREATOR_ROLE) returns (uint256) {
        // ensure interval
        require(block.timestamp >= lastSnapshotTimestamp + snapshotIntervalSeconds, "SolidaryMetrics: snapshot interval not passed");

        uint256 qLinks = 0;
        uint256 sValue = 0;

        // Try reading from orchestrator if set
        if (address(orchestrator) != address(0)) {
            // fetching safely using external calls (will revert if orchestrator misbehaves)
            qLinks = orchestrator.totalQuantumLinks();
            sValue = orchestrator.totalStellarValue();
        }

        // prepare snapshot payload (data used to compute simulated CID)
        bytes memory payload = abi.encodePacked(
            block.timestamp,
            qLinks,
            sValue,
            msg.sender,
            extraNote,
            _snapshotIdCounter.current()
        );

        string memory cid = _uploadToIPFSSimulated(payload);

        // increment id
        _snapshotIdCounter.increment();
        uint256 newId = _snapshotIdCounter.current();

        Snapshot memory s = Snapshot({
            id: newId,
            totalQuantumLinks: qLinks,
            totalStellarValue: sValue,
            timestamp: block.timestamp,
            cid: cid
        });

        snapshots[newId] = s;
        totalSnapshots++;
        lastSnapshotTimestamp = block.timestamp;

        emit SnapshotCreated(newId, cid, block.timestamp);
        return newId;
    }

    // Getter
    function getSnapshot(uint256 id) external view returns (Snapshot memory) {
        require(id > 0 && id <= _snapshotIdCounter.current(), "SolidaryMetrics: snapshot not found");
        return snapshots[id];
    }

    function latestSnapshotId() external view returns (uint256) {
        return _snapshotIdCounter.current();
    }

    // ---------- Simulated IPFS upload ----------
    // In production, remove simulation: do off-chain upload and call registerExternalCID.

    function _uploadToIPFSSimulated(bytes memory data) internal view returns (string memory) {
        // deterministic pseudo-CID based on keccak256 hash
        bytes32 h = keccak256(data);
        // Convert bytes32 to hex string via uint conversion and StringsUpgradeable
        string memory hexstr = StringsUpgradeable.toHexString(uint256(h), 32);
        return string(abi.encodePacked("simulated:ipfs:", hexstr));
    }

    /**
     * registerExternalCID
     * - admin-only function to update a snapshot with the real CID produced off-chain.
     * - use off-chain backend (Heroku) to upload to NFT.Storage / Pinata and then call this.
     */
    function registerExternalCID(uint256 snapshotId, string calldata realCid) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(snapshotId > 0 && snapshotId <= _snapshotIdCounter.current(), "SolidaryMetrics: snapshot not found");
        snapshots[snapshotId].cid = realCid;
        emit ExternalCIDRegistered(snapshotId, realCid, msg.sender);
        emit SnapshotCreated(snapshotId, realCid, snapshots[snapshotId].timestamp);
    }

    // ---------- Upgradeability ----------
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    // ---------- Helpers ----------
    // Allow the admin to pull a quick summary from orchestrator (view)
    function readOrchestratorSummary() external view returns (
        uint256 qLinks,
        uint256 sValue,
        address nftPlanet,
        address ftSatellite
    ) {
        if (address(orchestrator) == address(0)) {
            return (0, 0, address(0), address(0));
        }
        qLinks = orchestrator.totalQuantumLinks();
        sValue = orchestrator.totalStellarValue();
        nftPlanet = orchestrator.nftPlanetContract();
        ftSatellite = orchestrator.ftSatelliteContract();
    }
}
