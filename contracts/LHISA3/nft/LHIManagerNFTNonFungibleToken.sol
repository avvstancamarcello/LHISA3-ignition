// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// © Copyright Marcello Stanca - Italy - Florence. Author and owner of the Solidary.it ecosystem and this smart contract. The ecosystem and its logical components (.sol files and scripts) are protected by copyright.


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface ILHILecceNFT {
    function safeMint(address to, string memory uri, string memory description) external;
    function totalSupply() external view returns (uint256);
}

interface IAccessControlSolidary {
    function hasRole(address user, string memory role) external view returns (bool);
}

interface ISolidaryIdentity {
    function isVerified(address user) external view returns (bool);
}

interface IReputationManager {
    function getReputationScore(address user) external view returns (uint256);
}

interface IDonationTracker {
    function hasDonated(address user) external view returns (bool);
}

interface IScientificProof {
    function isResearchValidated(uint256 proofId) external view returns (bool);
}

contract LHIManagerNFTNonFungibleToken is Ownable {
    address public lhiLecceNFT;
    address public accessControl;
    address public identityModule;
    address public reputationModule;
    address public donationModule;
    address public proofModule;

    // Struct to store user profile data
    struct UserProfile {
        string role; // Assigned role (e.g., RESEARCHER)
        string[] badges; // List of earned badges
        uint256[] missions; // Completed mission IDs
        bool hasReceivedNFT; // Whether the user has received an NFT
        uint256 lastMintTimestamp; // Timestamp of last mint
    }

    // Mapping to store user profiles
    mapping(address => UserProfile) private userProfiles;
    // Mapping to track minting limits per NFT type
    mapping(uint256 => uint256) public mintLimits;
    // Mapping to count how many NFTs have been minted per type
    mapping(uint256 => uint256) public mintedCount;
    // Mapping to store category labels (e.g., Science, Property)
    mapping(uint256 => string) public categoryLabels;
    // Mapping to track authorized minters
    mapping(address => bool) public approvedMinters;

    event NFTMinted(address indexed to, uint256 indexed nftId, string description);
    event UserRoleSet(address indexed user, string role);
    event UserBadgeGranted(address indexed user, string badge);
    event UserMissionRecorded(address indexed user, uint256 missionId);
    event UserNFTStatusReset(address indexed user, string reason);
    event CategoryDefined(uint256 indexed categoryId, string label);
    event MinterApproved(address indexed minter);
    event MinterRevoked(address indexed minter);

    modifier onlyApprovedMinter() {
        require(msg.sender == owner() || approvedMinters[msg.sender], "Not authorized");
        _;
    }

    constructor(
        address initialOwner,
        address nftContract,
        address accessControlContract,
        address identityContract,
        address reputationContract,
        address donationContract,
        address proofContract
    ) Ownable() {
        lhiLecceNFT = nftContract;
        accessControl = accessControlContract;
        identityModule = identityContract;
        reputationModule = reputationContract;
        donationModule = donationContract;
        proofModule = proofContract;
    }

    function setMintLimit(uint256 nftId, uint256 maxQuantity) external onlyOwner {
        mintLimits[nftId] = maxQuantity;
    }

    function defineCategory(uint256 categoryId, string memory label) external onlyOwner {
        categoryLabels[categoryId] = label;
        emit CategoryDefined(categoryId, label);
    }

    function setUserRole(address user, string memory role) external onlyOwner {
        userProfiles[user].role = role;
        emit UserRoleSet(user, role);
    }

    function approveMinter(address minter) external onlyOwner {
        approvedMinters[minter] = true;
        emit MinterApproved(minter);
    }

    function revokeMinter(address minter) external onlyOwner {
        approvedMinters[minter] = false;
        emit MinterRevoked(minter);
    }

    function mintValidatedNFT(address to, uint256 nftId, uint256 categoryId, uint256 proofId) external onlyApprovedMinter {
        require(!userProfiles[to].hasReceivedNFT, "NFT already assigned");
        require(mintedCount[nftId] < mintLimits[nftId], "Minting limit reached");

        require(ISolidaryIdentity(identityModule).isVerified(to), "Identity not verified");
        require(IAccessControlSolidary(accessControl).hasRole(to, "RESEARCHER"), "Role not authorized");
        require(IReputationManager(reputationModule).getReputationScore(to) >= 80, "Insufficient reputation");
        require(IDonationTracker(donationModule).hasDonated(to), "Donation not registered");
        require(IScientificProof(proofModule).isResearchValidated(proofId), "Scientific proof not valid");

        string memory uri = string(abi.encodePacked("https://solidary.org/metadata/", Strings.toString(nftId)));
        string memory description = string(abi.encodePacked("Category: ", categoryLabels[categoryId], ", Role: ", userProfiles[to].role, ", Proof: ", Strings.toString(proofId)));

        ILHILecceNFT(lhiLecceNFT).safeMint(to, uri, description);

        mintedCount[nftId]++;
        userProfiles[to].hasReceivedNFT = true;
        userProfiles[to].lastMintTimestamp = block.timestamp;

        emit NFTMinted(to, nftId, description);
    }

    function grantUserBadge(address user, string memory badgeName) external onlyOwner {
        userProfiles[user].badges.push(badgeName);
        emit UserBadgeGranted(user, badgeName);
    }

    function recordUserMission(address user, uint256 missionId) external onlyOwner {
        userProfiles[user].missions.push(missionId);
        emit UserMissionRecorded(user, missionId);
    }

    function resetUserNFTStatus(address user, string memory reason) external onlyOwner {
        userProfiles[user].hasReceivedNFT = false;
        emit UserNFTStatusReset(user, reason);
    }

    function getUserRole(address user) external view returns (string memory) {
        return userProfiles[user].role;
    }

    function getUserBadges(address user) external view returns (string[] memory) {
        return userProfiles[user].badges;
    }

    function getUserMissions(address user) external view returns (uint256[] memory) {
        return userProfiles[user].missions;
    }

    function hasUserReceived(address user) external view returns (bool) {
        return userProfiles[user].hasReceivedNFT;
    }

    function getLastMintTimestamp(address user) external view returns (uint256) {
        return userProfiles[user].lastMintTimestamp;
    }

    function getMintedCount(uint256 nftId) external view returns (uint256) {
        return mintedCount[nftId];
    }

    function getCategoryLabel(uint256 categoryId) external view returns (string memory) {
        return categoryLabels[categoryId];
    }

    function isApprovedMinter(address minter) external view returns (bool) {
        return approvedMinters[minter];
    }
}
