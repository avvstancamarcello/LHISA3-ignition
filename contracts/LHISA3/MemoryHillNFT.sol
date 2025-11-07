// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca Lawyer - ITALY Florence

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title MemoryHillNFT
 * @dev Campo Santo virtuale su blockchain per onorare la memoria dei caduti e dispersi di guerra
 * 
 * 🌹 CONCETTO: 
 * Il Piccolo Principe, custode di un pianeta deserto, diventa giardiniere del giardino della memoria.
 * Ogni NFT rappresenta un'aiuola dedicata alla memoria eterna di una persona cara.
 * L'utente "semina" le colline deserte mintando un prato monofloreale o multicolore.
 * 
 * 🎭 MECCANICA:
 * 1. L'utente sceglie il tipo di fiore per l'aiuola
 * 2. Il Piccolo Principe coglie una stella dal cielo (l'anima del defunto)
 * 3. La semina nel campo che fiorisce immediatamente
 * 4. Viene creato un NFT permanente con metadati IPFS
 */
contract MemoryHillNFT is 
    Initializable, 
    ERC721Upgradeable, 
    ERC721URIStorageUpgradeable, 
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable 
{
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌹 STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    uint256 public nextTokenId;
    uint256 public totalSupply;
    uint256 public mintPrice; // Prezzo in wei per mintare un NFT memoria
    
    string private _baseTokenURI;
    string private _contractURI;
    
    // Mapping per i metadati di ogni aiuola della memoria
    mapping(uint256 => MemorialPlot) public memorialPlots;
    
    // Mapping per tenere traccia dei fiori disponibili
    mapping(string => bool) public availableFlowers;
    string[] public flowerTypes;
    
    // Statistiche
    uint256 public totalMemorials;
    mapping(address => uint256[]) public userMemorials;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌹 STRUCTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    struct MemorialPlot {
        string belovedName;        // Nome del defunto/disperso
        string flowerType;         // Tipo di fiore scelto
        string memoryMessage;      // Messaggio di memoria
        string warConflict;        // Guerra/conflitto di riferimento
        uint256 timestamp;         // Quando è stato creato il memoriale
        address gardener;          // Chi ha "seminato" l'aiuola
        bool isActive;            // Se il memoriale è attivo
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌹 EVENTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    event MemorialPlanted(
        uint256 indexed tokenId,
        address indexed gardener,
        string belovedName,
        string flowerType,
        string memoryMessage
    );
    
    event FlowerTypeAdded(string flowerType);
    event PriceUpdated(uint256 newPrice);
    event BaseURIUpdated(string newBaseURI);
    event ContractURIUpdated(string newContractURI);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌹 INITIALIZATION
    // ═══════════════════════════════════════════════════════════════════════════════

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        uint256 _mintPrice,
        string memory _initialBaseURI,
        string memory _initialContractURI
    ) public initializer {
        __ERC721_init("Memory Hill NFT", "MEMORIAL");
        __ERC721URIStorage_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        
        transferOwnership(initialOwner);
        nextTokenId = 1;
        totalSupply = 0;
        mintPrice = _mintPrice;
        _baseTokenURI = _initialBaseURI;
        _contractURI = _initialContractURI;
        
        // Inizializza i tipi di fiori disponibili
        _addInitialFlowerTypes();
    }
    
    function _addInitialFlowerTypes() internal {
        string[10] memory defaultFlowers = [
            "rose",           // Rose rosse - amore eterno
            "poppy",          // Papaveri - memoria dei caduti
            "lily",           // Gigli - purezza dell'anima
            "sunflower",      // Girasoli - luce e speranza
            "violet",         // Violette - modestia e ricordo
            "daisy",          // Margherite - innocenza
            "forget_me_not",  // Non ti scordar di me
            "carnation",      // Garofani - amore profondo
            "iris",           // Iris - messaggio di valor
            "mixed_wildflowers" // Fiori di campo misti
        ];
        
        for (uint i = 0; i < defaultFlowers.length; i++) {
            availableFlowers[defaultFlowers[i]] = true;
            flowerTypes.push(defaultFlowers[i]);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌹 MAIN FUNCTIONS - PLANTING MEMORIALS
    // ═══════════════════════════════════════════════════════════════════════════════

    /**
     * @dev Pianta un memoriale - Il Piccolo Principe semina una stella
     * @param belovedName Nome della persona cara da ricordare
     * @param flowerType Tipo di fiore per l'aiuola
     * @param memoryMessage Messaggio di memoria
     * @param warConflict Guerra o conflitto di riferimento
     */
    function plantMemorial(
        string memory belovedName,
        string memory flowerType,
        string memory memoryMessage,
        string memory warConflict
    ) external payable nonReentrant returns (uint256) {
        require(msg.value >= mintPrice, "Insufficient payment for memorial");
        require(bytes(belovedName).length > 0, "Beloved name cannot be empty");
        require(availableFlowers[flowerType], "Flower type not available");
        require(bytes(memoryMessage).length > 0, "Memory message cannot be empty");
        
        uint256 tokenId = nextTokenId;
        
        // Mint dell'NFT
        _safeMint(msg.sender, tokenId);
        
        // Crea il memoriale
        memorialPlots[tokenId] = MemorialPlot({
            belovedName: belovedName,
            flowerType: flowerType,
            memoryMessage: memoryMessage,
            warConflict: warConflict,
            timestamp: block.timestamp,
            gardener: msg.sender,
            isActive: true
        });
        
        // Aggiorna le statistiche
        userMemorials[msg.sender].push(tokenId);
        totalMemorials++;
        nextTokenId++;
        totalSupply++;
        
        // Imposta l'URI del token (sarà costruito dinamicamente)
        string memory tokenURIString = string(abi.encodePacked(_baseTokenURI, _toString(tokenId), ".json"));
        _setTokenURI(tokenId, tokenURIString);
        
        emit MemorialPlanted(tokenId, msg.sender, belovedName, flowerType, memoryMessage);
        
        return tokenId;
    }

    // Funzione semplificata temporaneamente rimossa per risolvere errori di compilazione
    // Sarà aggiunta in un upgrade futuro

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌹 VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

    /**
     * @dev Ottieni i dettagli completi di un memoriale
     */
    function getMemorialDetails(uint256 tokenId) external view returns (
        string memory belovedName,
        string memory flowerType,
        string memory memoryMessage,
        string memory warConflict,
        uint256 timestamp,
        address gardener,
        bool isActive
    ) {
        require(ownerOf(tokenId) != address(0), "Memorial does not exist");
        
        MemorialPlot memory plot = memorialPlots[tokenId];
        return (
            plot.belovedName,
            plot.flowerType,
            plot.memoryMessage,
            plot.warConflict,
            plot.timestamp,
            plot.gardener,
            plot.isActive
        );
    }

    /**
     * @dev Ottieni tutti i memoriali di un utente
     */
    function getUserMemorials(address user) external view returns (uint256[] memory) {
        return userMemorials[user];
    }

    /**
     * @dev Ottieni tutti i tipi di fiori disponibili
     */
    function getAvailableFlowers() external view returns (string[] memory) {
        return flowerTypes;
    }

    /**
     * @dev Controlla se un tipo di fiore è disponibile
     */
    function isFlowerAvailable(string memory flowerType) external view returns (bool) {
        return availableFlowers[flowerType];
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌹 ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

    /**
     * @dev Aggiungi un nuovo tipo di fiore
     */
    function addFlowerType(string memory flowerType) external onlyOwner {
        require(!availableFlowers[flowerType], "Flower type already exists");
        
        availableFlowers[flowerType] = true;
        flowerTypes.push(flowerType);
        
        emit FlowerTypeAdded(flowerType);
    }

    /**
     * @dev Aggiorna il prezzo di mint
     */
    function updateMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
        emit PriceUpdated(newPrice);
    }

    /**
     * @dev Aggiorna il Base URI per i metadati IPFS
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }
    
    /**
     * @dev Aggiorna il Contract URI per i metadati della collezione
     */
    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractURI = newContractURI;
        emit ContractURIUpdated(newContractURI);
    }

    /**
     * @dev Preleva i fondi raccolti
     */
    function withdrawFunds() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
        
        emit FundsWithdrawn(owner(), balance);
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌹 OVERRIDE FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) 
        public 
        view 
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable) 
        returns (string memory) 
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
    
    // Helper function per convertire uint256 in string
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}