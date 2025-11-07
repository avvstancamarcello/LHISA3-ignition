// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca, Firenze, Italy

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

contract SolidaryGamingBridge is Initializable, OwnableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    IERC20Upgradeable public solidaryToken;
    EnumerableSetUpgradeable.AddressSet private registeredGamers;

    mapping(address => uint256) public gamerScores;
    mapping(address => uint256) public redeemedTokens;
    mapping(address => string) public linkedGameIDs;

    event GamerRegistered(address indexed gamer, string gameID);
    event ScoreUpdated(address indexed gamer, uint256 newScore);
    event TokensMinted(address indexed gamer, uint256 amount);
    event Redemption(address indexed gamer, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address tokenAddress) public initializer {
        __Ownable_init();
        solidaryToken = IERC20Upgradeable(tokenAddress);
    }

    function registerGamer(address gamer, string memory gameID) external onlyOwner {
        require(!registeredGamers.contains(gamer), "Gamer already registered");
        registeredGamers.add(gamer);
        linkedGameIDs[gamer] = gameID;
        emit GamerRegistered(gamer, gameID);
    }

    function updateScore(address gamer, uint256 scoreDelta) external onlyOwner {
        require(registeredGamers.contains(gamer), "Gamer not registered");
        gamerScores[gamer] += scoreDelta;
        emit ScoreUpdated(gamer, gamerScores[gamer]);
    }

    function mintTokens(address gamer) external onlyOwner {
        uint256 score = gamerScores[gamer];
        require(score > 0, "No score to convert");
        uint256 amount = score * 1e18;
        solidaryToken.transfer(gamer, amount);
        redeemedTokens[gamer] += score;
        gamerScores[gamer] = 0;
        emit TokensMinted(gamer, amount);
    }

    function redeemBan(address gamer, uint256 amount) external {
        require(registeredGamers.contains(gamer), "Gamer not registered");
        require(solidaryToken.transferFrom(gamer, address(this), amount), "Transfer failed");
        redeemedTokens[gamer] += amount;
        emit Redemption(gamer, amount);
    }

    function getGamerScore(address gamer) external view returns (uint256) {
        return gamerScores[gamer];
    }

    function getLinkedGameID(address gamer) external view returns (string memory) {
        return linkedGameIDs[gamer];
    }

    function isRegistered(address gamer) external view returns (bool) {
        return registeredGamers.contains(gamer);
    }
}
