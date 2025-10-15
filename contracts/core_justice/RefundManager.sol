// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

// Copyright © 2025 Avv. Marcello Stanca - Firenze, Italia. All Rights Reserved.
//
// Hoc contractum, pars Systematis Solidarii, ab Auctore Marcello Stanca Caritati Internationali (MCMLXXVI) gratis conceditur.
// (This smart contract, part of the Solidary System, is granted for free use to Caritas Internationalis (1976) by the author, Marcello Stanca.)

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title RefundManager
 * @author Avv. Marcello Stanca - Architectus Aequitatis (Architect of Justice)
 * @notice Fundamentum oeconomicum Oecosystematis Solidarii, quod conlatores tuetur et iustitiam in redistributione praestat.
 * (English: The economic foundation of the Solidary Ecosystem, which protects contributors and ensures justice in redistribution.)
 * @dev Hic contractus est modulus abstractus, cor pulsans cuiusque "planetae" oeconomicae. Sicut tholus Cathedralis pondus aequaliter distribuit, sic hic codex valorem in tuto collocat, adaptans se ad magnitudinem cuiusque missionis, a parva communitate usque ad gentem universam.
 * (English: This contract is an abstract module, the beating heart of every economic "planet". As the dome of a Cathedral distributes weight evenly, so this code secures value, adapting itself to the scale of each mission, from a small community to an entire nation.)
 */
