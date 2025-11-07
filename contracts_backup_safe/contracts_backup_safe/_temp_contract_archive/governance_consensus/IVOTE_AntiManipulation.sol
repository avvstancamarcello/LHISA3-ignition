// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;
// © Copyright 2025 Marcello Stanca Avvocato in Italy Firenze - All Rights Reserved
// © Copyright Marcello Stanca – Lawyer, Italy (Florence)
// Tutti i diritti di uso e riproduzione sono riservati esclusivamente al titolare

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Interfaccia per il contratto NFT votanti
interface IVOTEVoterNFTInterface {
    function validateVoterNFT(address voter, bytes32 campaignId, uint256 votingTime) external view returns (bool isValid, string memory reason);
    function markNFTAsUsed(uint256 nftId) external;
    function getVoterNFT(address voter, bytes32 campaignId) external view returns (uint256);
    function hasValidNFT(address voter, bytes32 campaignId) external view returns (bool);
}

/**
 * @title IVOTE - Sistema Anti-Manipolazione Elettorale Blockchain
 * @dev Token rivoluzionario per verificare autenticità risultati elettorali vs voto cartaceo
 * @author © Marcello Stanca Avvocato in Italy Firenze - Copyright 2025 - All Rights Reserved
 * @notice PROPRIETÀ INTELLETTUALE PROTETTA - Uso non autorizzato perseguibile per legge
 * 
 * FUNZIONAMENTO RIVOLUZIONARIO:
 * 1. Elettori comprano token candidato/partito (TRUMP2024, BIDEN2024, etc.)
 * 2. Blockchain registra voti anonimi ma verificabili
 * 3. Confronto risultati ufficiali vs blockchain
 * 4. Discrepanze = PROVA DI MANIPOLAZIONE
 */

