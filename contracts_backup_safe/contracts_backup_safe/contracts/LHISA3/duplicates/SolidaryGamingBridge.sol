// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca Lawyer - ITALY Florence
// Canto VII - Ponti tra Mondi Virtuali - Divina Commedia della Solidarietà Blockchain

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @title SolidaryGamingBridge
 * @dev Bridge avanzato per gaming cross-chain nell'ecosistema Solidary
 * @notice Connette gaming engines, metaversi e piattaforme di social gaming
 */
contract SolidaryGamingBridge is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎮 ROLES & CONSTANTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    bytes32 public constant GAME_OPERATOR = keccak256("GAME_OPERATOR");
    bytes32 public constant BRIDGE_VALIDATOR = keccak256("BRIDGE_VALIDATOR");
    bytes32 public constant ASSET_MANAGER = keccak256("ASSET_MANAGER");
    bytes32 public constant METAVERSE_CONNECTOR = keccak256("METAVERSE_CONNECTOR");
    bytes32 public constant ACHIEVEMENT_ORACLE = keccak256("ACHIEVEMENT_ORACLE");
    
    uint256 public constant MAX_BATCH_SIZE = 100;
    uint256 public constant BRIDGE_FEE_BASIS_POINTS = 100; // 1%
    uint256 public constant ACHIEVEMENT_COOLDOWN = 24 hours;
    uint256 public constant MAX_GAMING_REPUTATION = 10000;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎯 GAMING ECOSYSTEM STRUCTURES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    struct GamingProfile {
        address playerAddress;
        string playerId;                     // Cross-platform player ID
        uint256 totalGameTime;               // Total hours played
        uint256 gamesCompleted;              // Number of completed games
        uint256 achievementsUnlocked;        // Total achievements
        uint256 gamingReputation;            // Gaming-specific reputation (0-10000)
        uint256 socialImpactScore;           // Social impact through gaming
        uint256 lastActiveTimestamp;         // Last gaming activity
        mapping(string => GameStats) gameStats;        // Per-game statistics
        mapping(uint256 => Achievement) achievements;   // Player achievements
        mapping(string => MetaverseAsset) assets;      // Cross-platform assets
        bool isVerifiedPlayer;
        bool isGameDeveloper;
        bool isContentCreator;
        PlayerTier tier;                     // Player tier level
    }
    
    enum PlayerTier {
        ROOKIE,         // 0-1000: New player
        APPRENTICE,     // 1001-3000: Learning player  
        ADVENTURER,     // 3001-5000: Regular player
        CHAMPION,       // 5001-7000: Skilled player
        LEGEND,         // 7001-9000: Expert player
        GRANDMASTER     // 9001-10000: Master player
    }
    
    struct GameStats {
        string gameId;
        string platform;                     // Unity, Unreal, Web3, etc.
        uint256 hoursPlayed;
        uint256 level;
        uint256 experience;
        uint256 wins;
        uint256 losses;
        uint256 collaborativeActions;        // Helping other players
        uint256 socialImpactActions;         // Actions with positive social impact
        uint256 lastPlayedTimestamp;
        bool isCompleted;
        GameGenre genre;
    }
    
    enum GameGenre {
        EDUCATION,          // Educational games
        SOCIAL_IMPACT,      // Games focused on social change
        COLLABORATIVE,      // Cooperative multiplayer games
        STRATEGY,          // Strategy and puzzle games
        SIMULATION,        // Life and city simulation
        ADVENTURE,         // Story-driven adventures
        CREATIVE,          // Creative and building games
        HEALTH_WELLNESS,   // Health and fitness games
        OTHER
    }
    
    struct Achievement {
        uint256 achievementId;
        string name;
        string description;
        string gameId;
        AchievementType achievementType;
        uint256 reputationPoints;           // Points awarded
        uint256 socialImpactPoints;         // Social impact points
        uint256 unlockedTimestamp;
        bool isVerified;                    // Verified by oracle
        bool isCrossChain;                  // Available across chains
        string evidenceURI;                 // Evidence/proof URI
    }
    
    enum AchievementType {
        SKILL_MASTERY,      // Game skill achievements
        SOCIAL_IMPACT,      // Positive social impact
        COLLABORATION,      // Helping other players
        INNOVATION,         // Creative problem solving
        LEADERSHIP,         // Community leadership
        EDUCATION,          // Learning achievements
        WELLNESS,           // Health and wellness
        ENVIRONMENTAL,      // Environmental consciousness
        CULTURAL,           // Cultural preservation
        CHARITABLE          // Charitable actions
    }
    
    struct MetaverseAsset {
        string assetId;
        string name;
        AssetType assetType;
        string originPlatform;              // Original platform/metaverse
        address tokenAddress;               // ERC721/ERC1155 address
        uint256 tokenId;                    // Token ID
        uint256 rarity;                     // Rarity score (0-10000)
        uint256 socialValue;                // Social/cultural value
        bool isTransferable;                // Can be transferred
        bool isBridgeable;                  // Can be bridged cross-chain
        mapping(string => string) attributes;  // Dynamic attributes
        string metadataURI;
    }
    
    enum AssetType {
        AVATAR,             // Avatar and character assets
        WEARABLE,          // Clothing and accessories
        EQUIPMENT,         // Tools and weapons
        PROPERTY,          // Virtual real estate
        VEHICLE,           // Transportation
        PET_COMPANION,     // Pets and companions
        ARTWORK,           // Digital art pieces
        COLLECTIBLE,       // Rare collectibles
        UTILITY_ITEM,      // Utility and functional items
        SOCIAL_BADGE       // Social achievement badges
    }
    
    struct GamingPlatform {
        string platformId;
        string name;
        string endpoint;                    // API endpoint
        PlatformType platformType;
        bool isActive;
        bool supportsNFTs;
        bool supportsCrossChain;
        address bridgeContract;             // Platform-specific bridge
        mapping(string => bool) supportedGameGenres;
        uint256 totalPlayers;
        uint256 totalGames;
    }
    
    enum PlatformType {
        WEB3_NATIVE,        // Blockchain-native platform
        UNITY_ENGINE,       // Unity-based games
        UNREAL_ENGINE,      // Unreal Engine games  
        WEB_BROWSER,        // Browser-based games
        MOBILE_APP,         // Mobile applications
        VR_PLATFORM,        // VR/AR platforms
        METAVERSE,          // Metaverse platforms
        SOCIAL_PLATFORM,    // Social gaming platforms
        EDUCATIONAL,        // Educational platforms
        CUSTOM_ENGINE       // Custom game engines
    }
    
    struct SocialGamingEvent {
        uint256 eventId;
        string name;
        string description;
        EventType eventType;
        uint256 startTime;
        uint256 endTime;
        uint256 maxParticipants;
        uint256 currentParticipants;
        uint256 rewardPool;                 // Total rewards available
        address[] participants;
        mapping(address => uint256) participantScores;
        mapping(address => uint256) participantRewards;
        bool isActive;
        bool isCompleted;
        string gameId;
        SocialImpactGoal impactGoal;
    }
    
    enum EventType {
        COLLABORATIVE_CHALLENGE,    // Team-based challenges
        EDUCATIONAL_TOURNAMENT,     // Learning competitions
        CHARITY_FUNDRAISER,        // Charity gaming events
        SOCIAL_AWARENESS,          // Social cause awareness
        COMMUNITY_BUILDING,        // Community engagement
        SKILL_DEVELOPMENT,         // Skill building events
        CULTURAL_EXCHANGE,         // Cultural sharing events
        ENVIRONMENTAL_ACTION,      // Environmental initiatives
        HEALTH_WELLNESS,           // Health promotion events
        INNOVATION_HACKATHON       // Creative problem solving
    }
    
    struct SocialImpactGoal {
        string description;
        uint256 targetAmount;               // Target to reach (donations, actions, etc.)
        uint256 currentAmount;              // Current progress
        string beneficiary;                 // Who benefits from this goal
        bool isCompleted;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 💾 STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    mapping(address => GamingProfile) public gamingProfiles;
    mapping(string => GamingPlatform) public platforms;
    mapping(uint256 => SocialGamingEvent) public gamingEvents;
    mapping(address => uint256[]) public playerEvents;
    mapping(string => address[]) public gameLeaderboards;
    mapping(PlayerTier => uint256) public tierCounts;
    
    uint256 public currentEventId;
    uint256 public totalPlayers;
    uint256 public totalAchievements;
    uint256 public totalSocialImpact;
    uint256 public totalGamingHours;
    
    string[] public registeredPlatforms;
    string[] public featuredGames;
    
    // Cross-chain bridge mappings
    mapping(bytes32 => bool) public processedTransactions;
    mapping(string => mapping(address => bool)) public platformPlayerVerification;
    
    // Contract references
    address public solidaryHub;
    address public reputationManager;
    address public trustManager;
    address public impactLogger;
    address public solidaryToken;
    address public nftManager;
    
    // Bridge settings
    uint256 public bridgeFee;
    uint256 public minBridgeAmount;
    bool public bridgeActive;
    bool public crossChainEnabled;
    bool public socialEventsEnabled;
    
    // Events
    event PlayerRegistered(address indexed player, string playerId, PlayerTier tier);
    event GameStatsUpdated(address indexed player, string gameId, uint256 hoursPlayed, uint256 level);
    event AchievementUnlocked(address indexed player, uint256 achievementId, uint256 reputationPoints);
    event AssetBridged(address indexed player, string assetId, string fromPlatform, string toPlatform);
    event SocialEventCreated(uint256 indexed eventId, string name, EventType eventType);
    event SocialEventCompleted(uint256 indexed eventId, uint256 totalParticipants, uint256 socialImpact);
    event PlatformRegistered(string platformId, string name, PlatformType platformType);
    event CrossChainGameAction(address indexed player, string gameId, bytes32 actionHash);
    event GamingReputationUpdated(address indexed player, uint256 oldReputation, uint256 newReputation);
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🏗️ INITIALIZATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        address admin,
        address _solidaryHub,
        address _reputationManager,
        address _trustManager,
        address _impactLogger,
        address _solidaryToken,
        address _nftManager
    ) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(GAME_OPERATOR, admin);
        _grantRole(BRIDGE_VALIDATOR, admin);
        _grantRole(ASSET_MANAGER, admin);
        _grantRole(METAVERSE_CONNECTOR, admin);
        _grantRole(ACHIEVEMENT_ORACLE, admin);
        
        solidaryHub = _solidaryHub;
        reputationManager = _reputationManager;
        trustManager = _trustManager;
        impactLogger = _impactLogger;
        solidaryToken = _solidaryToken;
        nftManager = _nftManager;
        
        currentEventId = 1;
        bridgeFee = BRIDGE_FEE_BASIS_POINTS;
        minBridgeAmount = 1e18; // 1 token minimum
        bridgeActive = true;
        crossChainEnabled = true;
        socialEventsEnabled = true;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎮 PLAYER MANAGEMENT
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Registra un nuovo giocatore nell'ecosistema gaming
     * @param playerId ID giocatore cross-platform
     * @param isGameDev Se il player è anche sviluppatore
     * @param isCreator Se il player è content creator
     */
    function registerPlayer(
        string memory playerId,
        bool isGameDev,
        bool isCreator
    ) external {
        require(bytes(playerId).length > 0, "Player ID cannot be empty");
        require(gamingProfiles[msg.sender].playerAddress == address(0), "Player already registered");
        
        GamingProfile storage profile = gamingProfiles[msg.sender];
        profile.playerAddress = msg.sender;
        profile.playerId = playerId;
        profile.isGameDeveloper = isGameDev;
        profile.isContentCreator = isCreator;
        profile.tier = PlayerTier.ROOKIE;
        profile.lastActiveTimestamp = block.timestamp;
        profile.gamingReputation = 500; // Starting reputation
        
        tierCounts[PlayerTier.ROOKIE]++;
        totalPlayers++;
        
        emit PlayerRegistered(msg.sender, playerId, PlayerTier.ROOKIE);
    }
    
    /**
     * @dev Aggiorna le statistiche di gioco di un player
     * @param player Indirizzo del giocatore
     * @param gameId ID del gioco
     * @param platform Piattaforma di gioco
     * @param hoursPlayed Ore giocate in questa sessione
     * @param newLevel Nuovo livello raggiunto
     * @param experience Esperienza guadagnata
     * @param collaborativeActions Azioni collaborative eseguite
     * @param socialImpactActions Azioni di impatto sociale
     * @param genre Genere del gioco
     */
    function updateGameStats(
        address player,
        string memory gameId,
        string memory platform,
        uint256 hoursPlayed,
        uint256 newLevel,
        uint256 experience,
        uint256 collaborativeActions,
        uint256 socialImpactActions,
        GameGenre genre
    ) external onlyRole(GAME_OPERATOR) {
        require(gamingProfiles[player].playerAddress != address(0), "Player not registered");
        
        GamingProfile storage profile = gamingProfiles[player];
        GameStats storage stats = profile.gameStats[gameId];
        
        // Update game-specific stats
        stats.gameId = gameId;
        stats.platform = platform;
        stats.hoursPlayed += hoursPlayed;
        stats.level = newLevel;
        stats.experience += experience;
        stats.collaborativeActions += collaborativeActions;
        stats.socialImpactActions += socialImpactActions;
        stats.lastPlayedTimestamp = block.timestamp;
        stats.genre = genre;
        
        // Update overall profile
        profile.totalGameTime += hoursPlayed;
        profile.lastActiveTimestamp = block.timestamp;
        
        // Update global stats
        totalGamingHours += hoursPlayed;
        totalSocialImpact += socialImpactActions;
        
        // Calculate reputation increase
        uint256 reputationGain = _calculateReputationGain(
            hoursPlayed, 
            collaborativeActions, 
            socialImpactActions,
            genre
        );
        
        _updateGamingReputation(player, reputationGain);
        
        emit GameStatsUpdated(player, gameId, hoursPlayed, newLevel);
    }
    
    /**
     * @dev Sblocca un achievement per un giocatore
     * @param player Indirizzo del giocatore
     * @param name Nome dell'achievement
     * @param description Descrizione
     * @param gameId ID del gioco
     * @param achievementType Tipo di achievement
     * @param reputationPoints Punti reputazione assegnati
     * @param socialImpactPoints Punti impatto sociale
     * @param evidenceURI URI dell'evidenza
     */
    function unlockAchievement(
        address player,
        string memory name,
        string memory description,
        string memory gameId,
        AchievementType achievementType,
        uint256 reputationPoints,
        uint256 socialImpactPoints,
        string memory evidenceURI
    ) external onlyRole(ACHIEVEMENT_ORACLE) returns (uint256) {
        require(gamingProfiles[player].playerAddress != address(0), "Player not registered");
        
        uint256 achievementId = totalAchievements + 1;
        GamingProfile storage profile = gamingProfiles[player];
        
        Achievement storage achievement = profile.achievements[achievementId];
        achievement.achievementId = achievementId;
        achievement.name = name;
        achievement.description = description;
        achievement.gameId = gameId;
        achievement.achievementType = achievementType;
        achievement.reputationPoints = reputationPoints;
        achievement.socialImpactPoints = socialImpactPoints;
        achievement.unlockedTimestamp = block.timestamp;
        achievement.evidenceURI = evidenceURI;
        achievement.isVerified = true;
        achievement.isCrossChain = true;
        
        profile.achievementsUnlocked++;
        totalAchievements++;
        
        // Update reputation
        _updateGamingReputation(player, reputationPoints);
        
        // Log social impact
        if (socialImpactPoints > 0) {
            _logSocialImpact(player, gameId, socialImpactPoints, achievementType);
        }
        
        emit AchievementUnlocked(player, achievementId, reputationPoints);
        return achievementId;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌉 CROSS-CHAIN ASSET BRIDGE
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Bridging di asset NFT cross-chain
     * @param assetId ID dell'asset
     * @param fromPlatform Piattaforma di origine
     * @param toPlatform Piattaforma destinazione
     * @param tokenAddress Indirizzo del contratto NFT
     * @param tokenId ID del token
     * @param destinationAddress Indirizzo destinazione
     */
    function bridgeAsset(
        string memory assetId,
        string memory fromPlatform,
        string memory toPlatform,
        address tokenAddress,
        uint256 tokenId,
        address destinationAddress
    ) external payable nonReentrant {
        require(bridgeActive, "Bridge not active");
        require(msg.value >= bridgeFee, "Insufficient bridge fee");
        require(destinationAddress != address(0), "Invalid destination");
        
        GamingProfile storage profile = gamingProfiles[msg.sender];
        require(profile.playerAddress != address(0), "Player not registered");
        
        MetaverseAsset storage asset = profile.assets[assetId];
        require(asset.isBridgeable, "Asset not bridgeable");
        
        // Verify NFT ownership
        IERC721Upgradeable nft = IERC721Upgradeable(tokenAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not NFT owner");
        
        // Create bridge transaction hash
        bytes32 txHash = keccak256(abi.encodePacked(
            msg.sender,
            assetId,
            fromPlatform,
            toPlatform,
            tokenId,
            block.timestamp
        ));
        
        require(!processedTransactions[txHash], "Transaction already processed");
        processedTransactions[txHash] = true;
        
        // Update asset platform
        asset.originPlatform = toPlatform;
        
        emit AssetBridged(msg.sender, assetId, fromPlatform, toPlatform);
        emit CrossChainGameAction(msg.sender, "", txHash);
    }
    
    /**
     * @dev Registra un asset nel metaverso
     * @param assetId ID univoco dell'asset
     * @param name Nome dell'asset
     * @param assetType Tipo di asset
     * @param platform Piattaforma di origine
     * @param tokenAddress Indirizzo contratto token
     * @param tokenId ID del token
     * @param rarity Livello di rarità
     * @param socialValue Valore sociale/culturale
     * @param isTransferable Se può essere trasferito
     * @param isBridgeable Se può essere bridged
     * @param metadataURI URI metadata
     */
    function registerMetaverseAsset(
        string memory assetId,
        string memory name,
        AssetType assetType,
        string memory platform,
        address tokenAddress,
        uint256 tokenId,
        uint256 rarity,
        uint256 socialValue,
        bool isTransferable,
        bool isBridgeable,
        string memory metadataURI
    ) external onlyRole(ASSET_MANAGER) {
        GamingProfile storage profile = gamingProfiles[msg.sender];
        
        MetaverseAsset storage asset = profile.assets[assetId];
        asset.assetId = assetId;
        asset.name = name;
        asset.assetType = assetType;
        asset.originPlatform = platform;
        asset.tokenAddress = tokenAddress;
        asset.tokenId = tokenId;
        asset.rarity = rarity;
        asset.socialValue = socialValue;
        asset.isTransferable = isTransferable;
        asset.isBridgeable = isBridgeable;
        asset.metadataURI = metadataURI;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎪 SOCIAL GAMING EVENTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Crea un evento di social gaming
     * @param name Nome dell'evento
     * @param description Descrizione
     * @param eventType Tipo di evento
     * @param startTime Timestamp inizio
     * @param duration Durata in secondi
     * @param maxParticipants Numero massimo partecipanti
     * @param rewardPool Pool di ricompense
     * @param gameId ID del gioco (opzionale)
     * @param impactGoalDescription Descrizione obiettivo impatto sociale
     * @param impactTargetAmount Target da raggiungere
     * @param beneficiary Chi beneficia dell'evento
     */
    function createSocialGamingEvent(
        string memory name,
        string memory description,
        EventType eventType,
        uint256 startTime,
        uint256 duration,
        uint256 maxParticipants,
        uint256 rewardPool,
        string memory gameId,
        string memory impactGoalDescription,
        uint256 impactTargetAmount,
        string memory beneficiary
    ) external onlyRole(GAME_OPERATOR) returns (uint256) {
        require(socialEventsEnabled, "Social events not enabled");
        require(startTime > block.timestamp, "Start time must be in future");
        require(maxParticipants > 0, "Must allow participants");
        
        uint256 eventId = currentEventId++;
        SocialGamingEvent storage gameEvent = gamingEvents[eventId];
        
        gameEvent.eventId = eventId;
        gameEvent.name = name;
        gameEvent.description = description;
        gameEvent.eventType = eventType;
        gameEvent.startTime = startTime;
        gameEvent.endTime = startTime + duration;
        gameEvent.maxParticipants = maxParticipants;
        gameEvent.rewardPool = rewardPool;
        gameEvent.isActive = true;
        gameEvent.gameId = gameId;
        
        // Set social impact goal
        gameEvent.impactGoal.description = impactGoalDescription;
        gameEvent.impactGoal.targetAmount = impactTargetAmount;
        gameEvent.impactGoal.beneficiary = beneficiary;
        
        emit SocialEventCreated(eventId, name, eventType);
        return eventId;
    }
    
    /**
     * @dev Partecipa a un evento social gaming
     * @param eventId ID dell'evento
     */
    function joinSocialEvent(uint256 eventId) external {
        SocialGamingEvent storage gameEvent = gamingEvents[eventId];
        require(gameEvent.isActive, "Event not active");
        require(block.timestamp >= gameEvent.startTime, "Event not started");
        require(block.timestamp <= gameEvent.endTime, "Event ended");
        require(gameEvent.currentParticipants < gameEvent.maxParticipants, "Event full");
        require(gamingProfiles[msg.sender].playerAddress != address(0), "Player not registered");
        
        // Check if already participating
        for (uint256 i = 0; i < gameEvent.participants.length; i++) {
            require(gameEvent.participants[i] != msg.sender, "Already participating");
        }
        
        gameEvent.participants.push(msg.sender);
        gameEvent.currentParticipants++;
        playerEvents[msg.sender].push(eventId);
        
        // Initialize participant score
        gameEvent.participantScores[msg.sender] = 0;
    }
    
    /**
     * @dev Aggiorna il punteggio di un partecipante
     * @param eventId ID dell'evento
     * @param participant Partecipante
     * @param score Punteggio da aggiungere
     * @param impactContribution Contributo all'impatto sociale
     */
    function updateParticipantScore(
        uint256 eventId,
        address participant,
        uint256 score,
        uint256 impactContribution
    ) external onlyRole(GAME_OPERATOR) {
        SocialGamingEvent storage gameEvent = gamingEvents[eventId];
        require(gameEvent.isActive, "Event not active");
        require(gameEvent.participantScores[participant] > 0 || _isParticipant(eventId, participant), "Not a participant");
        
        gameEvent.participantScores[participant] += score;
        gameEvent.impactGoal.currentAmount += impactContribution;
        
        // Update player reputation based on contribution
        _updateGamingReputation(participant, score / 10);
    }
    
    /**
     * @dev Completa un evento e distribuisce le ricompense
     * @param eventId ID dell'evento
     */
    function completeSocialEvent(uint256 eventId) external onlyRole(GAME_OPERATOR) {
        SocialGamingEvent storage gameEvent = gamingEvents[eventId];
        require(gameEvent.isActive, "Event not active");
        require(block.timestamp > gameEvent.endTime, "Event not ended");
        
        gameEvent.isActive = false;
        gameEvent.isCompleted = true;
        
        // Check if social impact goal was reached
        if (gameEvent.impactGoal.currentAmount >= gameEvent.impactGoal.targetAmount) {
            gameEvent.impactGoal.isCompleted = true;
        }
        
        // Distribute rewards based on scores
        _distributeEventRewards(eventId);
        
        emit SocialEventCompleted(
            eventId, 
            gameEvent.currentParticipants, 
            gameEvent.impactGoal.currentAmount
        );
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎯 PLATFORM INTEGRATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    /**
     * @dev Registra una nuova piattaforma gaming
     * @param platformId ID univoco piattaforma
     * @param name Nome piattaforma
     * @param endpoint Endpoint API
     * @param platformType Tipo di piattaforma
     * @param supportsNFTs Se supporta NFT
     * @param supportsCrossChain Se supporta cross-chain
     * @param bridgeContract Contratto bridge dedicato
     */
    function registerGamingPlatform(
        string memory platformId,
        string memory name,
        string memory endpoint,
        PlatformType platformType,
        bool supportsNFTs,
        bool supportsCrossChain,
        address bridgeContract
    ) external onlyRole(METAVERSE_CONNECTOR) {
        require(bytes(platformId).length > 0, "Platform ID cannot be empty");
        require(platforms[platformId].isActive == false, "Platform already registered");
        
        GamingPlatform storage platform = platforms[platformId];
        platform.platformId = platformId;
        platform.name = name;
        platform.endpoint = endpoint;
        platform.platformType = platformType;
        platform.isActive = true;
        platform.supportsNFTs = supportsNFTs;
        platform.supportsCrossChain = supportsCrossChain;
        platform.bridgeContract = bridgeContract;
        
        registeredPlatforms.push(platformId);
        
        emit PlatformRegistered(platformId, name, platformType);
    }
    
    /**
     * @dev Verifica un giocatore su una specifica piattaforma
     * @param platformId ID piattaforma
     * @param player Indirizzo giocatore
     * @param verified Stato di verifica
     */
    function verifyPlayerOnPlatform(
        string memory platformId,
        address player,
        bool verified
    ) external onlyRole(BRIDGE_VALIDATOR) {
        require(platforms[platformId].isActive, "Platform not active");
        require(gamingProfiles[player].playerAddress != address(0), "Player not registered");
        
        platformPlayerVerification[platformId][player] = verified;
        
        if (verified) {
            gamingProfiles[player].isVerifiedPlayer = true;
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔧 INTERNAL UTILITY FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function _calculateReputationGain(
        uint256 hoursPlayed,
        uint256 collaborativeActions,
        uint256 socialImpactActions,
        GameGenre genre
    ) internal pure returns (uint256) {
        uint256 baseGain = hoursPlayed; // 1 point per hour
        uint256 collaborativeBonus = collaborativeActions * 5; // 5 points per collaborative action
        uint256 socialBonus = socialImpactActions * 10; // 10 points per social impact action
        
        // Genre multipliers
        uint256 genreMultiplier = 100; // Default 1x
        if (genre == GameGenre.EDUCATION) genreMultiplier = 150; // 1.5x
        else if (genre == GameGenre.SOCIAL_IMPACT) genreMultiplier = 200; // 2x
        else if (genre == GameGenre.COLLABORATIVE) genreMultiplier = 130; // 1.3x
        else if (genre == GameGenre.HEALTH_WELLNESS) genreMultiplier = 120; // 1.2x
        
        uint256 totalGain = (baseGain + collaborativeBonus + socialBonus) * genreMultiplier / 100;
        
        return totalGain > 1000 ? 1000 : totalGain; // Cap at 1000 points per session
    }
    
    function _updateGamingReputation(address player, uint256 reputationGain) internal {
        GamingProfile storage profile = gamingProfiles[player];
        uint256 oldReputation = profile.gamingReputation;
        
        profile.gamingReputation += reputationGain;
        if (profile.gamingReputation > MAX_GAMING_REPUTATION) {
            profile.gamingReputation = MAX_GAMING_REPUTATION;
        }
        
        // Update player tier
        PlayerTier oldTier = profile.tier;
        PlayerTier newTier = _calculatePlayerTier(profile.gamingReputation);
        
        if (newTier != oldTier) {
            tierCounts[oldTier]--;
            tierCounts[newTier]++;
            profile.tier = newTier;
        }
        
        emit GamingReputationUpdated(player, oldReputation, profile.gamingReputation);
        
        // Sync with main reputation system
        _syncWithMainReputation(player, profile.gamingReputation);
    }
    
    function _calculatePlayerTier(uint256 reputation) internal pure returns (PlayerTier) {
        if (reputation <= 1000) return PlayerTier.ROOKIE;
        else if (reputation <= 3000) return PlayerTier.APPRENTICE;
        else if (reputation <= 5000) return PlayerTier.ADVENTURER;
        else if (reputation <= 7000) return PlayerTier.CHAMPION;
        else if (reputation <= 9000) return PlayerTier.LEGEND;
        else return PlayerTier.GRANDMASTER;
    }
    
    function _logSocialImpact(
        address player,
        string memory gameId,
        uint256 impactPoints,
        AchievementType achievementType
    ) internal {
        // Log to ImpactLogger if available
        if (impactLogger != address(0)) {
            (bool success, ) = impactLogger.call(
                abi.encodeWithSignature(
                    "logGamingImpact(address,string,uint256,uint8)",
                    player,
                    gameId,
                    impactPoints,
                    uint8(achievementType)
                )
            );
        }
    }
    
    function _syncWithMainReputation(address player, uint256 gamingReputation) internal {
        // Sync with ReputationManager
        if (reputationManager != address(0)) {
            (bool success, ) = reputationManager.call(
                abi.encodeWithSignature(
                    "updateGamingContribution(address,uint256)",
                    player,
                    gamingReputation
                )
            );
        }
        
        // Update trust score
        if (trustManager != address(0) && gamingReputation >= 5000) {
            (bool success, ) = trustManager.call(
                abi.encodeWithSignature(
                    "updateTrustScore(address)",
                    player
                )
            );
        }
    }
    
    function _isParticipant(uint256 eventId, address participant) internal view returns (bool) {
        SocialGamingEvent storage gameEvent = gamingEvents[eventId];
        for (uint256 i = 0; i < gameEvent.participants.length; i++) {
            if (gameEvent.participants[i] == participant) {
                return true;
            }
        }
        return false;
    }
    
    function _distributeEventRewards(uint256 eventId) internal {
        SocialGamingEvent storage gameEvent = gamingEvents[eventId];
        
        if (gameEvent.rewardPool == 0 || gameEvent.currentParticipants == 0) {
            return;
        }
        
        // Find top performers
        address[] memory sortedParticipants = _sortParticipantsByScore(eventId);
        
        // Distribute rewards (top 20% get most rewards)
        uint256 topPerformers = gameEvent.currentParticipants / 5; // Top 20%
        if (topPerformers == 0) topPerformers = 1;
        
        uint256 topReward = (gameEvent.rewardPool * 60) / 100; // 60% for top performers
        uint256 participationReward = (gameEvent.rewardPool * 40) / 100; // 40% for all participants
        
        // Distribute to top performers
        for (uint256 i = 0; i < topPerformers && i < sortedParticipants.length; i++) {
            uint256 reward = topReward / topPerformers;
            gameEvent.participantRewards[sortedParticipants[i]] = reward;
            
            // Transfer reward tokens
            if (solidaryToken != address(0)) {
                IERC20Upgradeable(solidaryToken).transfer(sortedParticipants[i], reward);
            }
        }
        
        // Distribute participation rewards
        uint256 baseParticipationReward = participationReward / gameEvent.currentParticipants;
        for (uint256 i = 0; i < gameEvent.participants.length; i++) {
            address participant = gameEvent.participants[i];
            if (gameEvent.participantRewards[participant] == 0) { // Not a top performer
                gameEvent.participantRewards[participant] = baseParticipationReward;
                
                if (solidaryToken != address(0)) {
                    IERC20Upgradeable(solidaryToken).transfer(participant, baseParticipationReward);
                }
            }
        }
    }
    
    function _sortParticipantsByScore(uint256 eventId) internal view returns (address[] memory) {
        SocialGamingEvent storage gameEvent = gamingEvents[eventId];
        address[] memory participants = new address[](gameEvent.participants.length);
        
        // Copy participants array
        for (uint256 i = 0; i < gameEvent.participants.length; i++) {
            participants[i] = gameEvent.participants[i];
        }
        
        // Simple bubble sort by score (descending)
        for (uint256 i = 0; i < participants.length - 1; i++) {
            for (uint256 j = 0; j < participants.length - i - 1; j++) {
                if (gameEvent.participantScores[participants[j]] < gameEvent.participantScores[participants[j + 1]]) {
                    address temp = participants[j];
                    participants[j] = participants[j + 1];
                    participants[j + 1] = temp;
                }
            }
        }
        
        return participants;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 👁️ VIEW FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function getGamingProfile(address player) external view returns (
        string memory playerId,
        uint256 totalGameTime,
        uint256 gamesCompleted,
        uint256 achievementsUnlocked,
        uint256 gamingReputation,
        uint256 socialImpactScore,
        bool isVerifiedPlayer,
        bool isGameDeveloper,
        bool isContentCreator,
        PlayerTier tier
    ) {
        GamingProfile storage profile = gamingProfiles[player];
        return (
            profile.playerId,
            profile.totalGameTime,
            profile.gamesCompleted,
            profile.achievementsUnlocked,
            profile.gamingReputation,
            profile.socialImpactScore,
            profile.isVerifiedPlayer,
            profile.isGameDeveloper,
            profile.isContentCreator,
            profile.tier
        );
    }
    
    function getGameStats(address player, string memory gameId) external view returns (GameStats memory) {
        return gamingProfiles[player].gameStats[gameId];
    }
    
    function getPlayerAchievement(address player, uint256 achievementId) external view returns (Achievement memory) {
        return gamingProfiles[player].achievements[achievementId];
    }
    
    function getMetaverseAsset(address player, string memory assetId) external view returns (
        string memory name,
        AssetType assetType,
        string memory originPlatform,
        uint256 rarity,
        uint256 socialValue,
        bool isTransferable,
        bool isBridgeable,
        string memory metadataURI
    ) {
        MetaverseAsset storage asset = gamingProfiles[player].assets[assetId];
        return (
            asset.name,
            asset.assetType,
            asset.originPlatform,
            asset.rarity,
            asset.socialValue,
            asset.isTransferable,
            asset.isBridgeable,
            asset.metadataURI
        );
    }
    
    function getSocialGamingEvent(uint256 eventId) external view returns (
        string memory name,
        EventType eventType,
        uint256 startTime,
        uint256 endTime,
        uint256 currentParticipants,
        uint256 maxParticipants,
        uint256 rewardPool,
        bool isActive,
        bool isCompleted
    ) {
        SocialGamingEvent storage gameEvent = gamingEvents[eventId];
        return (
            gameEvent.name,
            gameEvent.eventType,
            gameEvent.startTime,
            gameEvent.endTime,
            gameEvent.currentParticipants,
            gameEvent.maxParticipants,
            gameEvent.rewardPool,
            gameEvent.isActive,
            gameEvent.isCompleted
        );
    }
    
    function getGamingPlatform(string memory platformId) external view returns (
        string memory name,
        string memory endpoint,
        PlatformType platformType,
        bool isActive,
        bool supportsNFTs,
        bool supportsCrossChain,
        address bridgeContract,
        uint256 totalPlayers,
        uint256 totalGames
    ) {
        GamingPlatform storage platform = platforms[platformId];
        return (
            platform.name,
            platform.endpoint,
            platform.platformType,
            platform.isActive,
            platform.supportsNFTs,
            platform.supportsCrossChain,
            platform.bridgeContract,
            platform.totalPlayers,
            platform.totalGames
        );
    }
    
    function getPlayerEvents(address player) external view returns (uint256[] memory) {
        return playerEvents[player];
    }
    
    function getRegisteredPlatforms() external view returns (string[] memory) {
        return registeredPlatforms;
    }
    
    function getSystemStats() external view returns (
        uint256 players,
        uint256 achievements,
        uint256 socialImpact,
        uint256 gamingHours,
        uint256 activeEvents
    ) {
        uint256 activeEventCount = 0;
        for (uint256 i = 1; i < currentEventId; i++) {
            if (gamingEvents[i].isActive) activeEventCount++;
        }
        
        return (totalPlayers, totalAchievements, totalSocialImpact, totalGamingHours, activeEventCount);
    }
    
    function getTierDistribution() external view returns (uint256[6] memory) {
        return [
            tierCounts[PlayerTier.ROOKIE],
            tierCounts[PlayerTier.APPRENTICE],
            tierCounts[PlayerTier.ADVENTURER],
            tierCounts[PlayerTier.CHAMPION],
            tierCounts[PlayerTier.LEGEND],
            tierCounts[PlayerTier.GRANDMASTER]
        ];
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // ⚙️ ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function setBridgeSettings(
        uint256 _bridgeFee,
        uint256 _minBridgeAmount,
        bool _bridgeActive,
        bool _crossChainEnabled
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bridgeFee = _bridgeFee;
        minBridgeAmount = _minBridgeAmount;
        bridgeActive = _bridgeActive;
        crossChainEnabled = _crossChainEnabled;
    }
    
    function setSystemSettings(
        bool _socialEventsEnabled
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        socialEventsEnabled = _socialEventsEnabled;
    }
    
    function updateContractReferences(
        address _solidaryHub,
        address _reputationManager,
        address _trustManager,
        address _impactLogger,
        address _solidaryToken,
        address _nftManager
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_solidaryHub != address(0)) solidaryHub = _solidaryHub;
        if (_reputationManager != address(0)) reputationManager = _reputationManager;
        if (_trustManager != address(0)) trustManager = _trustManager;
        if (_impactLogger != address(0)) impactLogger = _impactLogger;
        if (_solidaryToken != address(0)) solidaryToken = _solidaryToken;
        if (_nftManager != address(0)) nftManager = _nftManager;
    }
    
    function addFeaturedGame(string memory gameId) external onlyRole(GAME_OPERATOR) {
        featuredGames.push(gameId);
    }
    
    function withdrawBridgeFees() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Fee withdrawal failed");
    }
    
    // Required for receiving ETH bridge fees
    receive() external payable {}
}