// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

// Copyright © 2025 Avv. Marcello Stanca - Firenze, Italia. All Rights Reserved.
// Hoc contractum, pars SolidarySystem.org, ab Auctore Marcello Stanca Caritas Internationalis (MCMLXXVI) conceditur.

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract LuccaComixSolidary is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    // Token addresses (saranno deployati separatamente)
    address public tokenAddress;
    address public nftAddress;
    
    // Charity system
    struct Charity {
        string name;
        string description;
        uint256 votes;
        address wallet;
        bool active;
    }
    
    Charity[] public charities;
    mapping(address => bool) public hasVotedForCharity;
    
    // Lottery system
    mapping(uint256 => address[]) public hourlyParticipants;
    uint256 public constant HOURLY_PRIZE = 100 * 10**18;
    
    // Events
    event CharityVoteCast(address indexed voter, uint256 charityId, uint256 timestamp);
    event PhotoMinted(address indexed creator, uint256 nftId, string emotion);
    event AnonymousWin(address indexed winner, uint256 amount, uint256 timestamp);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Ownable_init(_msgSender());
        __UUPSUpgradeable_init();
    }
    
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    // ✅ AGGIUNTE FUNZIONI DI LETTURA PER BASESCAN
    function getContractInfo() public view returns (
        address _tokenAddress,
        address _nftAddress,
        address _owner,
        uint256 _charityCount,
        uint256 _hourlyPrize
    ) {
        return (
            tokenAddress,
            nftAddress,
            owner(),
            charities.length,
            HOURLY_PRIZE
        );
    }
    
    function getCharityInfo(uint256 charityId) public view returns (
        string memory name,
        string memory description,
        uint256 votes,
        address wallet,
        bool active
    ) {
        require(charityId < charities.length, "Invalid charity");
        Charity memory charity = charities[charityId];
        return (
            charity.name,
            charity.description,
            charity.votes,
            charity.wallet,
            charity.active
        );
    }
    
    function getCharityCount() public view returns (uint256) {
        return charities.length;
    }
    
    function getCurrentHourParticipants() public view returns (uint256) {
        uint256 currentHour = block.timestamp / 3600;
        return hourlyParticipants[currentHour].length;
    }
    
    function mintEmotionalMemory(string memory emotion) external payable returns (uint256) {
        require(msg.value >= 0.01 ether, "Minimum minting fee 0.01 ETH");
        
        // Qui chiameremo i contratti token e NFT separati
        // Per ora simuliamo il minting
        
        _addToLottery(msg.sender);
        
        emit PhotoMinted(msg.sender, 0, emotion); // Simulato
        return 0;
    }
    
    function _addToLottery(address participant) internal {
        uint256 currentHour = block.timestamp / 3600;
        hourlyParticipants[currentHour].push(participant);
    }
    
    function voteForCharity(uint256 charityId) external {
        require(!hasVotedForCharity[msg.sender], "Already voted");
        require(charityId < charities.length, "Invalid charity");
        require(charities[charityId].active, "Charity not active");

        charities[charityId].votes++;
        hasVotedForCharity[msg.sender] = true;

        emit CharityVoteCast(msg.sender, charityId, block.timestamp);
    }
    
    function addCharity(string memory name, string memory description, address wallet) external onlyOwner {
        charities.push(Charity(name, description, 0, wallet, true));
    }
    
    function setTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = _tokenAddress;
    }
    
    function setNftAddress(address _nftAddress) external onlyOwner {
        nftAddress = _nftAddress;
    }
}
