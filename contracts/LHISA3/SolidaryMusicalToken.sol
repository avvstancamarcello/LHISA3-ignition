// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca Lawyer - ITALY Florence

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title SolidaryMusicalToken (SOLMUS)
 * @author Avv. Marcello Stanca - Solidary Network Architect
 * @notice Token ecosystem per l'economia creativa e supporto agli artisti
 * @dev Token ERC-20 con funzionalità per royalty, streaming e supporto artistico
 * 
 * 🎵 SOLMUS - SOLIDARY MUSICAL TOKEN:
 * - Economia creativa decentralizzata su blockchain
 * - Supporto diretto agli artisti senza intermediari
 * - Sistema di royalty automatiche tramite smart contract
 * - Tokenizzazione dell'accesso a eventi culturali
 * - Streaming musicale con compenso equo agli artisti
 * 
 * 💰 TOKENOMICS:
 * - Initial Supply: 1,000,000 SOLMUS
 * - Allocation: 40% Artist Fund, 30% Public Sale, 20% Events, 10% Team
 * - Utility: Music streaming, artist support, event tickets, NFT creation
 */
contract SolidaryMusicalToken is ERC20, Ownable, ReentrancyGuard {
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎵 SOLMUS CONSTANTS & STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * (10 ** 18); // 1 milione di token
    uint256 public constant ARTIST_FUND_ALLOCATION = 400_000 * (10 ** 18); // 40%
    uint256 public constant PUBLIC_SALE_ALLOCATION = 300_000 * (10 ** 18); // 30%
    uint256 public constant EVENT_ORGANIZERS_ALLOCATION = 200_000 * (10 ** 18); // 20%
    uint256 public constant TEAM_ALLOCATION = 100_000 * (10 ** 18); // 10%
    
    // Artist and streaming management
    mapping(address => bool) public registeredArtists;
    mapping(address => uint256) public artistRoyalties;
    mapping(uint256 => address) public songArtists; // songId => artist
    mapping(uint256 => uint256) public songPrices; // songId => price in SOLMUS
    mapping(address => uint256) public streamingRewards;
    
    // Event and ticket management
    mapping(uint256 => EventInfo) public culturalEvents;
    mapping(address => bool) public eventOrganizers;
    uint256 public nextEventId = 1;
    
    struct EventInfo {
        string name;
        string description;
        uint256 ticketPrice; // in SOLMUS
        uint256 totalTickets;
        uint256 soldTickets;
        address organizer;
        bool active;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎵 EVENTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    event ArtistRegistered(address indexed artist);
    event ArtistSupported(address indexed supporter, address indexed artist, uint256 amount);
    event SongStreamed(address indexed listener, uint256 indexed songId, address indexed artist, uint256 reward);
    event RoyaltyDistributed(address indexed artist, uint256 amount);
    event EventCreated(uint256 indexed eventId, string name, address indexed organizer, uint256 ticketPrice);
    event TicketPurchased(uint256 indexed eventId, address indexed buyer, uint256 amount);
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎵 CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════════════════
    
        constructor(address initialOwner) ERC20("Solidary Musical Token", "SOLMUS") Ownable() {
        // Mint initial supply to owner for proper distribution
        _mint(initialOwner, INITIAL_SUPPLY);
        
        // Register owner as first event organizer
        eventOrganizers[initialOwner] = true;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎨 ARTIST MANAGEMENT FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Registra un artista nell'ecosistema SOLMUS
     */
    function registerArtist() external {
        registeredArtists[msg.sender] = true;
        emit ArtistRegistered(msg.sender);
    }
    
    /**
     * @notice Supporta direttamente un artista con token SOLMUS
     * @param artist Indirizzo dell'artista da supportare
     * @param amount Quantità di SOLMUS da donare
     */
    function supportArtist(address artist, uint256 amount) external nonReentrant {
        require(registeredArtists[artist], "Artist not registered");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        _transfer(msg.sender, artist, amount);
        emit ArtistSupported(msg.sender, artist, amount);
    }
    
    /**
     * @notice Crea una canzone NFT con prezzo di streaming
     * @param songId ID univoco della canzone
     * @param pricePerStream Prezzo in SOLMUS per ogni ascolto
     */
    function createSong(uint256 songId, uint256 pricePerStream) external {
        require(registeredArtists[msg.sender], "Must be registered artist");
        require(songArtists[songId] == address(0), "Song ID already exists");
        
        songArtists[songId] = msg.sender;
        songPrices[songId] = pricePerStream;
    }
    
    /**
     * @notice Ascolta una canzone pagando il token SOLMUS all'artista
     * @param songId ID della canzone da ascoltare
     */
    function streamSong(uint256 songId) external nonReentrant {
        address artist = songArtists[songId];
        uint256 price = songPrices[songId];
        
        require(artist != address(0), "Song does not exist");
        require(price > 0, "Song not available for streaming");
        require(balanceOf(msg.sender) >= price, "Insufficient balance for streaming");
        
        _transfer(msg.sender, artist, price);
        streamingRewards[artist] += price;
        
        emit SongStreamed(msg.sender, songId, artist, price);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎪 EVENT MANAGEMENT FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Registra un organizzatore di eventi
     * @param organizer Indirizzo dell'organizzatore
     */
    function registerEventOrganizer(address organizer) external onlyOwner {
        eventOrganizers[organizer] = true;
    }
    
    /**
     * @notice Crea un evento culturale
     * @param name Nome dell'evento
     * @param description Descrizione dell'evento
     * @param ticketPrice Prezzo del biglietto in SOLMUS
     * @param totalTickets Numero totale di biglietti disponibili
     */
    function createCulturalEvent(
        string memory name,
        string memory description,
        uint256 ticketPrice,
        uint256 totalTickets
    ) external returns (uint256) {
        require(eventOrganizers[msg.sender], "Not authorized event organizer");
        
        uint256 eventId = nextEventId++;
        culturalEvents[eventId] = EventInfo({
            name: name,
            description: description,
            ticketPrice: ticketPrice,
            totalTickets: totalTickets,
            soldTickets: 0,
            organizer: msg.sender,
            active: true
        });
        
        emit EventCreated(eventId, name, msg.sender, ticketPrice);
        return eventId;
    }
    
    /**
     * @notice Acquista biglietti per un evento culturale
     * @param eventId ID dell'evento
     * @param quantity Numero di biglietti da acquistare
     */
    function purchaseEventTicket(uint256 eventId, uint256 quantity) external nonReentrant {
        EventInfo storage eventInfo = culturalEvents[eventId];
        
        require(eventInfo.active, "Event not active");
        require(eventInfo.soldTickets + quantity <= eventInfo.totalTickets, "Not enough tickets available");
        
        uint256 totalCost = eventInfo.ticketPrice * quantity;
        require(balanceOf(msg.sender) >= totalCost, "Insufficient balance");
        
        _transfer(msg.sender, eventInfo.organizer, totalCost);
        eventInfo.soldTickets += quantity;
        
        emit TicketPurchased(eventId, msg.sender, quantity);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 💰 ROYALTY & REWARD FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Distribuisce royalty agli artisti dal fondo comune
     * @param artists Array di indirizzi artisti
     * @param amounts Array delle quantità da distribuire
     */
    function distributeRoyalties(address[] memory artists, uint256[] memory amounts) external onlyOwner {
        require(artists.length == amounts.length, "Arrays length mismatch");
        
        for (uint256 i = 0; i < artists.length; i++) {
            require(registeredArtists[artists[i]], "Artist not registered");
            _transfer(owner(), artists[i], amounts[i]);
            artistRoyalties[artists[i]] += amounts[i];
            emit RoyaltyDistributed(artists[i], amounts[i]);
        }
    }
    
    /**
     * @notice Ottiene le informazioni di streaming rewards per un artista
     * @param artist Indirizzo dell'artista
     */
    function getArtistStats(address artist) external view returns (
        bool isRegistered,
        uint256 totalRoyalties,
        uint256 streamingEarnings
    ) {
        return (
            registeredArtists[artist],
            artistRoyalties[artist],
            streamingRewards[artist]
        );
    }
    
    /**
     * @notice Ottiene informazioni di un evento
     * @param eventId ID dell'evento
     */
    function getEventInfo(uint256 eventId) external view returns (EventInfo memory) {
        return culturalEvents[eventId];
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔧 ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @notice Mint aggiuntivi per rewards e incentivi (solo owner)
     * @param to Destinatario dei token
     * @param amount Quantità da mintare
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    /**
     * @notice Burn token dal proprio balance
     * @param amount Quantità da bruciare
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
    
    /**
     * @notice Pausa/riprende un evento (solo organizzatore o owner)
     * @param eventId ID dell'evento
     * @param active Stato attivo/inattivo
     */
    function setEventActive(uint256 eventId, bool active) external {
        EventInfo storage eventInfo = culturalEvents[eventId];
        require(
            msg.sender == eventInfo.organizer || msg.sender == owner(),
            "Not authorized"
        );
        eventInfo.active = active;
    }
}