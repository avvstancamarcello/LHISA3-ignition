// SPDX-License-Identifier: UNLICENSED
    pragma solidity ^0.8.29;

// Copyright © 2025 Avv. Marcello Stanca - Firenze, Italia. All Rights Reserved.
// Hoc contractum, pars Solidary Solar System, ab Auctore Marcello Stanca 
// ad solam Caritas Internationalis (MCMLXXVI) usum conceditur.
//
// This smart contract, part of the Solidary Solar System,
// is conceived by the author as a system of ethical finance with automatic balancing,
// with native anti-speculation stabilization.
//
// Questo contratto intelligente, parte del Solidary Solar System,
// è ideato dall'autore come sistema di finanza etica a bilanciamento automatico,
// con stabilizzazione nativa anti-speculazione.

contract MareaMangaNFT is ERC1155Upgradeable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    
    mapping(uint256 => string) public tokenIPFSCIDs; // tokenId => CID metadata
    mapping(uint256 => string) public provenanceCIDs; // tokenId => CID provenance
    mapping(uint256 => string) public voyageCIDs; // voyageId => CID log viaggio
    mapping(uint256 => string) public auctionCIDs; // auctionId => CID dati asta
    // 🗃️ MAPPING PER STORAGE IPFS

    // 🚢 TIPOLOGIE NAVI COMPLETE
    enum ShipType { 
        ZATTERA, GOLETTA, NAVE, TRANSATLANTICO,
        YACHT_SAILING, CAICCO, CATAMARANO, ALISCAFO,
        VELIERO, AMERIGO_VESPUCCI, LUNA_ROSSA,
        // 🆕 NAVI SPECIALI LUCCA COMICS
        POKEMON_EXPRESS, MAGIC_GALLEON, YUGIOH_CRUISER,
        DIGIMON_CARRIER, ONEPIECE_THOUSANDSUNNY
    }
    
    // 🏗️ STRUTTURE DATI COMPLETE
    struct NFTShip {
        ShipType shipType;
        string shipName;
        uint256 nftCapacity;
        uint256 currentNFTs;
        address captain;
        bool inVoyage;
        uint256 launchTime;
        uint256 prestigeLevel;
        uint256 speedMultiplier;
    }
    
    struct NFTPedigree {
        address originalMinter;
        address currentOwner;
        uint256 mintTimestamp;
        uint256 lastTransferTimestamp;
        string authenticityCode;
        string provenanceHistory;
        bool isCertified;
        address certifierAuthority;
        string gameUniverse; // "Pokemon", "Magic", "Yugioh", etc.
        string cardType; // "Character", "Spell", "Trap", etc.
        uint256 rarityScore;
        string provenanceCID; // 🔗 CID IPFS per storia completa
        string compressedProvenance; // ⚡ Versione compressa on-chain
    }
    
    function _createInitialProvenance(address to, string memory authenticityCode, string memory gameUniverse) 
    internal 
    returns (string memory cid) 
    { 
    // 📦 Prepara dati completi per IPFS
    bytes memory provenanceData = abi.encodePacked(
        '{"minter": "', _addressToString(to),
        '", "authenticityCode": "', authenticityCode,
        '", "gameUniverse": "', gameUniverse,
        '", "timestamp": ', _uint2str(block.timestamp),
        ', "type": "initial_mint"}'
    );
    
    // 🌐 Upload su IPFS (simulato/real)
    cid = _uploadProvenanceToIPFS(provenanceData);
    return cid;
    }
    
    struct ShippingContainer {
        uint256 containerId;
        address owner;
        uint256 shipId;
        uint256[] nftIds;
        uint256 capacity;
        uint256 currentLoad;
        bool inTransit;
        uint256 portOfOrigin;
        uint256 destinationPort;
        string containerType; // "Standard", "Premium", "Legendary"
    }
    
    struct CommercialPort {
        uint256 portId;
        string portName;
        string location; // "Lucca", "Tokyo", "New York"
        uint256 activityEndTime;
        uint256[] activeAuctions;
        uint256 entryFee;
        uint256 prestigeRequirement;
    }
    
    // 📊 MAPPING COMPLETI
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => NFTShip) public fleet;
    mapping(uint256 => NFTPedigree) public nftPedigrees;
    mapping(uint256 => ShippingContainer) public containers;
    mapping(uint256 => CommercialPort) public commercialPorts;
    mapping(address => uint256[]) public userContainers;
    mapping(address => bool) public authorizedCertifiers;
    mapping(string => bool) public registeredGameUniverses;
      
    // 🔢 VARIABILI DI STATO
    uint256 public shipCount;
    uint256 public containerCounter;
    uint256 public portCounter;
    uint256 public totalNFTsMinted;
    uint256 public totalTransactions;
    
    OceanState public ocean;
    uint256[] public activePorts;
    
    // 🌊 STATO OCEANO
    struct OceanState {
        uint256 totalNFTsEmbarked;
        uint256 totalShips;
        uint256 highTide;
        uint256 lowTide;
        uint256 lastTideChange;
        uint256 totalVoyagesCompleted;
    }
    
    // 🎯 EVENTI COMPLETI
    event ShipLaunched(uint256 shipId, ShipType shipType, string shipName, address captain);
    event ContainerLoaded(uint256 containerId, uint256 shipId, address owner);
    event ContainerUnloaded(uint256 containerId, uint256 portId);
    event CommercialAuctionStarted(uint256 portId, uint256[] nftIds, uint256 duration);
    event NFTPedigreeUpdated(uint256 nftId, address newOwner, string authenticityCode);
    event CertificateIssued(uint256 nftId, address certifier, string certificationData);
    event PortActivated(uint256 portId, string portName, uint256 duration);
    event VoyageCompleted(uint256 shipId, address captain, uint256 rewards);
    event GameUniverseRegistered(string gameUniverse, address registrant);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    // ✅ VARIABILI DI STATO - dichiarate correttamente
    string public ipfsBaseURI;
    string public nftStorageAPIKey;
    bool public metadataOnIPFS;

    function initialize() public initializer {
        __ERC1155_init("https://api.mareamanga.com/metadata/");
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
    
    // ✅ INIZIALIZZAZIONE - dentro la funzione
    metadataOnIPFS = false;
    }

    // ✅ FUNZIONI SEPARATE - fuori da initialize()

    function uri(uint256 tokenId) public view override returns (string memory) {
        if (metadataOnIPFS && bytes(ipfsBaseURI).length > 0) {
        return string(abi.encodePacked(ipfsBaseURI, _uint2str(tokenId), ".json"));
    }
    return string(abi.encodePacked(super.uri(tokenId), _uint2str(tokenId)));
    }

    function deployFleet() external onlyOwner {
        _deployCompleteFleet();
    }
    function initializeCommercialPorts() external onlyOwner {
        _initializeCommercialPorts();
    }
    function registerDefaultGameUniverses() external onlyOwner {
        _registerDefaultGameUniverses();
    }

    // 🚢 DEPLOY FLOTTA COMPLETA
    function _deployCompleteFleet() internal {
        // 🎪 NAVI BASE
        _addShip(ShipType.ZATTERA, "Zattera Solitaria", 10, 1);
        _addShip(ShipType.GOLETTA, "Goletta Veloce", 50, 3);
        _addShip(ShipType.NAVE, "Nave Maestosa", 200, 7);
        _addShip(ShipType.TRANSATLANTICO, "Transatlantico Regale", 1000, 15);
        
        // ⛵ NAVI SPECIALI
        _addShip(ShipType.YACHT_SAILING, "Yacht da Regata", 25, 8);
        _addShip(ShipType.CAICCO, "Caicco Turco", 75, 5);
        _addShip(ShipType.CATAMARANO, "Catamarano Veloce", 40, 6);
        _addShip(ShipType.ALISCAFO, "Aliscafo Jet", 30, 9);
        _addShip(ShipType.VELIERO, "Veliero Classico", 150, 12);
        _addShip(ShipType.AMERIGO_VESPUCCI, "Amerigo Vespucci", 500, 25);
        _addShip(ShipType.LUNA_ROSSA, "Luna Rossa AC75", 15, 20);
        
        // 🎮 NAVI TEMATICHE LUCCA COMICS
        _addShip(ShipType.POKEMON_EXPRESS, "Pokemon Express", 100, 10);
        _addShip(ShipType.MAGIC_GALLEON, "Magic Galleon", 120, 12);
        _addShip(ShipType.YUGIOH_CRUISER, "Yugioh Cruiser", 80, 11);
        _addShip(ShipType.DIGIMON_CARRIER, "Digimon Carrier", 90, 9);
        _addShip(ShipType.ONEPIECE_THOUSANDSUNNY, "Thousand Sunny", 200, 18);
    }
    
    function _addShip(ShipType shipType, string memory shipName, uint256 capacity, uint256 prestige) internal {
        fleet[shipCount] = NFTShip({
            shipType: shipType,
            shipName: shipName,
            nftCapacity: capacity,
            currentNFTs: 0,
            captain: msg.sender,
            inVoyage: false,
            launchTime: block.timestamp,
            prestigeLevel: prestige,
            speedMultiplier: _calculateSpeedMultiplier(shipType)
        });
        emit ShipLaunched(shipCount, shipType, shipName, msg.sender);
        shipCount++;
    }
    
    // 🚢 AGGIUNGI: Storage per log viaggi
    struct VoyageLog {
        uint256 voyageId;
        uint256 shipId;
        uint256 startTime;
        uint256 endTime;
        uint256[] transportedNFTs;
        string voyageDataCID; // 📊 Dati completi su IPFS
        uint256 rewardsEarned;
    }

    mapping(uint256 => VoyageLog) public voyageLogs;
    mapping(uint256 => string[]) public shipVoyageCIDs; // Tutti i CID per una nave

    event VoyageLogged(uint256 voyageId, uint256 shipId, string voyageCID);
    // 🎮 REGISTRAZIONE UNIVERSI DI GIOCO
    function _registerDefaultGameUniverses() internal {
        registeredGameUniverses["Pokemon"] = true;
        registeredGameUniverses["Magic The Gathering"] = true;
        registeredGameUniverses["Yugioh"] = true;
        registeredGameUniverses["Digimon"] = true;
        registeredGameUniverses["One Piece"] = true;
        registeredGameUniverses["Dragon Ball"] = true;
        registeredGameUniverses["Final Fantasy"] = true;
        registeredGameUniverses["World of Warcraft"] = true;
    }
    
    function registerNewGameUniverse(string memory gameUniverse) external onlyOwner {
        registeredGameUniverses[gameUniverse] = true;
        emit GameUniverseRegistered(gameUniverse, msg.sender);
    }
    
        // 🏷️ MINTING CERTIFICATO AVANZATO
        function mintCertifiedGameCard(
            address to,
            string memory tokenURI,
            string memory authenticityCode,
            string memory gameUniverse,
            string memory cardType,
            uint256 rarityScore,
            address certifier
    ) external nonReentrant returns (uint256) {
            require(registeredGameUniverses[gameUniverse], "Game universe not registered");

            uint256 newTokenId = totalNFTsMinted++;

            _mint(to, newTokenId, 1, "");
            // SOSTITUISCI: _setTokenURI(newTokenId, tokenURI);
            _setTokenMetadata(newTokenId, tokenURI); // 👈 USA QUESTA

         // 🏷️ CREA PEDIGREE AVANZATO
         nftPedigrees[newTokenId] = NFTPedigree({
            originalMinter: msg.sender,
            currentOwner: to,
            mintTimestamp: block.timestamp,
            lastTransferTimestamp: block.timestamp,
            authenticityCode: authenticityCode,
            provenanceHistory: _createInitialProvenance(to, authenticityCode, gameUniverse),
            isCertified: certifier != address(0),
            certifierAuthority: certifier,
            gameUniverse: gameUniverse,
            cardType: cardType,
            rarityScore: rarityScore
        });

        emit CertificateIssued(newTokenId, certifier, authenticityCode);
        return newTokenId;
    }        
    
    // 📦 SISTEMA CONTAINER AVANZATO
    function createShippingContainer(uint256 capacity, string memory containerType) external returns (uint256) {
        require(capacity > 0 && capacity <= getMaxContainerCapacity(containerType), "Capacity exceeded");
        
        uint256 containerId = containerCounter++;
        containers[containerId] = ShippingContainer({
            containerId: containerId,
            owner: msg.sender,
            shipId: 0,
            nftIds: new uint256[](0),
            capacity: capacity,
            currentLoad: 0,
            inTransit: false,
            portOfOrigin: 0,
            destinationPort: 0,
            containerType: containerType
        });
        
        userContainers[msg.sender].push(containerId);
        return containerId;
    }
    
    function loadNFTToContainer(uint256 containerId, uint256 nftId, uint256 shipId) external nonReentrant {
        ShippingContainer storage container = containers[containerId];
        require(container.owner == msg.sender, "Not container owner");
        require(container.currentLoad < container.capacity, "Container full");
        require(!container.inTransit, "Container in transit");
        
        require(balanceOf(msg.sender, nftId) > 0, "Not NFT owner");
        
        NFTShip storage ship = fleet[shipId];
        require(ship.currentNFTs + 1 <= ship.nftCapacity, "Ship capacity exceeded");
        
        // 🎯 VERIFICA COMPATIBILITÀ NAVE-UNIVERSO
        require(_checkShipUniverseCompatibility(ship.shipType, nftPedigrees[nftId].gameUniverse), 
                "Ship not compatible with NFT universe");
        
        _safeTransferFrom(msg.sender, address(this), nftId, 1, "");
        
        container.nftIds.push(nftId);
        container.currentLoad++;
        container.shipId = shipId;
        
        ship.currentNFTs++;
        ocean.totalNFTsEmbarked++;
        
        emit ContainerLoaded(containerId, shipId, msg.sender);
    }
    
    // 🏙️ SISTEMA PORTO COMMERCIALE
    function _initializeCommercialPorts() internal {
        _addCommercialPort("Porto di Lucca", "Lucca", 0, 100);
        _addCommercialPort("Tokyo Game Port", "Tokyo", 2 ether, 500);
        _addCommercialPort("New York Card Exchange", "New York", 5 ether, 1000);
        _addCommercialPort("Seoul e-Sports Harbor", "Seoul", 3 ether, 750);
        _addCommercialPort("London Collector's Dock", "London", 4 ether, 800);
    }
    
    function _addCommercialPort(string memory name, string memory location, uint256 fee, uint256 prestigeReq) internal {
        commercialPorts[portCounter] = CommercialPort({
            portId: portCounter,
            portName: name,
            location: location,
            activityEndTime: 0,
            activeAuctions: new uint256[](0),
            entryFee: fee,
            prestigeRequirement: prestigeReq
        });
        portCounter++;
    }
    
    function activatePort(uint256 portId, uint256 duration) external onlyOwner {
        commercialPorts[portId].activityEndTime = block.timestamp + duration;
        activePorts.push(portId);
        emit PortActivated(portId, commercialPorts[portId].portName, duration);
    }
    
    function unloadAtPort(uint256 containerId, uint256 portId) external payable nonReentrant {
        ShippingContainer storage container = containers[containerId];
        require(container.owner == msg.sender, "Not container owner");
        require(!container.inTransit, "Container in transit");
        require(_isPortActive(portId), "Port not active");
        
        // 💰 VERIFICA PRESTIGIO E FEE
        require(_calculateUserPrestige(msg.sender) >= commercialPorts[portId].prestigeRequirement, 
                "Prestige requirement not met");
        
        if (commercialPorts[portId].entryFee > 0) {
            require(msg.value >= commercialPorts[portId].entryFee, "Insufficient entry fee");
        }
        
        container.inTransit = false;
        container.destinationPort = portId;
        
        // 🎪 AVVIA ASTA 24H
        _startPortAuction(portId, container.nftIds, 24 hours);
        
        emit ContainerUnloaded(containerId, portId);
        emit CommercialAuctionStarted(portId, container.nftIds, 24 hours);
    }
    
    // 🎯 FUNZIONI DI GAMIFICAZIONE
    function startVoyage(uint256 shipId, uint256 destinationPort) external {
        require(shipId < shipCount, "Invalid ship");
        NFTShip storage ship = fleet[shipId];
        require(msg.sender == ship.captain, "Not captain");
        require(!ship.inVoyage, "Already in voyage");
        require(ship.currentNFTs > 0, "No NFTs loaded");
        
        ship.inVoyage = true;
        uint256 voyageDuration = _calculateVoyageDuration(ship.shipType, destinationPort);
        
        // ⏰ VIAGGIO AUTOMATICO
        _scheduleVoyageCompletion(shipId, voyageDuration);
    }
    
    function completeVoyage(uint256 shipId) external nonReentrant {
        NFTShip storage ship = fleet[shipId];
        require(ship.inVoyage, "Not in voyage");
        
        ship.inVoyage = false;
        uint256 rewards = _calculateVoyageRewards(shipId);
        
        if (rewards > 0) {
            _mint(msg.sender, 999, rewards, ""); // Token ricompensa
        }
        
        ocean.totalVoyagesCompleted++;
        emit VoyageCompleted(shipId, msg.sender, rewards);
    }
    
    // 🏆 SISTEMA PRESTIGIO E RICOMPENSE
    function _calculateUserPrestige(address user) internal view returns (uint256) {
        uint256 prestige = 0;
        
        // PRESTIGIO DA NAVI POSSEDUTE
        for (uint256 i = 0; i < shipCount; i++) {
            if (fleet[i].captain == user) {
                prestige += fleet[i].prestigeLevel;
            }
        }
        
        // PRESTIGIO DA TRANSACTION
        prestige += (totalTransactions / 100); // Bonus attività
        
        return prestige;
    }
    
    function _calculateVoyageRewards(uint256 shipId) internal view returns (uint256) {
        NFTShip storage ship = fleet[shipId];
        uint256 baseReward = ship.currentNFTs * 1e18;
        uint256 prestigeBonus = (baseReward * ship.prestigeLevel) / 10;
        uint256 speedBonus = (baseReward * ship.speedMultiplier) / 100;
        
        return baseReward + prestigeBonus + speedBonus;
    }
    
    // 🔧 FUNZIONI UTILITY
    function _checkShipUniverseCompatibility(ShipType shipType, string memory gameUniverse) 
        internal pure returns (bool) 
    {
        // 🎮 NAVI TEMATICHE COMPATIBILI
        if (shipType == ShipType.POKEMON_EXPRESS) return keccak256(abi.encodePacked(gameUniverse)) == keccak256(abi.encodePacked("Pokemon"));
        if (shipType == ShipType.MAGIC_GALLEON) return keccak256(abi.encodePacked(gameUniverse)) == keccak256(abi.encodePacked("Magic The Gathering"));
        if (shipType == ShipType.YUGIOH_CRUISER) return keccak256(abi.encodePacked(gameUniverse)) == keccak256(abi.encodePacked("Yugioh"));
        if (shipType == ShipType.DIGIMON_CARRIER) return keccak256(abi.encodePacked(gameUniverse)) == keccak256(abi.encodePacked("Digimon"));
        if (shipType == ShipType.ONEPIECE_THOUSANDSUNNY) return keccak256(abi.encodePacked(gameUniverse)) == keccak256(abi.encodePacked("One Piece"));
        
        return true; // Navi generiche compatibili con tutto
    }
    
    function getMaxContainerCapacity(string memory containerType) internal pure returns (uint256) {
        if (keccak256(abi.encodePacked(containerType)) == keccak256(abi.encodePacked("Standard"))) return 50;
        if (keccak256(abi.encodePacked(containerType)) == keccak256(abi.encodePacked("Premium"))) return 100;
        if (keccak256(abi.encodePacked(containerType)) == keccak256(abi.encodePacked("Legendary"))) return 200;
        return 25;
    }
    
    function _calculateSpeedMultiplier(ShipType shipType) internal pure returns (uint256) {
        if (shipType == ShipType.ALISCAFO) return 300; // +200%
        if (shipType == ShipType.CATAMARANO) return 250;
        if (shipType == ShipType.YACHT_SAILING) return 200;
        if (shipType == ShipType.LUNA_ROSSA) return 400;
        return 100; // Base 100%
    }
    
    function _calculateVoyageDuration(ShipType shipType, uint256 destination) internal pure returns (uint256) {
        uint256 baseDuration = 1 days;
        uint256 distanceMultiplier = (destination + 1) * 1 hours;
        uint256 speedBonus = (baseDuration * (100 - (_calculateSpeedMultiplier(shipType) - 100))) / 100;
        
        return distanceMultiplier + speedBonus;
    }
    
    // 🛠️ FUNZIONI UTILITY
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
    
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // 🎯 AGGIUNGI QUESTE FUNZIONI MANCANTI AL CONTRATTO

    // 1. FUNZIONE PER SETTARE URI (alternativa a _setTokenURI)
    function _setTokenMetadata(uint256 tokenId, string memory tokenURI) internal {
    // Per ERC1155, gestiamo l'URI in modo diverso
    // Possiamo usare un mapping per memorizzare gli URI
    // Aggiungi questo mapping in cima al contratto:
    // mapping(uint256 => string) private _tokenURIs;
    _tokenURIs[tokenId] = tokenURI;
    }

    // 2. FUNZIONE PER CREARE PROVENIENZA INIZIALE
    function _createInitialProvenance(
        address to, 
        string memory authenticityCode, 
        string memory gameUniverse
    ) internal view returns (string memory) {
        return string(abi.encodePacked(
        "Initial mint: ", 
        _addressToString(to), 
        " | Code: ", 
        authenticityCode, 
        " | Universe: ", 
        gameUniverse,
        " | Timestamp: ",
        _uintToString(block.timestamp)
    ));
    }

    // 3. FUNZIONE PER VERIFICARE PORTO ATTIVO
    function _isPortActive(uint256 portId) internal view returns (bool) {
        return commercialPorts[portId].activityEndTime > block.timestamp;
    }

    // 4. FUNZIONE PER AVVIARE ASTA PORTO (semplificata)
    function _startPortAuction(
        uint256 portId, 
        uint256[] memory nftIds, 
        uint256 duration
    ) internal {
        CommercialPort storage port = commercialPorts[portId];
    
        bytes memory auctionData = abi.encodePacked(
        '{"portId": ', _uint2str(portId),
        ', "nftCount": ', _uint2str(nftIds.length),
        ', "duration": ', _uint2str(duration),
        ', "startTime": ', _uint2str(block.timestamp),
        ', "nftIds": ['
    );
    
    for (uint256 i = 0; i < nftIds.length; i++) {
        auctionData = abi.encodePacked(auctionData, _uint2str(nftIds[i]));
        if (i < nftIds.length - 1) auctionData = abi.encodePacked(auctionData, ',');
    }
    auctionData = abi.encodePacked(auctionData, ']}');
    
    // 🌐 Salva su IPFS
    string memory auctionCID = _uploadAuctionDataToIPFS(auctionData);
    
    emit CommercialAuctionStarted(portId, nftIds, duration, auctionCID);
    }

    // Aggiungi l'asta alla lista delle aste attive
    // Per semplicità, usiamo il containerId come auctionId
    uint256 auctionId = portId * 1000 + port.activeAuctions.length;
    function addAuctionToPort(uint256 auctionId) internal {
        port.activeAuctions.push(auctionId);
    }
    
    // Qui puoi implementare la logica completa dell'asta
    function _emitCommercialAuction(uint256 portId, uint256[] memory nftIds, uint256 duration) internal {
        emit CommercialAuctionStarted(portId, nftIds, duration);
    }
    }
    
    // 🌐 SEZIONE STORAGE DECENTRALIZZATO

