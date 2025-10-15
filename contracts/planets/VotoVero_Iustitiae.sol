// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

// Copyright © 2025 Avv. Marcello Stanca - Firenze, Italia. All Rights Reserved.

// Hoc contractum, pars 'Solidary System',ab Auctore Marcello Stanca Caritas Internationalis (MCMLXXVI) conceditur.
// (This smart contract, part of the 'Solidary System', is granted for free use to Caritas Internationalis (1976) by the author, Marcello Stanca.)

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../core_justice/RefundManager.sol";
import "../core_justice/OraculumCaritatis.sol"; // SINAPSIS CONSECRATA: Importamus Oraculum

/**
 * @title VotoVero_Iustitiae (The True Vote of Justice)
 * @author Avv. Marcello Stanca - Architectus Aequitatis (Architect of Justice)
 * @notice Systema suffragii quod non solum veritatem custodit, sed etiam iustitiam operatur, dirigens valorem ad eos qui maxime indigent.
 * (English: A voting system that not only guards the truth, but also enacts justice, directing value to those most in need.)
 * @dev Hoc est primum "neuron" Oecosystematis 'Solidary System', quod cum Oraculo Caritatis communicat ad Legem Resistentiae et Machinamentum Iustitiae applicandum. Sicut nervus qui cor cum cerebro coniungit, sic hic codex oeconomiam cum compassione coniungit.
 * (English: This is the first "neuron" of the Solidary System, communicating with the Oracle of Compassion to apply the Law of Resistance and the Mechanism of Justice. Like a nerve that connects the heart to the brain, so this code connects economy with compassion.)
 */
