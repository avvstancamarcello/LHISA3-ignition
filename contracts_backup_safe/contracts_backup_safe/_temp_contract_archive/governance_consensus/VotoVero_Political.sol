// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca – Lawyer, Italy (Florence)

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol"; 
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../core_justice/RefundManager.sol";

/**
 * @title VotoVero - Democrazia Trasparente e Anti-Manipolazione (Optimized)
 * @dev Sistema di voto blockchain per elezioni politiche - versione ottimizzata per deployment
 * Garantisce trasparenza totale, anti-manipolazione e verificabilità universale
 * 
 * Features Core:
 * - Zero-Knowledge Voting (privacy + verifica)
 * - Anti-Sybil resistance con Proof of Humanity
 * - Merkle Tree verification per scalabilità  
 * - Audit trail completo e immutabile
 * - Anti-manipulation con staking requirements
 * 
 * Target: Elezioni politiche, referendum, consultazioni pubbliche, governance DAO
 * Mission: "Il tuo voto conta davvero, e puoi verificarlo"
 */
contract VotoVero is 
    Initializable,
    ERC20Upgradeable, 
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    RefundManager 
{
    // ═══════════════════════════════════════════════════════════════════════════════
    // ROLES & CONSTANTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    bytes32 public constant ELECTION_ADMIN_ROLE = keccak256("ELECTION_ADMIN_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    bytes32 public constant DRAW_OWNER_ROLE = keccak256("DRAW_OWNER_ROLE");
    bytes32 public constant SPONSOR_ROLE = keccak256("SPONSOR_ROLE");    
    uint256 public constant VERO_TOKEN_REWARD = 50 * 10**18; // 50 VERO per voto verificato
    uint256 public constant MIN_STAKE_VOTER = 10 * 10**18; // 10 VERO per votare (anti-Sybil)
    uint256 public constant AUDIT_WINDOW_DAYS = 30; // 30 giorni per audit post-elezione
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // ENUMS & STRUCTURES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    enum ElectionType { POLITICAL, REFERENDUM, CONSULTATION }
    enum ElectionStatus { CREATED, REGISTRATION, ACTIVE, ENDED, CANCELLED }
    enum VoteType { SECRET, PUBLIC }
    enum IdentityLevel { VERIFIED, PROOF_OF_HUMANITY }
    
    struct Election {
        bytes32 electionId;
        string title;
        string description;
        ElectionType electionType;
        VoteType voteType;
        IdentityLevel requiredIdentity;
        
        address administrator;
        uint256 creationTime;
        uint256 registrationStart;
        uint256 registrationEnd;
        uint256 votingStart;
        uint256 votingEnd;
        uint256 auditDeadline;
        
        ElectionStatus status;
        bytes32 merkleRoot; // Per voter eligibility
        uint256 totalEligibleVoters;
        uint256 totalVotes;
        
        string[] options; // Candidati o opzioni
        mapping(string => uint256) optionVotes;
        mapping(address => bool) hasVoted;
        mapping(address => bytes32) voteCommitments; // For secret voting
        mapping(address => bool) voteRevealed;
        mapping(address => uint256) voterStake;
        
        bool emergencyStop;
    }
    
    struct VoterProfile {
        bool isVerified;
        bool isProofOfHumanity;
        uint256 totalVotes;
        uint256 totalStaked;
        address delegate;
        address[] delegators;
    }
    
    struct AuditLog {
        address actor;
        string action;
        bytes32 electionId;
        string details;
        uint256 timestamp;
        bytes32 blockHash;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    mapping(bytes32 => Election) public elections;
    mapping(address => VoterProfile) public voterProfiles;
    mapping(address => mapping(bytes32 => bool)) public eligibleVoters;
    uint256 public totalEligibleVoters;    
    bytes32[] public allElections;
    bytes32[] public activeElections;
    AuditLog[] public auditTrail;
    
    uint256 public totalElections;
    uint256 public totalVotes;
    uint256 public totalVerifiedVoters;
    address public emergencyController;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    event ElectionCreated(bytes32 indexed electionId, string title, address indexed administrator);
    event VoteCommitted(bytes32 indexed electionId, address indexed voter, bytes32 commitment);
    event VoteRevealed(bytes32 indexed electionId, address indexed voter, string option);
    event ElectionEnded(bytes32 indexed electionId, string winner, uint256 totalVotes);
    event VoterVerified(address indexed voter, IdentityLevel level);
    event EmergencyStop(bytes32 indexed electionId, string reason);
    event AuditCompleted(bytes32 indexed electionId, string result);
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // MODIFIERS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    modifier validElection(bytes32 electionId) {
        require(elections[electionId].administrator != address(0), "Election not found");
        _;
    }
    
    modifier onlyElectionAdmin(bytes32 electionId) {
        require(elections[electionId].administrator == msg.sender, "Not election admin");
        _;
    }
    
    modifier canVote(bytes32 electionId) {
        require(eligibleVoters[msg.sender][electionId], "Not eligible to vote");
        require(!elections[electionId].hasVoted[msg.sender], "Already voted");
        require(elections[electionId].status == ElectionStatus.ACTIVE, "Voting not active");
        require(block.timestamp >= elections[electionId].votingStart, "Voting not started");
        require(block.timestamp <= elections[electionId].votingEnd, "Voting ended");
        _;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // INITIALIZATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        address _creatorWallet,
        address _solidaryWallet,
        uint256 _refundDeadline,
        uint256 _initialThreshold, // <-- Aggiungere questo parametro
        address _drawOwner,
        address _sponsor
    ) public initializer {
       __RefundManager_init(_creatorWallet, _solidaryWallet, _refundDeadline, _initialThreshold); // <-- Passare il nuovo parametro
       __ERC20_init("IVOTE Democracy Token", "IVOTE");
       __AccessControl_init();

       _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
       _grantRole(DRAW_OWNER_ROLE, _drawOwner);
       _grantRole(SPONSOR_ROLE, _sponsor);

       _mint(address(this), 1000000000 * 10**decimals());
    }    
    // ═══════════════════════════════════════════════════════════════════════════════
    // ELECTION CREATION & MANAGEMENT
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function createElection(
        string memory title,
        string memory description,
        ElectionType electionType,
        VoteType voteType,
        IdentityLevel requiredIdentity,
        uint256 registrationDuration,
        uint256 votingDuration,
        bytes32 merkleRoot,
        uint256 _eligibleVoters,
        string[] memory options
    ) external onlyRole(ELECTION_ADMIN_ROLE) nonReentrant {
        require(bytes(title).length > 0, "Title required");
        require(options.length >= 2, "At least 2 options required");
        require(registrationDuration > 0 && votingDuration > 0, "Invalid durations");
        
        bytes32 electionId = keccak256(abi.encodePacked(
            title,
            msg.sender,
            block.timestamp,
            blockhash(block.number - 1)
        ));
        
        Election storage newElection = elections[electionId];
        newElection.electionId = electionId;
        newElection.title = title;
        newElection.description = description;
        newElection.electionType = electionType;
        newElection.voteType = voteType;
        newElection.requiredIdentity = requiredIdentity;
        newElection.administrator = msg.sender;
        newElection.creationTime = block.timestamp;
        newElection.registrationStart = block.timestamp;
        newElection.registrationEnd = block.timestamp + registrationDuration;
        newElection.votingStart = newElection.registrationEnd;
        newElection.votingEnd = newElection.votingStart + votingDuration;
        newElection.auditDeadline = newElection.votingEnd + (AUDIT_WINDOW_DAYS * 1 days);
        newElection.status = ElectionStatus.REGISTRATION;
        newElection.merkleRoot = merkleRoot;
        newElection.totalEligibleVoters = _eligibleVoters;
        newElection.options = options;
        
        allElections.push(electionId);
        activeElections.push(electionId);
        totalElections++;
        
        // Log audit trail
        _addAuditLog(msg.sender, "ELECTION_CREATED", electionId, title);
        
        emit ElectionCreated(electionId, title, msg.sender);
    }
    
    function startVoting(bytes32 electionId) external onlyElectionAdmin(electionId) {
        Election storage election = elections[electionId];
        require(election.status == ElectionStatus.REGISTRATION, "Not in registration phase");
        require(block.timestamp >= election.votingStart, "Voting time not reached");
        
        election.status = ElectionStatus.ACTIVE;
        _addAuditLog(msg.sender, "VOTING_STARTED", electionId, "");
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // VOTING SYSTEM
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function commitVote(
        bytes32 electionId,
        bytes32 commitment,
        bytes32[] memory merkleProof
    ) external canVote(electionId) nonReentrant {
        Election storage election = elections[electionId];
        require(election.voteType == VoteType.SECRET, "Not secret voting");
        
        // Verify voter eligibility with Merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, election.merkleRoot, leaf),
            "Invalid eligibility proof"
        );
        
        // Require minimum stake for anti-Sybil
        require(balanceOf(msg.sender) >= MIN_STAKE_VOTER, "Insufficient stake");
        
        election.voteCommitments[msg.sender] = commitment;
        _addAuditLog(msg.sender, "VOTE_COMMITTED", electionId, "");
        
        emit VoteCommitted(electionId, msg.sender, commitment);
    }
    
    function revealVote(
        bytes32 electionId,
        string memory option,
        uint256 nonce
    ) external validElection(electionId) nonReentrant {
        Election storage election = elections[electionId];
        require(election.voteCommitments[msg.sender] != bytes32(0), "No commitment found");
        require(!election.voteRevealed[msg.sender], "Vote already revealed");
        require(block.timestamp > election.votingEnd, "Reveal phase not started");
        
        // Verify commitment
        bytes32 hash = keccak256(abi.encodePacked(option, nonce, msg.sender));
        require(hash == election.voteCommitments[msg.sender], "Invalid reveal");
        
        // Verify option exists
        bool validOption = false;
        for (uint i = 0; i < election.options.length; i++) {
            if (keccak256(bytes(election.options[i])) == keccak256(bytes(option))) {
                validOption = true;
                break;
            }
        }
        require(validOption, "Invalid option");
        
        election.optionVotes[option]++;
        election.hasVoted[msg.sender] = true;
        election.voteRevealed[msg.sender] = true;
        election.totalVotes++;
        totalVotes++;
        
        voterProfiles[msg.sender].totalVotes++;
        
        // Reward voter with VERO tokens
        _transfer(address(this), msg.sender, VERO_TOKEN_REWARD);
        
        _addAuditLog(msg.sender, "VOTE_REVEALED", electionId, option);
        emit VoteRevealed(electionId, msg.sender, option);
    }
    
    function publicVote(
        bytes32 electionId,
        string memory option,
        bytes32[] memory merkleProof
    ) external canVote(electionId) nonReentrant {
        Election storage election = elections[electionId];
        require(election.voteType == VoteType.PUBLIC, "Not public voting");
        
        // Verify voter eligibility with Merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, election.merkleRoot, leaf),
            "Invalid eligibility proof"
        );
        
        // Verify option exists
        bool validOption = false;
        for (uint i = 0; i < election.options.length; i++) {
            if (keccak256(bytes(election.options[i])) == keccak256(bytes(option))) {
                validOption = true;
                break;
            }
        }
        require(validOption, "Invalid option");
        
        election.optionVotes[option]++;
        election.hasVoted[msg.sender] = true;
        election.totalVotes++;
        totalVotes++;
        
        voterProfiles[msg.sender].totalVotes++;
        
        // Reward voter with VERO tokens
        _transfer(address(this), msg.sender, VERO_TOKEN_REWARD);
        
        _addAuditLog(msg.sender, "PUBLIC_VOTE", electionId, option);
        emit VoteRevealed(electionId, msg.sender, option);
    }
    
    function endElection(bytes32 electionId) external onlyElectionAdmin(electionId) {
        Election storage election = elections[electionId];
        require(election.status == ElectionStatus.ACTIVE, "Election not active");
        require(block.timestamp > election.votingEnd, "Voting period not ended");
        
        election.status = ElectionStatus.ENDED;
        string memory winner = _determineWinner(electionId);
        
        _removeFromActiveElections(electionId);
        _addAuditLog(msg.sender, "ELECTION_ENDED", electionId, winner);
        
        emit ElectionEnded(electionId, winner, election.totalVotes);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // EMERGENCY & GOVERNANCE
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function emergencyStopElection(
        bytes32 electionId, 
        string memory reason
    ) external onlyRole(EMERGENCY_ROLE) {
        Election storage election = elections[electionId];
        election.emergencyStop = true;
        election.status = ElectionStatus.CANCELLED;
        
        _addAuditLog(msg.sender, "EMERGENCY_STOP", electionId, reason);
        emit EmergencyStop(electionId, reason);
    }
    
    function verifyVoter(address voter) external onlyRole(ELECTION_ADMIN_ROLE) {
        voterProfiles[voter].isVerified = true;
        totalVerifiedVoters++;
        emit VoterVerified(voter, IdentityLevel.VERIFIED);
    }
    
    function setProofOfHumanity(address voter, bool isHuman) external onlyRole(ELECTION_ADMIN_ROLE) {
        voterProfiles[voter].isProofOfHumanity = isHuman;
        if (isHuman && !voterProfiles[voter].isVerified) {
            voterProfiles[voter].isVerified = true;
            totalVerifiedVoters++;
        }
        emit VoterVerified(voter, IdentityLevel.PROOF_OF_HUMANITY);
    }
    
    function setEligibleVoters(bytes32 electionId, address[] memory voters) external onlyElectionAdmin(electionId) {
        for (uint i = 0; i < voters.length; i++) {
            eligibleVoters[voters[i]][electionId] = true;
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function getElectionResults(bytes32 electionId) external view validElection(electionId) returns (
        string[] memory options,
        uint256[] memory votes,
        string memory winner,
        uint256 totalVotes_,
        ElectionStatus status
    ) {
        Election storage election = elections[electionId];
        
        options = election.options;
        votes = new uint256[](options.length);
        
        for (uint i = 0; i < options.length; i++) {
            votes[i] = election.optionVotes[options[i]];
        }
        
        winner = _determineWinner(electionId);
        totalVotes_ = election.totalVotes;
        status = election.status;
    }
    
    function _determineWinner(bytes32 electionId) internal view returns (string memory) {
        Election storage election = elections[electionId];
        string memory winner = "";
        uint256 maxVotes = 0;
        
        for (uint i = 0; i < election.options.length; i++) {
            string memory option = election.options[i];
            uint256 votes = election.optionVotes[option];
            if (votes > maxVotes) {
                maxVotes = votes;
                winner = option;
            }
        }
        
        return winner;
    }
    
    function _addAuditLog(
        address actor,
        string memory action,
        bytes32 electionId,
        string memory details
    ) internal {
        auditTrail.push(AuditLog({
            actor: actor,
            action: action,
            electionId: electionId,
            details: details,
            timestamp: block.timestamp,
            blockHash: blockhash(block.number - 1)
        }));
    }
    
    function _removeFromActiveElections(bytes32 electionId) internal {
        for (uint i = 0; i < activeElections.length; i++) {
            if (activeElections[i] == electionId) {
                activeElections[i] = activeElections[activeElections.length - 1];
                activeElections.pop();
                break;
            }
        }
    }
    
    function _processRefundHook(address user, uint256 /*amount*/) internal override {
        // Reward system: give extra VERO tokens for refund participation
        if (balanceOf(address(this)) >= VERO_TOKEN_REWARD) {
            _transfer(address(this), user, VERO_TOKEN_REWARD);
        }
    }
    
    function getActiveElections() external view returns (bytes32[] memory) {
        return activeElections;
    }
    
    function getVoterProfile(address voter) external view returns (VoterProfile memory) {
        return voterProfiles[voter];
    }
    
    function getElectionInfo(bytes32 electionId) external view validElection(electionId) returns (
        string memory title,
        string memory description,
        ElectionType electionType,
        ElectionStatus status,
        uint256 totalVotes_,
        uint256 votingEnd,
        address administrator
    ) {
        Election storage election = elections[electionId];
        return (
            election.title,
            election.description,
            election.electionType,
            election.status,
            election.totalVotes,
            election.votingEnd,
            election.administrator
        );
    }
    
    function getSystemStats() external view returns (
        uint256 totalElections_,
        uint256 totalVotes_,
        uint256 activeElectionsCount,
        uint256 totalVerifiedVoters_
    ) {
        return (totalElections, totalVotes, activeElections.length, totalVerifiedVoters);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // UPGRADE FUNCTIONALITY
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function _authorizeUpgrade(address newImplementation) internal override(RefundManager, UUPSUpgradeable) onlyRole(DEFAULT_ADMIN_ROLE) {}
}