contract IVOTE is ERC20, Ownable, ReentrancyGuard {
    
    // ═══════════════════════════════════════════════════════════════════
    // STRUTTURE DATI ANTI-MANIPOLAZIONE
    // ═══════════════════════════════════════════════════════════════════
    
    struct ElectionCampaign {
        string name;                    // "Elezioni USA 2024"
        uint256 startTime;             
        uint256 endTime;               
        bool isActive;                 
        mapping(string => CandidateToken) candidates;  // "TRUMP" => Token data
        string[] candidateList;        // Array candidati per iterazione
        uint256 totalVotes;           // Totale voti blockchain
        uint256 totalInvestment;      // Totale $ investiti
        bool resultsLocked;           // Risultati bloccati post-elezione
    }
    
    struct CandidateToken {
        address tokenAddress;          // Indirizzo token candidato
        uint256 totalPurchases;       // Totale acquisti token
        uint256 totalAmount;          // Totale token comprati 
        uint256 uniqueVoters;         // Numero votanti unici
        string officialName;          // "Donald Trump"
        string party;                 // "Republican Party"
        bool exists;
    }
    
    struct VoteRecord {
        bytes32 campaignId;           
        string candidate;             
        uint256 amount;               // Quantità token comprati
        uint256 timestamp;            
        address voter;                // Anonimizzabile
        bool verified;                
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // STORAGE ANTI-MANIPOLAZIONE
    // ═══════════════════════════════════════════════════════════════════
    
    mapping(bytes32 => ElectionCampaign) public campaigns;
    mapping(address => mapping(bytes32 => bool)) public hasVoted; // Votante per campagna
    mapping(bytes32 => VoteRecord[]) public voteHistory;          // Storia voti per audit
    
    // Registri per confronto con risultati ufficiali
    mapping(bytes32 => mapping(string => uint256)) public blockchainResults;  // Candidato => Voti blockchain
    mapping(bytes32 => mapping(string => uint256)) public officialResults;    // Candidato => Voti ufficiali
    mapping(bytes32 => bool) public manipulationDetected;                     // Campagna manipolata?
    
    uint256 public constant MANIPULATION_THRESHOLD = 5; // 5% differenza = sospetto
    uint256 public constant ROYALTY_PERCENTAGE = 5; // 5% royalty al proprietario
    
    // ═══════════════════════════════════════════════════════════════════
    // SISTEMA ROYALTIES E CONTROLLI OWNER
    // ═══════════════════════════════════════════════════════════════════
    
    address public drawOwner;        // Wallet per prelievi owner
    address public sponsorWallet;    // Wallet sponsor/partnership
    uint256 public maxCandidates;    // Limite candidati (0 = illimitato per owner)
    uint256 public maxParties;       // Limite partiti (0 = illimitato per owner)
    
    // Tracking royalties accumulate
    mapping(bytes32 => uint256) public campaignRoyalties;  // Royalties per campagna
    uint256 public totalRoyaltiesCollected;                // Totale royalties raccolte
    
    // ═══════════════════════════════════════════════════════════════════
    // INTEGRAZIONE NFT SICUREZZA SEPARATO
    // ═══════════════════════════════════════════════════════════════════
    
    IVOTEVoterNFTInterface public voterNFTContract;         // Contratto NFT separato
    
    // ═══════════════════════════════════════════════════════════════════
    // EVENTS TRASPARENZA DEMOCRATICA
    // ═══════════════════════════════════════════════════════════════════
    
    event CampaignCreated(bytes32 indexed campaignId, string name, uint256 startTime, uint256 endTime);
    event CandidateAdded(bytes32 indexed campaignId, string candidate, address tokenAddress);
    event RoyaltyCollected(bytes32 indexed campaignId, uint256 amount, address to);
    event WalletUpdated(string walletType, address oldWallet, address newWallet);
    event LimitsUpdated(uint256 newMaxCandidates, uint256 newMaxParties);
    event NFTContractUpdated(address indexed oldContract, address indexed newContract);
    event VoteCast(bytes32 indexed campaignId, string candidate, uint256 amount, address indexed voter);
    event OfficialResultsSubmitted(bytes32 indexed campaignId, string candidate, uint256 officialVotes);
    event ManipulationDetected(bytes32 indexed campaignId, string details);
    event TransparencyReport(bytes32 indexed campaignId, uint256 blockchainTotal, uint256 officialTotal);
    
    // ═══════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════
    
    constructor(
        address _drawOwner,
        address _sponsorWallet,
        uint256 _maxCandidates,
        uint256 _maxParties
    ) ERC20("IVOTE Democracy Token", "IVOTE") Ownable(msg.sender) {
        require(_drawOwner != address(0), "DrawOwner cannot be zero address");
        require(_sponsorWallet != address(0), "SponsorWallet cannot be zero address");
        
        drawOwner = _drawOwner;
        sponsorWallet = _sponsorWallet;
        maxCandidates = _maxCandidates; // 0 = illimitato per owner
        maxParties = _maxParties;       // 0 = illimitato per owner
        
        _mint(msg.sender, 1000000000 * 10**decimals()); // 1B token iniziali
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // GESTIONE CAMPAGNE ELETTORALI
    // ═══════════════════════════════════════════════════════════════════
    
    /**
     * @dev Crea nuova campagna elettorale
     * @param name Nome elezione ("Elezioni Italia 2025")
     * @param duration Durata in secondi
     */
    function createElection(
        string memory name, 
        uint256 duration
    ) external onlyOwner returns (bytes32) {
        bytes32 campaignId = keccak256(abi.encodePacked(name, block.timestamp));
        
        ElectionCampaign storage campaign = campaigns[campaignId];
        campaign.name = name;
        campaign.startTime = block.timestamp;
        campaign.endTime = block.timestamp + duration;
        campaign.isActive = true;
        campaign.totalVotes = 0;
        campaign.totalInvestment = 0;
        campaign.resultsLocked = false;
        
        emit CampaignCreated(campaignId, name, campaign.startTime, campaign.endTime);
        return campaignId;
    }
    
    /**
     * @dev Aggiunge candidato alla campagna (con controlli limiti)
     */
    function addCandidate(
        bytes32 campaignId,
        string memory candidateSymbol,    // "TRUMP2024"
        string memory officialName,       // "Donald Trump"  
        string memory party,              // "Republican Party"
        address tokenAddress              // Indirizzo token candidato
    ) external onlyOwner {
        ElectionCampaign storage campaign = campaigns[campaignId];
        require(campaign.isActive, "Campaign not active");
        
        // Controllo limiti candidati (0 = illimitato per owner)
        if (maxCandidates > 0 && campaign.candidateList.length >= maxCandidates) {
            revert("Maximum candidates limit reached");
        }
        
        campaign.candidates[candidateSymbol] = CandidateToken({
            tokenAddress: tokenAddress,
            totalPurchases: 0,
            totalAmount: 0,
            uniqueVoters: 0,
            officialName: officialName,
            party: party,
            exists: true
        });
        
        campaign.candidateList.push(candidateSymbol);
        
        emit CandidateAdded(campaignId, candidateSymbol, tokenAddress);
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // GESTIONE WALLET E ROYALTIES
    // ═══════════════════════════════════════════════════════════════════
    
    /**
     * @dev Aggiorna wallet draw owner
     */
    function updateDrawOwner(address _newDrawOwner) external onlyOwner {
        require(_newDrawOwner != address(0), "Cannot be zero address");
        address oldWallet = drawOwner;
        drawOwner = _newDrawOwner;
        emit WalletUpdated("DrawOwner", oldWallet, _newDrawOwner);
    }
    
    /**
     * @dev Aggiorna wallet sponsor
     */
    function updateSponsorWallet(address _newSponsorWallet) external onlyOwner {
        require(_newSponsorWallet != address(0), "Cannot be zero address");
        address oldWallet = sponsorWallet;
        sponsorWallet = _newSponsorWallet;
        emit WalletUpdated("SponsorWallet", oldWallet, _newSponsorWallet);
    }
    
    /**
     * @dev Aggiorna limiti candidati/partiti (solo owner può avere illimitati)
     */
    function updateLimits(uint256 _maxCandidates, uint256 _maxParties) external onlyOwner {
        maxCandidates = _maxCandidates; // 0 = illimitato
        maxParties = _maxParties;       // 0 = illimitato
        emit LimitsUpdated(_maxCandidates, _maxParties);
    }
    
    /**
     * @dev Preleva royalties accumulate
     */
    function withdrawRoyalties(bytes32 campaignId) external onlyOwner nonReentrant {
        uint256 amount = campaignRoyalties[campaignId];
        require(amount > 0, "No royalties to withdraw");
        
        campaignRoyalties[campaignId] = 0;
        totalRoyaltiesCollected += amount;
        
        // Trasferimento al drawOwner
        payable(drawOwner).transfer(amount);
        
        emit RoyaltyCollected(campaignId, amount, drawOwner);
    }
    
    /**
     * @dev Imposta contratto NFT votanti (solo owner)
     */
    function setVoterNFTContract(address _voterNFTContract) external onlyOwner {
        require(_voterNFTContract != address(0), "Cannot be zero address");
        address oldContract = address(voterNFTContract);
        voterNFTContract = IVOTEVoterNFTInterface(_voterNFTContract);
        emit NFTContractUpdated(oldContract, _voterNFTContract);
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // SISTEMA VOTO BLOCKCHAIN (ANTI-MANIPOLAZIONE)
    // ═══════════════════════════════════════════════════════════════════
    
    /**
     * @dev Vota comprando token candidato - CUORE DEL SISTEMA (RICHIEDE NFT SICUREZZA)
     * @param campaignId ID campagna elettorale
     * @param candidate Symbol candidato ("TRUMP2024")
     * @param amount Quantità IVOTE token da spendere
     */
    function voteByPurchasing(
        bytes32 campaignId,
        string memory candidate,
        uint256 amount
    ) external nonReentrant {
        ElectionCampaign storage campaign = campaigns[campaignId];
        require(campaign.isActive, "Campaign not active");
        require(block.timestamp <= campaign.endTime, "Voting period ended");
        require(campaign.candidates[candidate].exists, "Candidate not found");
        require(balanceOf(msg.sender) >= amount, "Insufficient IVOTE tokens");
        
        // 🛡️ CONTROLLO SICUREZZA NFT: Deve possedere NFT votante valido
        require(address(voterNFTContract) != address(0), "NFT contract not set");
        
        (bool isValidNFT, string memory reason) = voterNFTContract.validateVoterNFT(
            msg.sender, 
            campaignId, 
            block.timestamp
        );
        require(isValidNFT, reason);
        
        // Calcola royalty 5% per owner
        uint256 royaltyAmount = (amount * ROYALTY_PERCENTAGE) / 100;
        uint256 voteAmount = amount - royaltyAmount;
        
        // Transfer IVOTE tokens (costo del voto meno royalty)
        _transfer(msg.sender, address(this), voteAmount);
        if (royaltyAmount > 0) {
            _transfer(msg.sender, drawOwner, royaltyAmount);
            campaignRoyalties[campaignId] += royaltyAmount;
        }
        
        // 🛡️ MARCA NFT COME UTILIZZATO (UNA TANTUM)
        uint256 nftId = voterNFTContract.getVoterNFT(msg.sender, campaignId);
        voterNFTContract.markNFTAsUsed(nftId);
        
        // Registra voto per anti-manipolazione
        CandidateToken storage candidateData = campaign.candidates[candidate];
        candidateData.totalPurchases += 1;
        candidateData.totalAmount += amount;
        
        if (!hasVoted[msg.sender][campaignId]) {
            candidateData.uniqueVoters += 1;
            hasVoted[msg.sender][campaignId] = true;
        }
        
        // Aggiorna totali campagna
        campaign.totalVotes += 1;
        campaign.totalInvestment += amount;
        blockchainResults[campaignId][candidate] += amount;
        
        // Registra per audit trail
        voteHistory[campaignId].push(VoteRecord({
            campaignId: campaignId,
            candidate: candidate,
            amount: amount,
            timestamp: block.timestamp,
            voter: msg.sender,  // Può essere anonimizzato
            verified: true
        }));
        
        emit VoteCast(campaignId, candidate, amount, msg.sender);
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // CONFRONTO RISULTATI UFFICIALI (ANTI-MANIPOLAZIONE)
    // ═══════════════════════════════════════════════════════════════════
    
    /**
     * @dev Inserisce risultati elettorali ufficiali per confronto
     * @param campaignId ID campagna
     * @param candidate Candidato
     * @param officialVotes Voti ufficiali dichiarati dalle autorità
     */
    function submitOfficialResults(
        bytes32 campaignId,
        string memory candidate,
        uint256 officialVotes
    ) external onlyOwner {
        ElectionCampaign storage campaign = campaigns[campaignId];
        require(block.timestamp > campaign.endTime, "Voting not ended");
        
        officialResults[campaignId][candidate] = officialVotes;
        
        emit OfficialResultsSubmitted(campaignId, candidate, officialVotes);
        
        // Auto-detect manipulation
        _checkForManipulation(campaignId, candidate);
    }
    
    /**
     * @dev Verifica manipolazione confrontando blockchain vs risultati ufficiali
     */
    function _checkForManipulation(bytes32 campaignId, string memory candidate) internal {
        uint256 blockchainVotes = blockchainResults[campaignId][candidate];
        uint256 official = officialResults[campaignId][candidate];
        
        if (blockchainVotes == 0 || official == 0) return; // Skip se uno è zero
        
        uint256 difference;
        if (blockchainVotes > official) {
            difference = ((blockchainVotes - official) * 100) / blockchainVotes;
        } else {
            difference = ((official - blockchainVotes) * 100) / official;
        }
        
        if (difference > MANIPULATION_THRESHOLD) {
            manipulationDetected[campaignId] = true;
            
            string memory details = string(abi.encodePacked(
                "Candidate: ", candidate, 
                " | Blockchain: ", Strings.toString(blockchainVotes),
                " | Official: ", Strings.toString(official),
                " | Difference: ", Strings.toString(difference), "%"
            ));
            
            emit ManipulationDetected(campaignId, details);
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // TRASPARENZA E AUDIT FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════
    
    /**
     * @dev Genera report trasparenza completo
     */
    function generateTransparencyReport(bytes32 campaignId) external view returns (
        string[] memory candidates,
        uint256[] memory blockchainVotes,
        uint256[] memory officialVotes,
        bool manipulationFound
    ) {
        ElectionCampaign storage campaign = campaigns[campaignId];
        
        candidates = campaign.candidateList;
        blockchainVotes = new uint256[](candidates.length);
        officialVotes = new uint256[](candidates.length);
        
        for (uint256 i = 0; i < candidates.length; i++) {
            blockchainVotes[i] = blockchainResults[campaignId][candidates[i]];
            officialVotes[i] = officialResults[campaignId][candidates[i]];
        }
        
        manipulationFound = manipulationDetected[campaignId];
    }
    
    /**
     * @dev Ottiene dettagli candidato per campagna
     */
    function getCandidateDetails(
        bytes32 campaignId, 
        string memory candidate
    ) external view returns (
        string memory officialName,
        string memory party,
        uint256 totalPurchases,
        uint256 totalAmount,
        uint256 uniqueVoters
    ) {
        CandidateToken storage candidateData = campaigns[campaignId].candidates[candidate];
        require(candidateData.exists, "Candidate not found");
        
        return (
            candidateData.officialName,
            candidateData.party,
            candidateData.totalPurchases,
            candidateData.totalAmount,
            candidateData.uniqueVoters
        );
    }
    
    /**
     * @dev Audit trail completo per trasparenza
     */
    function getVoteHistory(bytes32 campaignId) external view returns (VoteRecord[] memory) {
        return voteHistory[campaignId];
    }
    
    // ═══════════════════════════════════════════════════════════════════
    // EMERGENCY FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════
    
    function lockCampaignResults(bytes32 campaignId) external onlyOwner {
        campaigns[campaignId].resultsLocked = true;
    }
    
    function emergencyPause(bytes32 campaignId) external onlyOwner {
        campaigns[campaignId].isActive = false;
    }
}