// 🗃️ MAPPING PER STORAGE IPFS

// 🔗 CONFIGURAZIONE ORCHESTRATOR

function configureStorage(string memory _nftStorageKey, string memory _pinataJWT) external onlyOwner {
    nftStorageAPIKey = _nftStorageKey;
    pinataJWT = _pinataJWT;
}

// 🌐 FUNZIONI IPFS
function _uploadToIPFS(bytes memory data) internal returns (string memory cid) {
    // 🎯 IMPLEMENTAZIONE REAL: Integrazione con Pinata/NFT.Storage
    // 📍 Per ora simuliamo la generazione CID
    bytes32 hash = keccak256(abi.encodePacked(data, block.timestamp));
    cid = string(abi.encodePacked("Qm", _bytes32ToHexString(hash), _uint2str(block.timestamp)));
    
    // ✅ In produzione: chiamata API a Pinata/NFT.Storage
    // usando nftStorageAPIKey e pinataJWT
    
    return cid;
}

function _uploadProvenanceToIPFS(bytes memory provenanceData) internal returns (string memory) {
    string memory cid = _uploadToIPFS(provenanceData);
    emit ProvenanceStored(cid, provenanceData);
    return cid;
}

function _uploadAuctionDataToIPFS(bytes memory auctionData) internal returns (string memory) {
    string memory cid = _uploadToIPFS(auctionData);
    return cid;
}

