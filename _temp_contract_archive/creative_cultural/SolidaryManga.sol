// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

// Copyright © 2025 Avv. Marcello Stanca - Firenze, Italia. All Rights Reserved.
// Hoc contractum, pars Systematis Solidarii, ab Auctore Marcello Stanca 
// Caritati Internationalis (MCMLXXVI) gratis conceditur.
// (This smart contract, part of the Solidary System, is granted for free use 
// to Caritas Internationalis (1976) by the author, Marcello Stanca.)


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SolidaryManga - LUCCA COMICS 2025 EMERGENCY LAUNCH
 * @dev Prima criptovaluta manga mondiale per Lucca Comics & Games
 * 
 * FEATURES:
 * - Royalties automatiche per organizzatori Lucca Comics (5%)
 * - Funding trasparente per 40 Barche Umanitarie Mediterraneo
 * - Community governance per contenuti manga
 * - Creator support system per mangaka
 */
contract SolidaryManga is ERC20, Ownable {
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎭 LUCCA COMICS 2025 CONSTANTS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    uint256 public constant TOTAL_SUPPLY = 1_000_000 * 10**18; // 1M MANGA tokens
    uint256 public constant LUCCA_ROYALTY_PERCENTAGE = 5; // 5% per Lucca Comics
    uint256 public constant HUMANITARIAN_PERCENTAGE = 10; // 10% per Mediterranean mission
    uint256 public constant CREATOR_PERCENTAGE = 40; // 40% per manga creators
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌍 STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    address public luccaComicsWallet;
    address public mediterraneanAidWallet;
    address public creatorFundWallet;
    
    uint256 public totalSalesVolume;
    uint256 public totalLuccaRoyalties;
    uint256 public totalHumanitarianFunding;
    uint256 public luccaComicsLaunchDate; // 31 October 2025
    
    mapping(address => bool) public approvedMangaCreators;
    mapping(address => uint256) public creatorRoyalties;
    mapping(string => MangaSeries) public mangaSeries;
    
    struct MangaSeries {
        string title;
        address creator;
        uint256 totalSales;
        bool isActive;
        string ipfsMetadata;
    }
    
    string[] public allMangaSeries;
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 EVENTS - LUCCA COMICS INTEGRATION
    // ═══════════════════════════════════════════════════════════════════════════════
    
    event LuccaComicsRoyaltyDistributed(uint256 amount, uint256 timestamp);
    event MediterraneanAidFunded(uint256 amount, string boatMission);
    event MangaSeriesCreated(string title, address creator);
    event CreatorRoyaltyPaid(address creator, uint256 amount);
    event MangaPurchase(address buyer, string series, uint256 amount);
    event LuccaComicsLaunched(uint256 launchDate, uint256 totalParticipants);
    
    constructor(
        address _luccaComicsWallet,
        address _mediterraneanAidWallet,
        address _creatorFundWallet,
        address initialOwner
    ) ERC20("Solidary Manga", "MANGA") Ownable(initialOwner) {
        require(_luccaComicsWallet != address(0), "Invalid Lucca wallet");
        require(_mediterraneanAidWallet != address(0), "Invalid aid wallet");
        require(_creatorFundWallet != address(0), "Invalid creator wallet");
        
        luccaComicsWallet = _luccaComicsWallet;
        mediterraneanAidWallet = _mediterraneanAidWallet;
        creatorFundWallet = _creatorFundWallet;
        
        // Set Lucca Comics launch date: October 31, 2025
        luccaComicsLaunchDate = 1735689600; // Unix timestamp for Oct 31, 2025
        
        // Mint total supply with strategic distribution
        _mint(initialOwner, TOTAL_SUPPLY * 45 / 100); // 45% public sale
        _mint(_creatorFundWallet, TOTAL_SUPPLY * 30 / 100); // 30% creator fund
        _mint(address(this), TOTAL_SUPPLY * 15 / 100); // 15% operations
        _mint(_luccaComicsWallet, TOTAL_SUPPLY * 5 / 100); // 5% Lucca Comics
        _mint(_mediterraneanAidWallet, TOTAL_SUPPLY * 5 / 100); // 5% humanitarian
        
        // Create initial manga series for Lucca Comics launch
        _createInitialMangaSeries();
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎭 MANGA SERIES MANAGEMENT - LUCCA COMICS READY
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function createMangaSeries(
        string memory _title,
        address _creator,
        string memory _ipfsMetadata
    ) public onlyOwner {
        require(bytes(_title).length > 0, "Title required");
        require(_creator != address(0), "Invalid creator address");
        require(bytes(mangaSeries[_title].title).length == 0, "Series exists");
        
        mangaSeries[_title] = MangaSeries({
            title: _title,
            creator: _creator,
            totalSales: 0,
            isActive: true,
            ipfsMetadata: _ipfsMetadata
        });
        
        allMangaSeries.push(_title);
        approvedMangaCreators[_creator] = true;
        
        emit MangaSeriesCreated(_title, _creator);
    }
    
    function purchaseManga(
        string memory _seriesTitle,
        uint256 _amount
    ) public {
        require(_amount > 0, "Amount must be > 0");
        require(mangaSeries[_seriesTitle].isActive, "Series not active");
        require(balanceOf(msg.sender) >= _amount, "Insufficient MANGA tokens");
        
        // Transfer tokens to contract for royalty distribution
        _transfer(msg.sender, address(this), _amount);
        
        // Update stats
        mangaSeries[_seriesTitle].totalSales += _amount;
        totalSalesVolume += _amount;
        
        // Distribute royalties automatically
        _distributePurchaseRoyalties(_seriesTitle, _amount);
        
        emit MangaPurchase(msg.sender, _seriesTitle, _amount);
    }
    
    function _distributePurchaseRoyalties(string memory _seriesTitle, uint256 _amount) internal {
        MangaSeries storage series = mangaSeries[_seriesTitle];
        
        // 40% to manga creator
        uint256 creatorAmount = _amount * CREATOR_PERCENTAGE / 100;
        _transfer(address(this), series.creator, creatorAmount);
        creatorRoyalties[series.creator] += creatorAmount;
        
        // 5% to Lucca Comics organizers  
        uint256 luccaAmount = _amount * LUCCA_ROYALTY_PERCENTAGE / 100;
        _transfer(address(this), luccaComicsWallet, luccaAmount);
        totalLuccaRoyalties += luccaAmount;
        
        // 10% to Mediterranean humanitarian mission
        uint256 aidAmount = _amount * HUMANITARIAN_PERCENTAGE / 100;
        _transfer(address(this), mediterraneanAidWallet, aidAmount);
        totalHumanitarianFunding += aidAmount;
        
        // 45% remains for operations
        
        emit CreatorRoyaltyPaid(series.creator, creatorAmount);
        emit LuccaComicsRoyaltyDistributed(luccaAmount, block.timestamp);
        emit MediterraneanAidFunded(aidAmount, "40 Sails Mediterranean Mission");
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🌍 MEDITERRANEAN AID MISSION FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function donateToMediterraneanMission(uint256 _amount, string memory _boatName) public {
        require(_amount > 0, "Amount must be > 0");
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance");
        
        _transfer(msg.sender, mediterraneanAidWallet, _amount);
        totalHumanitarianFunding += _amount;
        
        emit MediterraneanAidFunded(_amount, _boatName);
    }
    
    function getMediterraneanMissionProgress() public view returns (
        uint256 totalFunded,
        uint256 fromLuccaRoyalties,
        uint256 fromDirectDonations,
        uint256 boatCount,
        string memory currentStatus
    ) {
        totalFunded = totalHumanitarianFunding;
        fromLuccaRoyalties = totalLuccaRoyalties;
        fromDirectDonations = totalHumanitarianFunding - totalLuccaRoyalties;
        boatCount = 40; // 40 humanitarian boats
        currentStatus = "Active: 40 boats delivering aid to Israel/Palestine";
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎪 LUCCA COMICS 2025 SPECIFIC FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function getLuccaComicsStats() public view returns (
        uint256 launchDate,
        uint256 totalRoyaltiesEarned,
        uint256 totalMangaSeriesCount,
        uint256 totalSalesVolume_,
        bool isLaunchActive
    ) {
        launchDate = luccaComicsLaunchDate;
        totalRoyaltiesEarned = totalLuccaRoyalties;
        totalMangaSeriesCount = allMangaSeries.length;
        totalSalesVolume_ = totalSalesVolume;
        isLaunchActive = block.timestamp >= luccaComicsLaunchDate && 
                         block.timestamp <= luccaComicsLaunchDate + 4 days;
    }
    
    function announceLuccaComicsLaunch() public onlyOwner {
        require(block.timestamp >= luccaComicsLaunchDate - 1 days, "Too early");
        
        emit LuccaComicsLaunched(luccaComicsLaunchDate, allMangaSeries.length);
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎨 MANGA CREATOR FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function withdrawCreatorRoyalties() public {
        require(approvedMangaCreators[msg.sender], "Not approved creator");
        uint256 amount = creatorRoyalties[msg.sender];
        require(amount > 0, "No royalties available");
        
        creatorRoyalties[msg.sender] = 0;
        _transfer(address(this), msg.sender, amount);
    }
    
    function getCreatorStats(address _creator) public view returns (
        uint256 totalRoyalties,
        uint256 seriesCount,
        bool isApproved
    ) {
        totalRoyalties = creatorRoyalties[_creator];
        isApproved = approvedMangaCreators[_creator];
        
        uint256 count = 0;
        for (uint256 i = 0; i < allMangaSeries.length; i++) {
            if (mangaSeries[allMangaSeries[i]].creator == _creator) {
                count++;
            }
        }
        seriesCount = count;
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 📊 ANALYTICS & INFO FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function getMangaSeriesInfo(string memory _title) public view returns (
        address creator,
        uint256 totalSales,
        bool isActive,
        string memory ipfsMetadata
    ) {
        MangaSeries memory series = mangaSeries[_title];
        return (series.creator, series.totalSales, series.isActive, series.ipfsMetadata);
    }
    
    function getAllMangaSeries() public view returns (string[] memory) {
        return allMangaSeries;
    }
    
    function _createInitialMangaSeries() internal {
        // Create flagship manga series for Lucca Comics 2025 launch
        string[3] memory titles = [
            "Blockchain Heroes: The Decentralized Samurai",
            "Mediterranean Guardians: 40 Sails of Hope", 
            "Solidarity Angels: Manga for Change"
        ];
        
        for (uint256 i = 0; i < titles.length; i++) {
            mangaSeries[titles[i]] = MangaSeries({
                title: titles[i],
                creator: owner(),
                totalSales: 0,
                isActive: true,
                ipfsMetadata: "QmLuccaComics2025LaunchSeries"
            });
            allMangaSeries.push(titles[i]);
        }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🎌 CULTURAL & SOLIDARITY MESSAGES
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function getMangaSolidarityQuote() public pure returns (string memory) {
        return "Blockchain ni yotte, manga no chikara de sekai wo sukuu! (Through blockchain, we save the world with the power of manga!)";
    }
    
    function getLuccaComicsMessage() public pure returns (string memory) {
        return "From Lucca Comics to Mediterranean Hearts: Manga Meets Blockchain for Global Solidarity!";
    }
    
    function getMediterraneanMessage() public pure returns (string memory) {
        return "40 Sails Carry Hope, 1 Million MANGA Tokens Carry Change. Together We Bridge All Seas!";
    }
    
    // ═══════════════════════════════════════════════════════════════════════════════
    // 🔧 ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════
    
    function updateLuccaComicsWallet(address _newWallet) external onlyOwner {
        require(_newWallet != address(0), "Invalid address");
        luccaComicsWallet = _newWallet;
    }
    
    function updateMediterraneanAidWallet(address _newWallet) external onlyOwner {
        require(_newWallet != address(0), "Invalid address");
        mediterraneanAidWallet = _newWallet;
    }
    
    function approveNewMangaCreator(address _creator) external onlyOwner {
        approvedMangaCreators[_creator] = true;
    }
    
    function toggleMangaSeriesStatus(string memory _title) external onlyOwner {
        mangaSeries[_title].isActive = !mangaSeries[_title].isActive;
    }
}
