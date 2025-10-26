// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca – Lawyer, Italy (Florence)

import "../core_justice/RefundManager.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title IVOTE_V2_WithRefund
 * @author Avv. Marcello Stanca - Solidary Network Architect
 * @notice Sistema elettorale anti-manipolazione con protezione refund integrata
 * @dev Upgrade del sistema IVOTE con RefundManager per protezione investitori
 * 
 * 🗳️ IVOTE + REFUND SYSTEM:
 * - Democrazia trasparente su blockchain
 * - Protezione acquirenti con soglia globale 100.000 EUR
 * - Refund automatico se ecosistema Solidary non raggiunge target
 * - Royalty distribuite automaticamente (5% + 5% + 2%)
 * 
 * 🛡️ ANTI-MANIPULATION + INVESTOR PROTECTION:
 * Combina sicurezza elettorale con garanzie economiche
 */
contract IVOTE_V2_WithRefund is RefundManager, ERC20Upgradeable, AccessControlUpgradeable {
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🗳️ IVOTE SPECIFIC ROLES & CONSTANTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    bytes32 public constant DRAW_OWNER_ROLE = keccak256("DRAW_OWNER_ROLE");
    bytes32 public constant SPONSOR_ROLE = keccak256("SPONSOR_ROLE");
    bytes32 public constant CANDIDATE_ROLE = keccak256("CANDIDATE_ROLE");
    
    /// @notice Prezzo per NFT Voter (0.001 ETH)
    uint256 public constant VOTER_NFT_PRICE = 0.001 ether;
    
    /// @notice Soglia manipolazione (5%)
    uint256 public constant MANIPULATION_THRESHOLD = 5;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 ELECTION MANAGEMENT
    // ═══════════════════════════════════════════════════════════════════════════════
    
    struct Election {
        bytes32 id;
        string name;
        string description;
        uint256 startTime;
        uint256 endTime;
        bool active;
        uint256 totalVotes;
        mapping(address => uint256) candidateVotes;
        address[] candidates;
        bool resultsSubmitted;
        mapping(address => uint256) officialResults;
        bool manipulationDetected;
    }
    
    /// @notice Mapping delle elezioni
    mapping(bytes32 => Election) public elections;
    
    /// @notice Array delle elezioni attive
    bytes32[] public activeElections;
    
    /// @notice Mapping dei voti per utente per elezione
    mapping(bytes32 => mapping(address => uint256)) public userVotes;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📢 EVENTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    event ElectionCreated(bytes32 indexed electionId, string name, uint256 startTime, uint256 endTime);
    event VoteCast(bytes32 indexed electionId, address indexed voter, address indexed candidate, uint256 amount);
    event CandidateAdded(bytes32 indexed electionId, address indexed candidate, string name);
    event OfficialResultsSubmitted(bytes32 indexed electionId, address indexed submitter);
    event ManipulationDetected(bytes32 indexed electionId, address indexed candidate, uint256 discrepancy);
    event VoterNFTPurchased(address indexed voter, uint256 amount);
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏗️ INITIALIZATION
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
    // 🗳️ ELECTION CREATION & MANAGEMENT
    // ═══════════════════════════════════════════════════════════════════════════════
   
    /**
     * @notice Crea una nuova elezione
     * @param name Nome dell'elezione
     * @param description Descrizione dell'elezione
     * @param startTime Timestamp di inizio
     * @param endTime Timestamp di fine
     */
    function createElection(
        string memory name,
        string memory description,
        uint256 startTime,
        uint256 endTime
    ) external onlyRole(DRAW_OWNER_ROLE) returns (bytes32 electionId) {
        require(startTime > block.timestamp, "Start time must be in future");
        require(endTime > startTime, "End time must be after start time");
        
        electionId = keccak256(abi.encodePacked(name, block.timestamp, msg.sender));
        
        Election storage newElection = elections[electionId];
        newElection.id = electionId;
        newElection.name = name;
        newElection.description = description;
        newElection.startTime = startTime;
        newElection.endTime = endTime;
        newElection.active = true;
        
        activeElections.push(electionId);
        
        emit ElectionCreated(electionId, name, startTime, endTime);
        
        return electionId;
    }
    
    /**
     * @notice Aggiunge un candidato all'elezione
     * @param electionId ID dell'elezione
     * @param candidate Indirizzo del candidato
     * @param candidateName Nome del candidato
     */
    function addCandidate(
        bytes32 electionId,
        address candidate,
        string memory candidateName
    ) external onlyRole(DRAW_OWNER_ROLE) {
        require(elections[electionId].active, "Election not active");
        require(block.timestamp < elections[electionId].startTime, "Election already started");
        
        elections[electionId].candidates.push(candidate);
        _grantRole(CANDIDATE_ROLE, candidate);
        
        emit CandidateAdded(electionId, candidate, candidateName);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🗳️ VOTING SYSTEM WITH REFUND PROTECTION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Acquista NFT Voter e vota per un candidato
     * @param electionId ID dell'elezione
     * @param candidate Candidato scelto
     */
    function purchaseVoterNFTAndVote(bytes32 electionId, address candidate) 
        external 
        payable 
        nonReentrant 
    {
        require(msg.value >= VOTER_NFT_PRICE, "Insufficient payment for Voter NFT");
        require(elections[electionId].active, "Election not active");
        require(block.timestamp >= elections[electionId].startTime, "Election not started");
        require(block.timestamp <= elections[electionId].endTime, "Election ended");
        require(hasRole(CANDIDATE_ROLE, candidate), "Invalid candidate");
        
        // Registra contribuzione per sistema refund
        _recordContribution(msg.sender, msg.value);
        
        // Registra voto
        elections[electionId].candidateVotes[candidate] += 1;
        elections[electionId].totalVotes += 1;
        userVotes[electionId][msg.sender] += 1;
        
        // Mint IVOTE tokens come ricompensa
        uint256 tokensToMint = msg.value * 1000; // 1000 tokens per ETH
        _transfer(address(this), msg.sender, tokensToMint);
        
        emit VoteCast(electionId, msg.sender, candidate, msg.value);
        emit VoterNFTPurchased(msg.sender, msg.value);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🛡️ ANTI-MANIPULATION SYSTEM
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Sottometti risultati ufficiali per confronto
     * @param electionId ID dell'elezione
     * @param candidates Array dei candidati
     * @param results Array dei risultati ufficiali
     */
    function submitOfficialResults(
        bytes32 electionId,
        address[] memory candidates,
        uint256[] memory results
    ) external onlyRole(DRAW_OWNER_ROLE) {
        require(!elections[electionId].resultsSubmitted, "Results already submitted");
        require(block.timestamp > elections[electionId].endTime, "Election not ended");
        require(candidates.length == results.length, "Arrays length mismatch");
        
        elections[electionId].resultsSubmitted = true;
        
        // Salva risultati ufficiali
        for (uint i = 0; i < candidates.length; i++) {
            elections[electionId].officialResults[candidates[i]] = results[i];
        }
        
        // Controlla manipolazione
        _detectManipulation(electionId, candidates);
        
        emit OfficialResultsSubmitted(electionId, msg.sender);
    }
    
    /**
     * @notice Rileva manipolazione confrontando risultati blockchain vs ufficiali
     * @param electionId ID dell'elezione
     * @param candidates Array dei candidati
     */
    function _detectManipulation(bytes32 electionId, address[] memory candidates) internal {
        for (uint i = 0; i < candidates.length; i++) {
            address candidate = candidates[i];
            uint256 blockchainVotes = elections[electionId].candidateVotes[candidate];
            uint256 officialVotes = elections[electionId].officialResults[candidate];
            
            if (blockchainVotes > 0 || officialVotes > 0) {
                uint256 discrepancy;
                if (blockchainVotes > officialVotes) {
                    discrepancy = ((blockchainVotes - officialVotes) * 100) / blockchainVotes;
                } else {
                    discrepancy = ((officialVotes - blockchainVotes) * 100) / officialVotes;
                }
                
                if (discrepancy > MANIPULATION_THRESHOLD) {
                    elections[electionId].manipulationDetected = true;
                    emit ManipulationDetected(electionId, candidate, discrepancy);
                }
            }
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔄 REFUND SYSTEM INTEGRATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Hook specifico per IVOTE durante refund
     * @dev Brucia i token IVOTE dell'utente durante il refund
     * @param user Utente che richiede refund
     * @param originalAmount Importo originale della contribuzione
     */
    function _processRefundHook(address user, uint256 originalAmount) internal override {
        // Calcola tokens da bruciare basato sulla contribuzione
        uint256 tokensToBurn = originalAmount * 1000; // Stesso rate del mint
        uint256 userBalance = balanceOf(user);
        
        // Brucia i token (fino al massimo del balance utente)
        uint256 burnAmount = tokensToBurn > userBalance ? userBalance : tokensToBurn;
        if (burnAmount > 0) {
            _burn(user, burnAmount);
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Ottieni risultati di un'elezione
     * @param electionId ID dell'elezione
     * @return candidates Array dei candidati
     * @return blockchainResults Risultati dalla blockchain
     * @return officialResults Risultati ufficiali (se sottomessi)
     * @return manipulationDetected Se è stata rilevata manipolazione
     */
    function getElectionResults(bytes32 electionId) 
        external 
        view 
        returns (
            address[] memory candidates,
            uint256[] memory blockchainResults,
            uint256[] memory officialResults,
            bool manipulationDetected
        ) 
    {
        Election storage election = elections[electionId];
        candidates = election.candidates;
        blockchainResults = new uint256[](candidates.length);
        officialResults = new uint256[](candidates.length);
        
        for (uint i = 0; i < candidates.length; i++) {
            blockchainResults[i] = election.candidateVotes[candidates[i]];
            officialResults[i] = election.officialResults[candidates[i]];
        }
        
        manipulationDetected = election.manipulationDetected;
    }
    
    /**
     * @notice Ottieni informazioni complete di un'elezione
     */
    function getElectionInfo(bytes32 electionId) 
        external 
        view 
        returns (
            string memory name,
            string memory description,
            uint256 startTime,
            uint256 endTime,
            bool active,
            uint256 totalVotes,
            bool resultsSubmitted,
            bool manipulationDetected
        ) 
    {
        Election storage election = elections[electionId];
        return (
            election.name,
            election.description,
            election.startTime,
            election.endTime,
            election.active,
            election.totalVotes,
            election.resultsSubmitted,
            election.manipulationDetected
        );
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔐 ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Chiudi un'elezione prematuramente
     */
    function closeElection(bytes32 electionId) external onlyRole(DRAW_OWNER_ROLE) {
        elections[electionId].active = false;
        elections[electionId].endTime = block.timestamp;
    }
    
    /**
     * @notice Preleva royalty accumulate
     */
    function withdrawRoyalties() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(refundState == RefundState.SUCCESS_CONFIRMED, "Success not confirmed");
        
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        payable(owner()).transfer(balance);
    }
}