// 📊 FUNZIONI RECUPERO DATI
function getTokenMetadataCID(uint256 tokenId) external view returns (string memory) {
    return tokenIPFSCIDs[tokenId];
}

function getProvenanceHistory(uint256 tokenId) external view returns (string memory cid, string memory compressed) {
    return (provenanceCIDs[tokenId], nftPedigrees[tokenId].provenanceHistory);
}

function getShipVoyageHistory(uint256 shipId) external view returns (string[] memory voyageCIDs) {
    return shipVoyageCIDs[shipId];
}

// 🛠️ UTILITY FUNCTIONS
function _bytes32ToHexString(bytes32 _bytes32) internal pure returns (string memory) {
    bytes memory s = new bytes(64);
    for (uint256 i = 0; i < 32; i++) {
        bytes1 b = bytes1(_bytes32[i]);
        bytes1 hi = bytes1(uint8(b) / 16);
        bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
        s[i * 2] = _char(hi);
        s[i * 2 + 1] = _char(lo);
    }
    return string(s);
}

function _char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
    }

    function _uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
          j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
        k = k - 1;
        uint8 temp = (48 + uint8(_i - _i / 10 * 10));
        bytes1 b1 = bytes1(temp);
        bstr[k] = b1;
        _i /= 10;
    }
    return string(bstr);
    }

    // 📈 EVENTI AGGIUNTIVI

    // 5. FUNZIONE PER SCHEDULARE COMPLETAMENTO VIAGGIO
    function _scheduleVoyageCompletion(uint256 shipId, uint256 duration) internal {
        // In una implementazione reale, useresti un oracolo o un sistema di scheduling
        // Per ora, memorizziamo il tempo di completamento
        fleet[shipId].launchTime = block.timestamp + duration;
    
    // In produzione, implementeresti Chainlink Keepers o simile
    }

    // 🛠️ FUNZIONI UTILITY AUSILIARIE
    function _addressToString(address addr) internal pure returns (string memory) {
        return _bytes32ToStr(bytes32(uint256(uint160(addr)) << 96));
    }

    function _bytes32ToStr(bytes32 _bytes32) internal pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
    }

    function _uintToString(uint256 value) internal view returns (string memory) {
        if (value == 0) return "0";
    
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
    
    // IN MareaMangaNFT.sol - Aggiungi queste funzioni:

    struct AchievementBadge {
        string badgeName;        // "Early Adopter", "Ethical Trader", "Community Builder"
        string description;
        uint256 requiredReputation;
        uint256 awardedTimestamp;
        string badgeCID;         // 🔗 Metadata su IPFS
    }

    function awardBadge(address user, string memory badgeName) external onlyRole(PLANET_MANAGER) {
        require(availableBadges[badgeName], "Badge not available");
        require(_hasRequiredReputation(user, badgeName), "Reputation requirement not met");
    
    string memory badgeCID = _storeBadgeMetadata(badgeName, user);
    
    userBadges[user].push(AchievementBadge({
        badgeName: badgeName,
        description: _getBadgeDescription(badgeName),
        requiredReputation: _getBadgeReputationRequirement(badgeName),
        awardedTimestamp: block.timestamp,
        badgeCID: badgeCID
    }));
    
    // Bonus reputazione per badge
    _updateReputation(user, 25, "badge_awarded");
    
    emit BadgeAwarded(user, badgeName, badgeCID);
    }

    function getUserBadges(address user) external view returns (AchievementBadge[] memory) {
        return userBadges[user];
  }
