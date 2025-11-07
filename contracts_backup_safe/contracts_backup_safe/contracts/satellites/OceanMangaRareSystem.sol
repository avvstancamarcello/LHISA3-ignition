// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca - Italy - Florence. Author and owner of the Solidary.it ecosystem and this smart contract.

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../metrics/SolidarySystemMetrics.sol";

interface IOceanMangaNFT {
    function mint(address to, uint256 id, uint256 amount, bytes calldata data) external;
    function setURI(uint256 tokenId, string memory newuri) external;
}

interface ILunaComicsFT {
    function mint(address to, uint256 amount) external payable;
    function totalSupply() external view returns (uint256);
}

/**
 * @title OceanMangaRareSystem  
 * @author Avv. Marcello Stanca
 * @notice Sistema per NFT rari premium che stabilizza il valore dell'ecosistema
 * @dev Permette all'owner di mintare NFT rari con valore maggiore per collezionisti
 */
contract OceanMangaRareSystem is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using StringsUpgradeable for uint256;
    
    IOceanMangaNFT public nftContract;
    ILunaComicsFT public ftContract;
    SolidarySystemMetrics public metricsOracle;
    
    // Base URI for rare NFTs
    string public rareBaseURI;
    
    // Rare NFT data
    struct RareNFT {
        uint256 tokenId;
        string specialCID;
        uint256 rareValue; // Valore in ETH del NFT raro
        address celebrity; // Indirizzo del personaggio/influencer (opzionale)
        string description; // Descrizione del pezzo raro
        uint256 mintTimestamp;
        bool isActive;
    }
    
    mapping(uint256 => RareNFT) public rareNFTs;
    uint256 public nextRareTokenId = 10000; // Inizia da 10000 per distinguere dai normali
    uint256 public totalRareValue; // Valore totale NFT rari in circolazione
    
    // Charity settings per NFT rari
    address public charityWallet;
    uint256 public rareCharityPercentage = 50; // 50% per charity sui NFT rari
    
    // Celebrity system
    mapping(address => bool) public approvedCelebrities;
    mapping(address => string) public celebrityNames;
    
    // Events
    event RareNFTMinted(
        uint256 indexed tokenId,
        address indexed recipient,
        address indexed celebrity,
        uint256 rareValue,
        string cid
    );
    
    event RareValueUpdated(uint256 tokenId, uint256 oldValue, uint256 newValue);
    event CelebrityApproved(address indexed celebrity, string name);
    event CharityDonationFromRare(uint256 amount, uint256 tokenId);
    event BaseURIUpdated(string oldURI, string newURI);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        address _nftContract,
        address _ftContract,
        address _metricsOracle,
        address _charityWallet,
        string memory _initialBaseURI
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        
        nftContract = IOceanMangaNFT(_nftContract);
        ftContract = ILunaComicsFT(_ftContract);
        metricsOracle = SolidarySystemMetrics(_metricsOracle);
        charityWallet = _charityWallet;
        rareBaseURI = _initialBaseURI;
    }
    
    /**
     * @notice Minta un NFT raro con valore premium (solo owner)
     * @param recipient Destinatario del NFT raro
     * @param specialCID CID IPFS specifico per questo NFT raro
     * @param rareValue Valore in ETH del NFT raro
     * @param celebrity Indirizzo del personaggio famoso (opzionale)
     * @param description Descrizione del pezzo raro
     */
    function mintRareNFT(
        address recipient,
        string memory specialCID,
        uint256 rareValue,
        address celebrity,
        string memory description
    ) external payable onlyOwner nonReentrant returns (uint256) {
        require(recipient != address(0), "Invalid recipient");
        require(bytes(specialCID).length > 0, "CID required");
        require(rareValue > 0, "Value must be > 0");
        
        // Se c'è un celebrity, deve essere approvato
        if (celebrity != address(0)) {
            require(approvedCelebrities[celebrity], "Celebrity not approved");
        }
        
        uint256 tokenId = nextRareTokenId++;
        
        // Calcola donazione charity
        uint256 charityAmount = (rareValue * rareCharityPercentage) / 100;
        require(msg.value >= charityAmount, "Insufficient payment for charity");
        
        // Crea struttura NFT raro
        rareNFTs[tokenId] = RareNFT({
            tokenId: tokenId,
            specialCID: specialCID,
            rareValue: rareValue,
            celebrity: celebrity,
            description: description,
            mintTimestamp: block.timestamp,
            isActive: true
        });
        
        // Aggiorna valore totale raro
        totalRareValue += rareValue;
        
        // Mint NFT con metadata speciale
        string memory tokenURI = string(abi.encodePacked(rareBaseURI, specialCID));
        nftContract.mint(recipient, tokenId, 1, abi.encode(tokenURI, "RARE"));
        
        // Dona alla charity
        if (charityAmount > 0) {
            payable(charityWallet).transfer(charityAmount);
            
            // Registra donazione nell'oracle metriche
            metricsOracle.registerCharityDonation(
                charityAmount, 
                string(abi.encodePacked("Rare NFT #", tokenId.toString()))
            );
            
            emit CharityDonationFromRare(charityAmount, tokenId);
        }
        
        // Rimborsa eventuale eccesso
        if (msg.value > charityAmount) {
            payable(msg.sender).transfer(msg.value - charityAmount);
        }
        
        emit RareNFTMinted(tokenId, recipient, celebrity, rareValue, specialCID);
        return tokenId;
    }
    
    /**
     * @notice Approva un personaggio famoso/influencer
     * @param celebrity Indirizzo del personaggio
     * @param name Nome del personaggio
     */
    function approveCelebrity(address celebrity, string memory name) external onlyOwner {
        require(celebrity != address(0), "Invalid celebrity address");
        require(bytes(name).length > 0, "Name required");
        
        approvedCelebrities[celebrity] = true;
        celebrityNames[celebrity] = name;
        
        emit CelebrityApproved(celebrity, name);
    }
    
    /**
     * @notice Rimuove approvazione personaggio
     */
    function revokeCelebrity(address celebrity) external onlyOwner {
        approvedCelebrities[celebrity] = false;
        delete celebrityNames[celebrity];
    }
    
    /**
     * @notice Aggiorna il valore di un NFT raro esistente
     * @param tokenId ID del token raro
     * @param newValue Nuovo valore in ETH
     */
    function updateRareValue(uint256 tokenId, uint256 newValue) external onlyOwner {
        require(rareNFTs[tokenId].isActive, "NFT not found or inactive");
        require(newValue > 0, "Value must be > 0");
        
        uint256 oldValue = rareNFTs[tokenId].rareValue;
        
        // Aggiorna valore totale
        totalRareValue = totalRareValue - oldValue + newValue;
        
        // Aggiorna NFT
        rareNFTs[tokenId].rareValue = newValue;
        
        emit RareValueUpdated(tokenId, oldValue, newValue);
    }
    
    /**
     * @notice Imposta nuovo Base URI per NFT rari
     */
    function setRareBaseURI(string memory newBaseURI) external onlyOwner {
        string memory oldURI = rareBaseURI;
        rareBaseURI = newBaseURI;
        emit BaseURIUpdated(oldURI, newBaseURI);
    }
    
    /**
     * @notice Calcola il valore teorico stabilizzato per i FT
     * @dev Considera il valore dei NFT rari per stabilizzare il prezzo FT
     * @return stabilizedValue Valore teorico stabilizzato per FT
     */
    function calculateStabilizedFTValue() external view returns (uint256 stabilizedValue) {
        uint256 ftSupply = ftContract.totalSupply();
        if (ftSupply == 0) return 0;
        
        // Valore base dai mint normali (45% del bilanciamento)
        uint256 baseValue = address(this).balance;
        
        // Aggiunge valore teorico dai NFT rari (effetto stabilizzazione)
        uint256 rareBonus = (totalRareValue * 20) / 100; // 20% del valore raro influenza FT
        
        // Calcola valore per singolo FT
        stabilizedValue = (baseValue + rareBonus) / ftSupply;
        
        return stabilizedValue;
    }
    
    /**
     * @notice Ottieni informazioni complete su un NFT raro
     */
    function getRareNFTInfo(uint256 tokenId) external view returns (
        RareNFT memory rareInfo,
        string memory celebrityName,
        bool isCelebrityActive
    ) {
        require(rareNFTs[tokenId].isActive, "NFT not found");
        
        rareInfo = rareNFTs[tokenId];
        
        if (rareInfo.celebrity != address(0)) {
            celebrityName = celebrityNames[rareInfo.celebrity];
            isCelebrityActive = approvedCelebrities[rareInfo.celebrity];
        }
        
        return (rareInfo, celebrityName, isCelebrityActive);
    }
    
    /**
     * @notice Statistiche complete dell'ecosistema
     */
    function getEcosystemStats() external view returns (
        uint256 totalRareNFTs,
        uint256 totalRareValueWei,
        uint256 stabilizedFTValue,
        uint256 totalCharityFromRares,
        uint256 ftTotalSupply
    ) {
        totalRareNFTs = nextRareTokenId - 10000;
        totalRareValueWei = totalRareValue;
        stabilizedFTValue = this.calculateStabilizedFTValue();
        totalCharityFromRares = metricsOracle.getTotalCharityDonations();
        ftTotalSupply = ftContract.totalSupply();
        
        return (totalRareNFTs, totalRareValueWei, stabilizedFTValue, totalCharityFromRares, ftTotalSupply);
    }
    
    /**
     * @notice Aggiorna percentuale charity per NFT rari
     */
    function setRareCharityPercentage(uint256 newPercentage) external onlyOwner {
        require(newPercentage <= 100, "Percentage too high");
        rareCharityPercentage = newPercentage;
    }
    
    /**
     * @notice Aggiorna indirizzo charity
     */
    function setCharityWallet(address newCharity) external onlyOwner {
        require(newCharity != address(0), "Invalid charity address");
        charityWallet = newCharity;
    }
    
    /**
     * @notice Withdraw di emergenza (solo owner)
     */
    function emergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    // Permette di ricevere ETH
    receive() external payable {}
}