// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title RefundManager
 * @author Avv. Marcello Stanca - Solidary Network Architect
 * @notice Contratto base per gestione refund cross-planetari nell'ecosistema Solidary
 * @dev Sistema standardizzato di rimborso con soglia globale di 100.000 EUR
 * 
 * 🌌 FILOSOFIA SOLIDARY REFUND SYSTEM:
 * - Protezione acquirenti con soglia minima globale
 * - Trasparenza fiscale con royalty dichiarate
 * - Economia circolare con redistribuzione automatica
 * - Giustizia contrattuale con rimborso garantito
 * 
 * 💰 DISTRIBUZIONE STANDARD:
 * - 88% → Wallet Acquirente (valore netto)
 * - 5% → Creator Wallet (royalty tassabile)
 * - 5% → Owner Wallet (royalty tassabile)  
 * - 2% → Solidary Ecosystem (fondo comune)
 */
abstract contract RefundManager is 
    Initializable, 
    OwnableUpgradeable, 
    ReentrancyGuardUpgradeable, 
    UUPSUpgradeable 
{
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📋 REFUND SYSTEM CONSTANTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @notice Soglia minima globale per conferma progetti (100.000 EUR in wei)
    uint256 public constant GLOBAL_SUCCESS_THRESHOLD = 100000 ether;
    
    /// @notice Percentuale rimborso netto (88% dopo royalty)
    uint256 public constant REFUND_PERCENTAGE = 88;
    
    /// @notice Percentuale royalty creator (5%)
    uint256 public constant CREATOR_ROYALTY = 5;
    
    /// @notice Percentuale royalty owner (5%)
    uint256 public constant OWNER_ROYALTY = 5;
    
    /// @notice Percentuale ecosistema solidary (2%)
    uint256 public constant SOLIDARY_PERCENTAGE = 2;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @notice Wallet creator per royalty
    address public creatorWallet;
    
    /// @notice Wallet ecosistema Solidary
    address public solidaryWallet;
    
    /// @notice Totale raccolto da questo pianeta
    uint256 public totalRaisedThisPlanet;
    
    /// @notice Totale raccolto da tutto l'ecosistema (aggiornato da oracle)
    uint256 public totalRaisedEcosystem;
    
    /// @notice Deadline per richieste di refund
    uint256 public refundDeadline;
    
    /// @notice Mapping delle contribuzioni per wallet
    mapping(address => uint256) public contributions;
    
    /// @notice Mapping dei refund già processati
    mapping(address => bool) public refundProcessed;
    
    /// @notice Stato del sistema refund
    enum RefundState { ACTIVE, SUCCESS_CONFIRMED, REFUND_AVAILABLE, REFUND_EXPIRED }
    RefundState public refundState;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📢 EVENTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    event ContributionRecorded(address indexed contributor, uint256 amount, uint256 timestamp);
    event RefundRequested(address indexed user, uint256 refundAmount, uint256 timestamp);
    event RefundProcessed(address indexed user, uint256 amount);
    event EcosystemThresholdReached(uint256 totalAmount, uint256 timestamp);
    event EcosystemThresholdFailed(uint256 totalAmount, uint256 deadline);
    event RoyaltyDistributed(address indexed recipient, uint256 amount, string role);
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔧 MODIFIERS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    modifier onlyRefundAvailable() {
        require(refundState == RefundState.REFUND_AVAILABLE, "Refunds not available");
        _;
    }
    
    modifier hasContribution() {
        require(contributions[msg.sender] > 0, "No contribution found");
        require(!refundProcessed[msg.sender], "Refund already processed");
        _;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏗️ INITIALIZATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function __RefundManager_init(
        address _creatorWallet,
        address _solidaryWallet,
        uint256 _refundDeadline
    ) internal onlyInitializing {
        __Ownable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        
        creatorWallet = _creatorWallet;
        solidaryWallet = _solidaryWallet;
        refundDeadline = _refundDeadline;
        refundState = RefundState.ACTIVE;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 💰 CONTRIBUTION MANAGEMENT
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Registra una contribuzione e distribuisce royalty
     * @param contributor Indirizzo del contributore
     * @param amount Importo della contribuzione
     */
    function _recordContribution(address contributor, uint256 amount) internal {
        require(refundState == RefundState.ACTIVE, "Contributions not active");
        
        contributions[contributor] += amount;
        totalRaisedThisPlanet += amount;
        
        // Distribuzione automatica royalty
        _distributeRoyalties(amount);
        
        emit ContributionRecorded(contributor, amount, block.timestamp);
    }
    
    /**
     * @notice Distribuisce royalty automaticamente
     * @param amount Importo totale da cui calcolare royalty
     */
    function _distributeRoyalties(uint256 amount) internal {
        uint256 creatorShare = (amount * CREATOR_ROYALTY) / 100;
        uint256 ownerShare = (amount * OWNER_ROYALTY) / 100;
        uint256 solidaryShare = (amount * SOLIDARY_PERCENTAGE) / 100;
        
        // Trasferimento royalty creator
        if (creatorShare > 0) {
            payable(creatorWallet).transfer(creatorShare);
            emit RoyaltyDistributed(creatorWallet, creatorShare, "CREATOR");
        }
        
        // Trasferimento royalty owner
        if (ownerShare > 0) {
            payable(owner()).transfer(ownerShare);
            emit RoyaltyDistributed(owner(), ownerShare, "OWNER");
        }
        
        // Trasferimento quota ecosistema
        if (solidaryShare > 0) {
            payable(solidaryWallet).transfer(solidaryShare);
            emit RoyaltyDistributed(solidaryWallet, solidaryShare, "SOLIDARY");
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔄 REFUND SYSTEM
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Richiedi refund se soglia ecosistema non raggiunta
     * @dev Rimborsa 88% del valore (al netto delle royalty già distribuite)
     */
    function requestRefund() external nonReentrant onlyRefundAvailable hasContribution {
        uint256 originalContribution = contributions[msg.sender];
        uint256 refundAmount = (originalContribution * REFUND_PERCENTAGE) / 100;
        
        // Azzera la contribuzione
        contributions[msg.sender] = 0;
        refundProcessed[msg.sender] = true;
        
        // Hook per azioni specifiche del pianeta (es. burn tokens/NFT)
        _processRefundHook(msg.sender, originalContribution);
        
        // Trasferimento refund
        require(address(this).balance >= refundAmount, "Insufficient contract balance");
        payable(msg.sender).transfer(refundAmount);
        
        emit RefundRequested(msg.sender, refundAmount, block.timestamp);
        emit RefundProcessed(msg.sender, refundAmount);
    }
    
    /**
     * @notice Hook per azioni specifiche del pianeta durante refund
     * @dev Da implementare nei contratti derivati
     * @param user Utente che richiede refund
     * @param originalAmount Importo originale della contribuzione
     */
    function _processRefundHook(address user, uint256 originalAmount) internal virtual {
        // Implementazione specifica per ogni pianeta
        // Es: burn tokens, NFT, badge, etc.
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌍 ECOSYSTEM THRESHOLD MANAGEMENT
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Aggiorna il totale dell'ecosistema (solo owner)
     * @param _totalEcosystem Nuovo totale raccolto da tutto l'ecosistema
     */
    function updateEcosystemTotal(uint256 _totalEcosystem) external onlyOwner {
        totalRaisedEcosystem = _totalEcosystem;
        
        // Controlla se soglia raggiunta
        if (_totalEcosystem >= GLOBAL_SUCCESS_THRESHOLD) {
            refundState = RefundState.SUCCESS_CONFIRMED;
            emit EcosystemThresholdReached(_totalEcosystem, block.timestamp);
        }
    }
    
    /**
     * @notice Attiva periodo refund se soglia non raggiunta (solo owner)
     */
    function activateRefundPeriod() external onlyOwner {
        require(block.timestamp >= refundDeadline, "Refund deadline not reached");
        require(totalRaisedEcosystem < GLOBAL_SUCCESS_THRESHOLD, "Threshold reached");
        
        refundState = RefundState.REFUND_AVAILABLE;
        emit EcosystemThresholdFailed(totalRaisedEcosystem, refundDeadline);
    }
    
    /**
     * @notice Chiude definitivamente il periodo refund (solo owner)
     */
    function closeRefundPeriod() external onlyOwner {
        refundState = RefundState.REFUND_EXPIRED;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Controlla se utente può richiedere refund
     * @param user Indirizzo da controllare
     * @return eligible Se può richiedere refund
     * @return amount Importo del refund
     */
    function checkRefundEligibility(address user) external view returns (bool eligible, uint256 amount) {
        if (refundState != RefundState.REFUND_AVAILABLE) return (false, 0);
        if (contributions[user] == 0) return (false, 0);
        if (refundProcessed[user]) return (false, 0);
        
        uint256 refundAmount = (contributions[user] * REFUND_PERCENTAGE) / 100;
        return (true, refundAmount);
    }
    
    /**
     * @notice Stato completo del sistema refund
     */
    function getRefundSystemStatus() external view returns (
        RefundState state,
        uint256 thisPlanetTotal,
        uint256 ecosystemTotal,
        uint256 threshold,
        uint256 deadline,
        bool thresholdReached
    ) {
        return (
            refundState,
            totalRaisedThisPlanet,
            totalRaisedEcosystem,
            GLOBAL_SUCCESS_THRESHOLD,
            refundDeadline,
            totalRaisedEcosystem >= GLOBAL_SUCCESS_THRESHOLD
        );
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔐 ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Aggiorna wallet creator (solo owner)
     */
    function updateCreatorWallet(address _newCreator) external onlyOwner {
        creatorWallet = _newCreator;
    }
    
    /**
     * @notice Aggiorna wallet Solidary (solo owner)
     */
    function updateSolidaryWallet(address _newSolidary) external onlyOwner {
        solidaryWallet = _newSolidary;
    }
    
    /**
     * @notice Prelievo fondi rimanenti (solo se successo confermato)
     */
    function withdrawRemainingFunds() external onlyOwner {
        require(refundState == RefundState.SUCCESS_CONFIRMED, "Success not confirmed");
        
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        payable(owner()).transfer(balance);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔄 UPGRADE AUTHORIZATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 💰 RECEIVE FUNCTION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    receive() external payable {
        // Accetta pagamenti per refund pool
    }
}