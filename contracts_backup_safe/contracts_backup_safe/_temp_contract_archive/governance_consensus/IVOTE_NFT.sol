// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

// © Copyright 2025 Marcello Stanca Avvocato in Italy Firenze - All Rights Reserved
// Tutti i diritti di uso e riproduzione sono riservati esclusivamente al titolare

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title IVOTEVoterNFT - NFT Sicurezza Voto Una Tantum
 * @dev NFT rivoluzionario per garantire un solo voto per persona per campagna
 * @author © Marcello Stanca Avvocato in Italy Firenze - Copyright 2025 - All Rights Reserved
 * @notice PROPRIETÀ INTELLETTUALE PROTETTA - Uso non autorizzato perseguibile per legge
 * 
 * SICUREZZA ANTI-MANIPOLAZIONE:
 * 1. Un solo NFT per votante per campagna
 * 2. Distanza di sicurezza 7 giorni prima del voto
 * 3. NFT utilizzabile una sola volta
 * 4. Prezzo NFT come deterrente spam
 */

contract IVOTEVoterNFT is ERC721, Ownable, ReentrancyGuard {
    
    // ═══════════════════════════════════════════════════════════════════
    // CONFIGURAZIONE SICUREZZA NFT
    // ═══════════════════════════════════════════════════════════════════
    
    uint256 public nftCounter;
    uint256 public nftPrice;
    uint256 public constant SAFETY_PERIOD = 7 days;
    
    address public ivoteContract;     // Contratto IVOTE principale
    address public drawOwner;         // Wallet incassi
    
    struct VoterNFTData {
        bytes32 campaignId;
        uint256 mintTime;
        bool hasVoted;
        string voterType;    // "CITIZEN", "PREMIUM", "INSTITUTIONAL"
        address voter;
    }
    
    mapping(uint256 => VoterNFTData) public nftData;
    mapping(address => mapping(bytes32 => uint256)) public voterNFTByCampaign;
    mapping(address => mapping(bytes32 => bool)) public hasNFTForCampaign;
    
    // ═══════════════════════════════════════════════════════════════════
    // EVENTS TRASPARENZA
    // ═══════════════════════════════════════════════════════════════════
    
    event VoterNFTMinted(uint256 indexed nftId, address indexed voter, bytes32 indexed campaignId, string voterType);
    event VoterNFTUsed(uint256 indexed nftId, address indexed voter, bytes32 indexed campaignId);
    event PriceUpdated(uint256 oldPrice, uint256 newPrice);
    
    // ═══════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════
    
    constructor(
        address _ivoteContract,
        address _drawOwner,
        uint256 _nftPrice
    ) ERC721("IVOTE Voter Security NFT", "IVTNFT") Ownable(msg.sender) {
        require(_ivoteContract != address(0), "IVOTE contract cannot be zero");
        require(_drawOwner != address(0), "DrawOwner cannot be zero");
        
        ivoteContract = _ivoteContract;
        drawOwner = _drawOwner;
        nftPrice = _nftPrice;
        nftCounter = 1;
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // GESTIONE CONFIGURAZIONE
    // ═══════════════════════════════════════════════════════════════════
    
    function updateNFTPrice(uint256 _newPrice) external onlyOwner {
        uint256 oldPrice = nftPrice;
        nftPrice = _newPrice;
        emit PriceUpdated(oldPrice, _newPrice);
    }
    
    function updateDrawOwner(address _newDrawOwner) external onlyOwner {
        require(_newDrawOwner != address(0), "Cannot be zero address");
        drawOwner = _newDrawOwner;
    }
    
    function updateIVOTEContract(address _newIVOTE) external onlyOwner {
        require(_newIVOTE != address(0), "Cannot be zero address");
        ivoteContract = _newIVOTE;
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // MINTING NFT SICUREZZA UNA TANTUM
    // ═══════════════════════════════════════════════════════════════════
    
    /**
     * @dev Mint NFT votante per campagna specifica (UNA TANTUM)
     */
    function mintVoterNFT(
        bytes32 campaignId,
        string memory voterType
    ) external payable nonReentrant returns (uint256) {
        // CONTROLLO UNA TANTUM
        require(!hasNFTForCampaign[msg.sender][campaignId], "Already has NFT for this campaign");
        
        // CONTROLLO PAGAMENTO
        require(msg.value >= nftPrice, "Insufficient payment");
        
        // MINT NFT
        uint256 nftId = nftCounter;
        _safeMint(msg.sender, nftId);
        
        // REGISTRA DATI
        nftData[nftId] = VoterNFTData({
            campaignId: campaignId,
            mintTime: block.timestamp,
            hasVoted: false,
            voterType: voterType,
            voter: msg.sender
        });
        
        // AGGIORNA MAPPINGS
        voterNFTByCampaign[msg.sender][campaignId] = nftId;
        hasNFTForCampaign[msg.sender][campaignId] = true;
        nftCounter++;
        
        // INVIA PAGAMENTO AL DRAWOWNER
        if (msg.value > 0) {
            payable(drawOwner).transfer(msg.value);
        }
        
        emit VoterNFTMinted(nftId, msg.sender, campaignId, voterType);
        return nftId;
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // VERIFICA SICUREZZA VOTO
    // ═══════════════════════════════════════════════════════════════════
    
    /**
     * @dev Verifica se NFT è valido per voto (chiamato da IVOTE contract)
     */
    function validateVoterNFT(
        address voter,
        bytes32 campaignId,
        uint256 votingTime
    ) external view returns (bool isValid, string memory reason) {
        if (!hasNFTForCampaign[voter][campaignId]) {
            return (false, "No NFT for campaign");
        }
        
        uint256 nftId = voterNFTByCampaign[voter][campaignId];
        VoterNFTData memory data = nftData[nftId];
        
        if (data.hasVoted) {
            return (false, "NFT already used");
        }
        
        if (ownerOf(nftId) != voter) {
            return (false, "NFT ownership changed");
        }
        
        // CONTROLLO DISTANZA SICUREZZA
        if (data.mintTime + SAFETY_PERIOD > votingTime) {
            return (false, "Safety period not met");
        }
        
        return (true, "Valid");
    }
    
    /**
     * @dev Marca NFT come utilizzato (solo IVOTE contract)
     */
    function markNFTAsUsed(uint256 nftId) external {
        require(msg.sender == ivoteContract, "Only IVOTE contract can call");
        require(nftId < nftCounter && nftId > 0, "Invalid NFT ID");
        
        nftData[nftId].hasVoted = true;
        
        emit VoterNFTUsed(nftId, nftData[nftId].voter, nftData[nftId].campaignId);
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // FUNZIONI DI QUERY
    // ═══════════════════════════════════════════════════════════════════
    
    function getNFTData(uint256 nftId) external view returns (VoterNFTData memory) {
        require(nftId < nftCounter && nftId > 0, "Invalid NFT ID");
        return nftData[nftId];
    }
    
    function getVoterNFT(address voter, bytes32 campaignId) external view returns (uint256) {
        return voterNFTByCampaign[voter][campaignId];
    }
    
    function hasValidNFT(address voter, bytes32 campaignId) external view returns (bool) {
        return hasNFTForCampaign[voter][campaignId] && !nftData[voterNFTByCampaign[voter][campaignId]].hasVoted;
    }
}
