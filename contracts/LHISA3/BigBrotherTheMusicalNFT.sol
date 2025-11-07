// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca - Avv. - ITALY Florence
// Author and architect of the Solidary.it ecosystem and this smart contract.
// The ecosystem and its logical components (.sol files and scripts) are protected by copyright.
// Solidary Network® - Compassionate Blockchain Infrastructure

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// ═══════════════════════════════════════════════════════════════════════════════
// 🌐 SOLIDARY ECOSYSTEM INTERFACES  
// ═══════════════════════════════════════════════════════════════════════════════

interface ISolidaryTrustManager {
    function isValidated(address user) external view returns (bool);
    function getReputationScore(address user) external view returns (uint256);
}

interface ISolidaryHub {
    function isActiveMember(address user) external view returns (bool);
    function getMembershipLevel(address user) external view returns (uint256);
}

/**
 * @title BigBrotherTheMusicalNFT
 * @author Avv. Marcello Stanca - Solidary Network Architect
 * @notice Collezione NFT musicale del Maestro Stefano Burbi integrata nell'ecosistema Solidary
 * @dev ERC-1155 Upgradeable con integrazione completa Solidary Network
 * 
 * 🎭 BBTM Musical Collection Features:
 * - 20 NFT musicali unici (Token IDs: 5, 10, 15... 100)
 * - Valori configurati in EUR (da 0.25€ a 5.00€)
 * - Integrazione completa Solidary Network  
 * - Mint gratuiti per membri Solidary verificati
 * - Royalties automatiche per Maestro e Impact Fund
 * - Bridge cross-chain ready
 * - Upgradeable con pattern UUPS
 * 
 * © Copyright Marcello Stanca - Solidary Network Ecosystem
 */