contract VotoVero_Iustitiae is
    Initializable,
    ERC20Upgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    RefundManager
{
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏛️ MUNERA ET LEGES AETHEREAE (ROLES & ETHEREAL LAWS)
    // ═══════════════════════════════════════════════════════════════════════════════

    bytes32 public constant ELECTION_ADMIN_ROLE = keccak256("ELECTION_ADMIN_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    uint256 public constant VERO_TOKEN_REWARD = 50 * 10**18;
    uint256 public constant MIN_STAKE_VOTER = 10 * 10**18;
    
    uint256 public constant SPECULATIVE_LOCK_DURATION = 30 days;
    uint256 public constant SOLIDARITY_TITHE_PERCENTAGE = 2; // 2% tax

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🧠 STATUS NEURALIS ET TABULAE IUSTITIAE (NEURAL STATE & LEDGERS OF JUSTICE)
    // ═══════════════════════════════════════════════════════════════════════════════

    OraculumCaritatis public oraculumCaritatis;
    mapping(address => uint256) public tokenLockReleaseTime;
    uint256 public fundumIustitiae;

    enum ElectionStatus { CREATED, ACTIVE, ENDED, CANCELLED }

    struct Election {
        bytes32 electionId;
        string title;
        address administrator;
        uint256 creationTime;
        uint256 votingStart;
        uint256 votingEnd;
        ElectionStatus status;
        uint256 totalVotes;
        string[] options;
        mapping(string => uint256) optionVotes;
        mapping(address => bool) hasVoted;
    }

    mapping(bytes32 => Election) public elections;
    bytes32[] public allElections;

    // ═══════════════════════════════════════════════════════════════════════════════
    // 📢 NUNTII (EVENTS)
    // ═══════════════════════════════════════════════════════════════════════════════

    event ElectionCreated(bytes32 indexed electionId, string title, address indexed administrator);
    event VoteCast(bytes32 indexed electionId, address indexed voter, string option);
    event ElectionEnded(bytes32 indexed electionId, string winner, uint256 totalVotes);
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏗️ INITIALIZATION (INITIUM OPERIS)
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _creatorWallet,
        address _solidaryWallet,
        uint256 _refundDeadline,
        uint256 _initialThreshold,
        address _emergencyController,
        address _oraculumAddress
    ) public initializer {
        __ERC20_init("VotoVero Iustitiae Token", "VERO");
        __RefundManager_init(_creatorWallet, _solidaryWallet, _refundDeadline, _initialThreshold);
        __AccessControl_init();
        __UUPSUpgradeable_init();

        oraculumCaritatis = OraculumCaritatis(_oraculumAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ELECTION_ADMIN_ROLE, msg.sender);
        _grantRole(EMERGENCY_ROLE, _emergencyController);

        _mint(address(this), 10_000_000 * 10**decimals());
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // ❤️ COR MACHINAE IUSTITIAE (THE HEART OF THE JUSTICE MACHINE)
    // ═══════════════════════════════════════════════════════════════════════════════

    
    /**
     * @notice Pecuniam movet, non modo ut res, sed ut instrumentum iustitiae et caritatis.
     * (English: Moves tokens, not merely as an asset, but as an instrument of justice and charity.)
     * @dev Haec est versio nostra centralis functionis "_update". Hic, coram omni motu valoris, interrogamus Oraculum et Leges Aethereas applicamus.
     * (English: This is our central override of the "_update" function. Here, before every movement of value, we question the Oracle and apply the Ethereal Laws.)
     */
    function _update(address from, address to, uint256 amount) internal override {
        // --- PRIMA LEX: Lex Resistentiae (The Law of Resistance) ---
        if (!oraculumCaritatis.isSoulBlessed(from)) {
            if (from != address(0) && to != address(0)) {
                require(block.timestamp >= tokenLockReleaseTime[from], "PatientiaPactum: Speculative lock is active");
            }
        }

        // --- SECUNDA LEX: Machinamentum Iustitiae (The Mechanism of Justice) ---
        if (!oraculumCaritatis.isSoulBlessed(from) && from != address(0) && to != address(0)) {
            uint256 tithe = (amount * SOLIDARITY_TITHE_PERCENTAGE) / 100;
            if (tithe > 0) {
                fundumIustitiae += tithe;
                uint256 transferAmount = amount - tithe;
                super._update(from, to, transferAmount);
            } else {
                 super._update(from, to, amount);
            }
        } else {
            super._update(from, to, amount);
        }

        // --- REGISTRUM TEMPORIS (TIME LEDGER) ---
        if (from == address(0) && to != address(0) && !oraculumCaritatis.isSoulBlessed(to)) {
            tokenLockReleaseTime[to] = block.timestamp + SPECULATIVE_LOCK_DURATION;
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🗳️ GESTIO SUFFRAGIORUM (ELECTION MANAGEMENT)
    // ═══════════════════════════════════════════════════════════════════════════════

    function createElection(
        string memory title,
        uint256 votingDuration,
        string[] memory options
    ) external onlyRole(ELECTION_ADMIN_ROLE) nonReentrant returns (bytes32) {
        require(bytes(title).length > 0, "Title required");
        require(options.length >= 2, "At least 2 options required");

        bytes32 electionId = keccak256(abi.encodePacked(title, msg.sender, block.timestamp));

        Election storage newElection = elections[electionId];
        newElection.electionId = electionId;
        newElection.title = title;
        newElection.administrator = msg.sender;
        newElection.creationTime = block.timestamp;
        newElection.votingStart = block.timestamp;
        newElection.votingEnd = block.timestamp + votingDuration;
        newElection.status = ElectionStatus.ACTIVE;
        newElection.options = options;

        allElections.push(electionId);
        emit ElectionCreated(electionId, title, msg.sender);
        return electionId;
    }

    function castVote(bytes32 electionId, string memory option) external nonReentrant {
        Election storage election = elections[electionId];
        
        require(election.status == ElectionStatus.ACTIVE, "Election not active");
        require(block.timestamp <= election.votingEnd, "Voting ended");
        require(!election.hasVoted[msg.sender], "Already voted");
        require(balanceOf(msg.sender) >= MIN_STAKE_VOTER, "Insufficient stake to vote");

        bool validOption = false;
        for (uint i = 0; i < election.options.length; i++) {
            if (keccak256(bytes(election.options[i])) == keccak256(bytes(option))) {
                validOption = true;
                break;
            }
        }
        require(validOption, "Invalid option");

        election.hasVoted[msg.sender] = true;
        election.optionVotes[option]++;
        election.totalVotes++;

        // Ricompensa per il voto
        _transfer(address(this), msg.sender, VERO_TOKEN_REWARD);

        emit VoteCast(electionId, msg.sender, option);
    }
    
    // ... Altre funzioni di gestione e visualizzazione possono essere aggiunte qui ...

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔄 AUCTORITAS EMENDANDI (UPGRADEABILITY)
    // ═══════════════════════════════════════════════════════════════════════════════

    function _authorizeUpgrade(address newImplementation) internal override(RefundManager, UUPSUpgradeable) onlyRole(DEFAULT_ADMIN_ROLE) {}
}