abstract contract RefundManager is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📋 PRINCIPIA ET CONSTANTES CARITATIS (PRINCIPLES & CONSTANTS OF CHARITY)
    // ═══════════════════════════════════════════════════════════════════════════════

    uint256 public constant REFUND_PERCENTAGE = 88;
    uint256 public constant CREATOR_ROYALTY = 5;
    uint256 public constant OWNER_ROYALTY = 5;
    uint256 public constant SOLIDARY_PERCENTAGE = 2;

    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 TABULAE OECONOMICAE (ECONOMIC LEDGERS)
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Limen victoriae oecosystematis, quod magnitudinem missionis reflectit. Mutabile est ab Auctore.
     * (English: The success threshold of the ecosystem, reflecting the mission's scale. It is mutable by the Author/Owner.)
     */
    uint256 public globalSuccessThreshold;

    address public creatorWallet;
    address public solidaryWallet;
    uint256 public totalRaisedThisPlanet;
    uint256 public totalRaisedEcosystem;
    uint256 public refundDeadline;
    mapping(address => uint256) public contributions;
    mapping(address => bool) public refundProcessed;
    enum RefundState { ACTIVE, SUCCESS_CONFIRMED, REFUND_AVAILABLE, REFUND_EXPIRED }
    RefundState public refundState;

    // ═══════════════════════════════════════════════════════════════════════════════
    // 📢 NUNTII PUBLICI (PUBLIC ANNOUNCEMENTS / EVENTS)
    // ═══════════════════════════════════════════════════════════════════════════════

    event ContributionRecorded(address indexed contributor, uint256 amount, uint256 timestamp);
    event RefundRequested(address indexed user, uint256 refundAmount, uint256 timestamp);
    event RefundProcessed(address indexed user, uint256 amount);
    event EcosystemThresholdReached(uint256 totalAmount, uint256 timestamp);
    event EcosystemThresholdFailed(uint256 totalAmount, uint256 deadline);
    event RoyaltyDistributed(address indexed recipient, uint256 amount, string role);
    event GlobalSuccessThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔧 MODIFIERS (CUSTODES ACTIONUM)
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
    // 🏗️ INITIALIZATION (INITIUM OPERIS)
    // ═══════════════════════════════════════════════════════════════════════════════

    // ... all'interno di RefundManager.sol ...

    function __RefundManager_init(
        address _creatorWallet,
        address _solidaryWallet,
        uint256 _refundDeadline,
        uint256 _initialThreshold
    ) internal onlyInitializing {
        // --- MODIFICA CORRETTIVA ---
        // Invochiamo __Ownable_init passando l'indirizzo dell'owner che ha deployato il proxy,
        // come richiesto dalle nuove versioni di OpenZeppelin.
        __Ownable_init(msg.sender); 
        
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        creatorWallet = _creatorWallet;
        solidaryWallet = _solidaryWallet;
        refundDeadline = _refundDeadline;
        globalSuccessThreshold = _initialThreshold;
        refundState = RefundState.ACTIVE;
    }
    // ═══════════════════════════════════════════════════════════════════════════════
    // 💰 DE CONLATIONIBUS ADMINISTRANDIS (CONTRIBUTION MANAGEMENT)
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function _recordContribution(address contributor, uint256 amount) internal {
        require(refundState == RefundState.ACTIVE, "Contributions not active");

        contributions[contributor] += amount;
        totalRaisedThisPlanet += amount;

        _distributeRoyalties(amount);

        emit ContributionRecorded(contributor, amount, block.timestamp);
    }

    function _distributeRoyalties(uint256 amount) internal {
        uint256 authorShare = (amount * CREATOR_ROYALTY) / 100;
        uint256 ownerShare = (amount * OWNER_ROYALTY) / 100;
        uint256 solidaryShare = (amount * SOLIDARY_PERCENTAGE) / 100;

        if (authorShare > 0) {
            (bool success, ) = payable(creatorWallet).call{value: authorShare}("");
            require(success, "EthicaTranslatioDefecit:AUCTOR");
            emit RoyaltyDistributed(creatorWallet, authorShare, "AUTHOR");
        }
        if (ownerShare > 0) {
            (bool success, ) = payable(owner()).call{value: ownerShare}("");
            require(success, "EthicaTranslatioDefecit:DOMINUS");
            emit RoyaltyDistributed(owner(), ownerShare, "OWNER");
        }
        if (solidaryShare > 0) {
            (bool success, ) = payable(solidaryWallet).call{value: solidaryShare}("");
            require(success, "EthicaTranslatioDefecit:OECOSYSTEMA");
            emit RoyaltyDistributed(solidaryWallet, solidaryShare, "SOLIDARY");
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔄 DE RESTITUTIONIBUS (REFUND SYSTEM)
    // ═══════════════════════════════════════════════════════════════════════════════

    function requestRefund() external nonReentrant onlyRefundAvailable hasContribution {
        uint256 originalContribution = contributions[msg.sender];
        uint256 refundAmount = (originalContribution * REFUND_PERCENTAGE) / 100;

        contributions[msg.sender] = 0;
        refundProcessed[msg.sender] = true;

        _processRefundHook(msg.sender, originalContribution);

        (bool success, ) = msg.sender.call{value: refundAmount}("");
        require(success, "Refund transfer failed");

        emit RefundRequested(msg.sender, refundAmount, block.timestamp);
        emit RefundProcessed(msg.sender, refundAmount);
    }
    
    function _processRefundHook(address user, uint256 originalAmount) internal virtual {}

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌍 ADMINISTRATIO LIMINIS OECOSYSTEMATIS (ECOSYSTEM THRESHOLD MANAGEMENT)
    // ═══════════════════════════════════════════════════════════════════════════════

    function updateEcosystemTotal(uint256 _totalEcosystem) external onlyOwner {
        totalRaisedEcosystem = _totalEcosystem;

        if (_totalEcosystem >= globalSuccessThreshold) {
            refundState = RefundState.SUCCESS_CONFIRMED;
            emit EcosystemThresholdReached(_totalEcosystem, block.timestamp);
        }
    }
    
    function activateRefundPeriod() external onlyOwner {
        require(block.timestamp >= refundDeadline, "Refund deadline not reached");
        require(totalRaisedEcosystem < globalSuccessThreshold, "Threshold reached");

        refundState = RefundState.REFUND_AVAILABLE;
        emit EcosystemThresholdFailed(totalRaisedEcosystem, refundDeadline);
    }
    
    function closeRefundPeriod() external onlyOwner {
        refundState = RefundState.REFUND_EXPIRED;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔐 FUNCTIONES ADMINISTRATORIS (ADMIN FUNCTIONS)
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function setGlobalSuccessThreshold(uint256 _newThreshold) external onlyOwner {
        require(_newThreshold > 0, "Limen debet esse maius quam zerum");
        uint256 oldThreshold = globalSuccessThreshold;
        globalSuccessThreshold = _newThreshold;
        emit GlobalSuccessThresholdUpdated(oldThreshold, _newThreshold);
    }

    function updateCreatorWallet(address _newCreator) external onlyOwner {
        creatorWallet = _newCreator;
    }

    function updateSolidaryWallet(address _newSolidary) external onlyOwner {
        solidaryWallet = _newSolidary;
    }

    function withdrawRemainingFunds() external onlyOwner nonReentrant {
        require(refundState == RefundState.SUCCESS_CONFIRMED, "Success not confirmed");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdraw failed");
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔄 UPGRADE AUTHORIZATION (AUCTORITAS EMENDANDI)
    // ═══════════════════════════════════════════════════════════════════════════════

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

    // ═══════════════════════════════════════════════════════════════════════════════
    // 💰 RECEIVE FUNCTION (FUNCTIO ACCIPIENDI)
    // ═══════════════════════════════════════════════════════════════════════════════
    
    receive() external payable {}
}