contract BigBrotherTheMusicalNFT is 
    Initializable,
    ERC1155Upgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC2981Upgradeable
{
    using Strings for uint256;

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎭 SOLIDARY ECOSYSTEM INTEGRATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    // Ruoli dell'ecosistema Solidary
    bytes32 public constant MAESTRO_ROLE = keccak256("MAESTRO_ROLE");
    bytes32 public constant ECOSYSTEM_MANAGER_ROLE = keccak256("ECOSYSTEM_MANAGER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    // Informazioni collezione
    string public name;
    string public symbol;
    string private _contractURI;
    string public baseURI;
    
    // Integrazione Solidary
    ISolidaryTrustManager public solidaryTrustManager;
    ISolidaryHub public solidaryHub;
    address public ecosystemArchitect; // Avv. Marcello Stanca
    address public maestroWallet;      // Maestro Stefano Burbi
    address public impactFundWallet;   // Fondo impatto sociale
    
    // Configurazione NFT musicali
    struct MusicalNFT {
        string title;           // Titolo del brano
        string composer;        // Compositore 
        uint256 euroValue;      // Valore in centesimi di EUR (es: 100 = 1.00 EUR)
        uint256 maxSupply;      // Supply massima
        uint256 mintedSupply;   // Supply già mintata
        bool isActive;          // Se è attivo per mint
        uint256 solidaryLevel;  // Livello richiesto nell'ecosistema (0=tutti)
        string ipfsCID;         // CID IPFS per metadata specifici
    }
    
    mapping(uint256 => MusicalNFT) public musicalNFTs;
    mapping(address => mapping(uint256 => uint256)) public userMintCount; // User => TokenId => Count
    
    // Token IDs configurati (20 NFT - multipli di 5: da 5 a 100)
    // Struttura IPFS: 5.jpg, 10.jpg, 15.jpg, 20.jpg, 25.jpg... fino a 100.jpg
    uint256[] public availableTokenIds;
    mapping(uint256 => bool) public isValidTokenId;
    
    // Economia dell'ecosistema
    uint256 public maestroRoyaltyPercentage; // 6% al Maestro
    uint256 public ecosystemFeePercentage;   // 2% all'ecosistema
    uint256 public impactFundPercentage;     // 1% al fondo impatto
    
    // Limiti e controlli
    uint256 public maxMintsPerUser;
    uint256 public maxMintsPerTransaction;
    bool public solidaryOnlyMode; // Se true, solo membri Solidary possono mintare
    
    // Versioning
    uint256 public contractVersion;
    string public versionString;

    // ═══════════════════════════════════════════════════════════════════════════════
    // 📢 EVENTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    event MusicalNFTMinted(
        address indexed to, 
        uint256 indexed tokenId, 
        uint256 amount, 
        uint256 euroValue,
        string title
    );
    
    event MusicalNFTConfigured(
        uint256 indexed tokenId,
        string title,
        string composer,
        uint256 euroValue,
        uint256 maxSupply
    );
    
    event SolidaryIntegrationUpdated(
        address indexed trustManager,
        address indexed hub,
        bool solidaryOnlyMode
    );
    
    event RoyaltiesDistributed(
        address indexed maestro,
        address indexed ecosystem, 
        address indexed impactFund,
        uint256 maestroAmount,
        uint256 ecosystemAmount,
        uint256 impactAmount
    );

    event BaseURIUpdated(string newBaseURI);
    event ContractURIUpdated(string newContractURI);

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🚀 INITIALIZATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    /**
     * @notice Inizializza il contratto BigBrotherTheMusicalNFT
     * @param _baseURI URI base per i metadata IPFS
          * @param _contractURIParam URI del contratto per metadata collezione  
     * @param _ecosystemArchitect Indirizzo Avv. Marcello Stanca
     * @param _maestroWallet Indirizzo Maestro Stefano Burbi
     * @param _trustManager Indirizzo SolidaryTrustManager
     * @param _solidaryHub Indirizzo SolidaryHub
     */
    function initialize(
        string memory _baseURI,
        string memory _contractURIParam,
        address _ecosystemArchitect,
        address _maestroWallet,
        address _trustManager,
        address _solidaryHub
    ) public initializer {
        require(bytes(_baseURI).length > 0, "Base URI cannot be empty");
        require(bytes(_contractURIParam).length > 0, "Contract URI cannot be empty");
        require(_ecosystemArchitect != address(0), "Ecosystem architect cannot be zero");
        require(_maestroWallet != address(0), "Maestro wallet cannot be zero");
        
        __ERC1155_init(_baseURI);
        __AccessControl_init();
        __ReentrancyGuard_init();
        __ERC2981_init();
        __UUPSUpgradeable_init();
        
        // Configurazioni iniziali
        name = "BigBrother The Musical";
        symbol = "BBTM";
        baseURI = _baseURI;
        _contractURI = _contractURIParam;
        
        ecosystemArchitect = _ecosystemArchitect;
        maestroWallet = _maestroWallet;
        impactFundWallet = _ecosystemArchitect; // Inizialmente stesso dell'architetto
        
        // Integrazione Solidary
        solidaryTrustManager = ISolidaryTrustManager(_trustManager);
        solidaryHub = ISolidaryHub(_solidaryHub);
        
        // Setup ruoli
        _grantRole(DEFAULT_ADMIN_ROLE, _ecosystemArchitect);
        _grantRole(MAESTRO_ROLE, _maestroWallet);
        _grantRole(MINTER_ROLE, _ecosystemArchitect);
        
        // Inizializza configurazioni economia
        maestroRoyaltyPercentage = 600; // 6% al Maestro
        ecosystemFeePercentage = 200;   // 2% all'ecosistema
        impactFundPercentage = 100;     // 1% al fondo impatto
        
        // Inizializza limiti e controlli
        maxMintsPerUser = 10;
        maxMintsPerTransaction = 3;
        solidaryOnlyMode = false; // Inizialmente aperto a tutti
        
        // Inizializza versioning
        contractVersion = 1;
        versionString = "1.0.0-solidary-integrated";
        
        // Configura royalties (8% totali)
        _setDefaultRoyalty(_ecosystemArchitect, 800); // 8%
        
        // Inizializza token musicali predefiniti
        _initializeMusicalTokens();
    }
    
    /**
     * @dev Inizializza i token musicali predefiniti (ID 5,10,15,20,25,30)
     */
    function _initializeMusicalTokens() internal {
        // 🎵 COLLEZIONE COMPLETA BBTM - 20 NFT MUSICALI (Token IDs: 5 a 100, multipli di 5)
        // Come previsto dalla struttura IPFS: 5.jpg, 10.jpg, 15.jpg... fino a 100.jpg
        
        // Serie 1: Introduzioni e Aperture (5-25) - Valori bassi, supply alta
        _configureMusicalNFT(5, "Ouverture Solidale", "Maestro Stefano Burbi", 25, 2000, "bafybeih7fvejarethnnngvvzwxvwjm7uzrzyj36wntxjlfbumjq4v5t6mu");      // 0.25€
        _configureMusicalNFT(10, "Preludio Compassione", "Maestro Stefano Burbi", 50, 1500, "bafybeih7fvejarethnnngvvzwxvwjm7uzrzyj36wntxjlfbumjq4v5t6mu");     // 0.50€
        _configureMusicalNFT(15, "Aria del Cuore Solidale", "Maestro Stefano Burbi", 75, 1200, "bafybeih7fvejarethnnngvvzwxvwjm7uzrzyj36wntxjlfbumjq4v5t6mu");   // 0.75€
        _configureMusicalNFT(20, "Intermezzo Blockchain", "Maestro Stefano Burbi", 100, 1000, "bafybeih7fvejarethnnngvvzwxvwjm7uzrzyj36wntxjlfbumjq4v5t6mu");    // 1.00€
        _configureMusicalNFT(25, "Sinfonia della Compassion", "Maestro Stefano Burbi", 125, 800, "bafybeih7fvejarethnnngvvzwxvwjm7uzrzyj36wntxjlfbumjq4v5t6mu");  // 1.25€
        
        // Serie 2: Sviluppi Tematici (30-50) - Valori medi, supply media
        _configureMusicalNFT(30, "Movimento Solidary Hearts", "Maestro Stefano Burbi", 150, 600, "bafybeih7fvejarethnnngvvzwxvwjm7uzrzyj36wntxjlfbumjq4v5t6mu");   // 1.50€
        _configureMusicalNFT(35, "Crescendo Tecnologico", "Maestro Stefano Burbi", 175, 500, "bafybeih7fvejarethnnngvvzwxvwjm7uzrzyj36wntxjlfbumjq4v5t6mu");     // 1.75€
        _configureMusicalNFT(40, "Variazioni Ecosystem", "Maestro Stefano Burbi", 200, 400, "bafybeih7fvejarethnnngvvzwxvwjm7uzrzyj36wntxjlfbumjq4v5t6mu");      // 2.00€
        _configureMusicalNFT(45, "Fuga Umanita Digitale", "Maestro Stefano Burbi", 225, 300, "bafybeih7fvejarethnnngvvzwxvwjm7uzrzyj36wntxjlfbumjq4v5t6mu");     // 2.25€
        _configureMusicalNFT(50, "Suite dell'Innovazione", "Maestro Stefano Burbi", 250, 250, "bafybeih7fvejarethnnngvvzwxvwjm7uzrzyj36wntxjlfbumjq4v5t6mu");     // 2.50€
        
        // Serie 3: Climax e Virtuosismi (55-75) - Valori alti, supply limitata
        _configureMusicalNFT(55, "Rapsodi Solidary Network", "Maestro Stefano Burbi", 275, 200, "bafybeih7fvejarethnnngvvzwxvwjm7uzrzyj36wntxjlfbumjq4v5t6mu");   // 2.75€
        _configureMusicalNFT(60, "Concerto per Smart Contract", "Maestro Stefano Burbi", 300, 150, "bafybeih7fvejarethnnngvvzwxvwjm7uzrzyj36wntxjlfbumjq4v5t6mu"); // 3.00€
        _configureMusicalNFT(65, "Sonata del Trust Manager", "Maestro Stefano Burbi", 325, 120, "bafybeih7fvejarethnnngvvzwxvwjm7uzrzyj36wntxjlfbumjq4v5t6mu");   // 3.25€
        _configureMusicalNFT(70, "Polonaise Governante", "Maestro Stefano Burbi", 350, 100, "bafybeih7fvejarethnnngvvzwxvwjm7uzrzyj36wntxjlfbumjq4v5t6mu");      // 3.50€
        _configureMusicalNFT(75, "Toccata Impact Fund", "Maestro Stefano Burbi", 375, 80, "bafybeih7fvejarethnnngvvzwxvwjm7uzrzyj36wntxjlfbumjq4v5t6mu");        // 3.75€
        
        // Serie 4: Capolavori e Collector's Edition (80-100) - Valori premium, supply rarissima
        _configureMusicalNFT(80, "Fantasia Marcello's Dream", "Maestro Stefano Burbi", 400, 60, "bafybeih7fvejarethnnngvvzwxvwjm7uzrzyj36wntxjlfbumjq4v5t6mu");    // 4.00€
        _configureMusicalNFT(85, "Ballata Cross-Chain Bridge", "Maestro Stefano Burbi", 425, 50, "bafybeih7fvejarethnnngvvzwxvwjm7uzrzyj36wntxjlfbumjq4v5t6mu");   // 4.25€
        _configureMusicalNFT(90, "Elegia Memory Hill", "Maestro Stefano Burbi", 450, 40, "bafybeih7fvejarethnnngvvzwxvwjm7uzrzyj36wntxjlfbumjq4v5t6mu");         // 4.50€
        _configureMusicalNFT(95, "Requiem per il Web2", "Maestro Stefano Burbi", 475, 30, "bafybeih7fvejarethnnngvvzwxvwjm7uzrzyj36wntxjlfbumjq4v5t6mu");          // 4.75€
        _configureMusicalNFT(100, "Grande Finale Vision Orchestrale", "Maestro Stefano Burbi", 500, 20, "bafybeih7fvejarethnnngvvzwxvwjm7uzrzyj36wntxjlfbumjq4v5t6mu"); // 5.00€ - Ultra Raro
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎵 MUSICAL NFT CONFIGURATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Configura un nuovo NFT musicale
     * @param tokenId ID del token (deve essere multiplo di 5)
     * @param title Titolo del brano
     * @param composer Compositore
     * @param euroValue Valore in centesimi di EUR
     * @param maxSupply Supply massima
     * @param ipfsCID CID IPFS per metadata specifici
     */
    function configureMusicalNFT(
        uint256 tokenId,
        string memory title,
        string memory composer,
        uint256 euroValue,
        uint256 maxSupply,
        string memory ipfsCID
    ) external onlyRole(ECOSYSTEM_MANAGER_ROLE) {
        _configureMusicalNFT(tokenId, title, composer, euroValue, maxSupply, ipfsCID);
    }
    
    function _configureMusicalNFT(
        uint256 tokenId,
        string memory title,
        string memory composer,
        uint256 euroValue,
        uint256 maxSupply,
        string memory ipfsCID
    ) internal {
        require(tokenId > 0 && tokenId <= 10000, "Invalid token ID");
        require(tokenId % 5 == 0, "Token ID must be multiple of 5");
        require(bytes(title).length > 0, "Title cannot be empty");
        require(euroValue > 0, "Euro value must be positive");
        require(maxSupply > 0, "Max supply must be positive");
        
        // Aggiungi alla lista se nuovo
        if (!isValidTokenId[tokenId]) {
            availableTokenIds.push(tokenId);
            isValidTokenId[tokenId] = true;
        }
        
        musicalNFTs[tokenId] = MusicalNFT({
            title: title,
            composer: composer,
            euroValue: euroValue,
            maxSupply: maxSupply,
            mintedSupply: 0,
            isActive: true,
            solidaryLevel: 0, // Accessibile a tutti inizialmente
            ipfsCID: ipfsCID
        });
        
        emit MusicalNFTConfigured(tokenId, title, composer, euroValue, maxSupply);
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎭 MINTING FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Mint di NFT musicali con pagamento in MATIC
     * @param to Destinatario dell'NFT
     * @param tokenId ID del token da mintare
     * @param amount Quantità da mintare
     */
    function mintMusicalNFT(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external payable nonReentrant {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0 && amount <= maxMintsPerTransaction, "Invalid amount");
        require(isValidTokenId[tokenId], "Invalid token ID");
        
        MusicalNFT storage nft = musicalNFTs[tokenId];
        require(nft.isActive, "Token not active for minting");
        require(nft.mintedSupply + amount <= nft.maxSupply, "Exceeds max supply");
        
        // Controlli Solidary se attivo
        if (solidaryOnlyMode) {
            require(solidaryHub.isActiveMember(msg.sender), "Not a Solidary member");
        }
        
        // Controlli limiti utente
        require(userMintCount[to][tokenId] + amount <= maxMintsPerUser, "Exceeds user mint limit");
        
        // Calcolo prezzo in MATIC (conversione EUR -> MATIC approssimativa)
        uint256 totalEuroValue = nft.euroValue * amount;
        uint256 requiredMatic = _euroToMatic(totalEuroValue);
        require(msg.value >= requiredMatic, "Insufficient payment");
        
        // Aggiorna contatori
        nft.mintedSupply += amount;
        userMintCount[to][tokenId] += amount;
        
        // Mint dell'NFT
        _mint(to, tokenId, amount, "");
        
        // Distribuzione royalties
        _distributeRoyalties(msg.value);
        
        // Rimborso eccesso
        if (msg.value > requiredMatic) {
            payable(msg.sender).transfer(msg.value - requiredMatic);
        }
        
        emit MusicalNFTMinted(to, tokenId, amount, totalEuroValue, nft.title);
    }
    
    /**
     * @notice Mint gratuito per membri Solidary verificati
     * @param to Destinatario dell'NFT
     * @param tokenId ID del token da mintare
     * @param amount Quantità da mintare
     */
    function solidaryFreeMint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external nonReentrant {
        require(solidaryTrustManager.isValidated(msg.sender), "Not validated by TrustManager");
        require(solidaryHub.isActiveMember(msg.sender), "Not active Solidary member");
        require(solidaryHub.getMembershipLevel(msg.sender) >= 3, "Insufficient membership level");
        
        require(isValidTokenId[tokenId], "Invalid token ID");
        require(amount <= 2, "Max 2 free mints"); // Limite per mint gratuiti
        
        MusicalNFT storage nft = musicalNFTs[tokenId];
        require(nft.isActive, "Token not active");
        require(nft.mintedSupply + amount <= nft.maxSupply, "Exceeds max supply");
        require(userMintCount[to][tokenId] == 0, "Already claimed free mint");
        
        // Aggiorna contatori
        nft.mintedSupply += amount;
        userMintCount[to][tokenId] += amount;
        
        // Mint gratuito
        _mint(to, tokenId, amount, "");
        
        emit MusicalNFTMinted(to, tokenId, amount, 0, nft.title);
    }
    
    /**
     * @notice Mint esclusivo per il Maestro e amministratori
     */
    function masterMint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external onlyRole(MAESTRO_ROLE) {
        require(isValidTokenId[tokenId], "Invalid token ID");
        
        MusicalNFT storage nft = musicalNFTs[tokenId];
        require(nft.mintedSupply + amount <= nft.maxSupply, "Exceeds max supply");
        
        nft.mintedSupply += amount;
        _mint(to, tokenId, amount, "");
        
        emit MusicalNFTMinted(to, tokenId, amount, 0, nft.title);
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 💰 ECONOMIC FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Conversione approssimativa EUR -> MATIC (basata su prezzo medio)
     */
    function _euroToMatic(uint256 euroCents) internal pure returns (uint256) {
        // Conversione semplificata: 1 EUR ≈ 2 MATIC (da aggiornare con oracle)
        return (euroCents * 2 * 1e18) / 100; // euroCents in wei MATIC
    }
    
    /**
     * @dev Distribuzione delle royalties tra stakeholder
     */
    function _distributeRoyalties(uint256 totalAmount) internal {
        uint256 maestroAmount = (totalAmount * maestroRoyaltyPercentage) / 10000;
        uint256 ecosystemAmount = (totalAmount * ecosystemFeePercentage) / 10000;
        uint256 impactAmount = (totalAmount * impactFundPercentage) / 10000;
        
        // Trasferimenti
        if (maestroAmount > 0) {
            payable(maestroWallet).transfer(maestroAmount);
        }
        
        if (ecosystemAmount > 0) {
            payable(ecosystemArchitect).transfer(ecosystemAmount);
        }
        
        if (impactAmount > 0) {
            payable(impactFundWallet).transfer(impactAmount);
        }
        
        emit RoyaltiesDistributed(
            maestroWallet, 
            ecosystemArchitect, 
            impactFundWallet,
            maestroAmount,
            ecosystemAmount, 
            impactAmount
        );
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔧 ADMINISTRATION FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Aggiorna il BaseURI per i metadata
     */
    function setBaseURI(string memory newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(newBaseURI).length > 0, "Base URI cannot be empty");
        baseURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }
    
    /**
     * @notice Aggiorna il ContractURI per i metadata della collezione
     */
    function setContractURI(string memory newContractURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bytes(newContractURI).length > 0, "Contract URI cannot be empty");
        _contractURI = newContractURI;
        emit ContractURIUpdated(newContractURI);
    }
    
    /**
     * @notice Aggiorna l'integrazione Solidary
     */
    function updateSolidaryIntegration(
        address _trustManager,
        address _solidaryHub,
        bool _solidaryOnlyMode
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        solidaryTrustManager = ISolidaryTrustManager(_trustManager);
        solidaryHub = ISolidaryHub(_solidaryHub);
        solidaryOnlyMode = _solidaryOnlyMode;
        
        emit SolidaryIntegrationUpdated(_trustManager, _solidaryHub, _solidaryOnlyMode);
    }
    
    /**
     * @notice Ritiro fondi dal contratto
     */
    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        payable(ecosystemArchitect).transfer(balance);
    }
    


    // ═══════════════════════════════════════════════════════════════════════════════
    // 👁️ VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Ottieni informazioni su un NFT musicale
     */
    function getMusicalNFTInfo(uint256 tokenId) external view returns (MusicalNFT memory) {
        require(isValidTokenId[tokenId], "Invalid token ID");
        return musicalNFTs[tokenId];
    }
    
    /**
     * @notice Ottieni tutti i token ID disponibili
     */
    function getAvailableTokenIds() external view returns (uint256[] memory) {
        return availableTokenIds;
    }
    
    /**
     * @notice Verifica se un utente può mintare gratuitamente
     */
    function canClaimFreeMint(address user, uint256 tokenId) external view returns (bool) {
        if (!solidaryTrustManager.isValidated(user)) return false;
        if (!solidaryHub.isActiveMember(user)) return false;
        if (solidaryHub.getMembershipLevel(user) < 3) return false;
        if (userMintCount[user][tokenId] > 0) return false;
        return true;
    }
    
    /**
     * @notice URI del contratto (metadata collezione)
     */
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }
    
    /**
     * @notice URI di un token specifico
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔒 REQUIRED OVERRIDES
    // ═══════════════════════════════════════════════════════════════════════════════
    

    
    function supportsInterface(bytes4 interfaceId) 
        public view override(ERC1155Upgradeable, AccessControlUpgradeable, ERC2981Upgradeable) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
    
    function _authorizeUpgrade(address newImplementation) 
        internal override onlyRole(DEFAULT_ADMIN_ROLE) 
    {}
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📋 CONTRACT INFO
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Informazioni complete del contratto
     */
    function getContractInfo() external view returns (
        string memory contractName,
        string memory contractSymbol,
        address architect,
        address maestro,
        uint256 version,
        uint256 totalTokenTypes
    ) {
        return (
            name,
            symbol, 
            ecosystemArchitect,
            maestroWallet,
            contractVersion,
            availableTokenIds.length
        );
    }
}