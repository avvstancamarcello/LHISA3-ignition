// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

// Copyright Marcello Stanca, Lawyer, Italy, Florence.
// This smart contract is a modular element of the SolidarySystem ecosystem/project, deployed on Polygon and Base networks.

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface ICosmixSolidaryToken {
    function mint(address to, uint256 amount) external;
}

interface IOceanMangaNFT {
    function mint(address to, uint256 id, uint256 amount, bytes calldata data) external;
}

contract OceanMangaOrchestratorV3 is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    IOceanMangaNFT public oceanMangaNFT;
    ICosmixSolidaryToken public cosmixFT;
    address public creator;
    address public charityFund;

    uint256 public constant NFT_SHARE = 550;      // 55%
    uint256 public constant FT_SHARE = 450;       // 45%
    uint256 public constant CREATOR_SHARE = 25;   // 2.5%
    uint256 public constant CHARITY_SHARE = 25;   // 2.5%
    uint256 public ftRatio = 1000;
    uint256 public nextTokenId = 1;

    // Lock/staking logic
    mapping(uint256 => uint256) public nftLockEnd;
    uint256 public lockPeriod = 90 days;

    event PhotoMinted(address indexed user, uint256 ethPaid, uint256 nftId, uint256 ftAmount, bool locked);
    event LockPeriodChanged(uint256 newPeriod);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _nft,
        address _ft,
        address _creator,
        address _charity
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        oceanMangaNFT = IOceanMangaNFT(_nft);
        cosmixFT = ICosmixSolidaryToken(_ft);
        creator = _creator;
        charityFund = _charity;
    }

    function mintPhotoCombo(string memory tokenURI) external payable nonReentrant whenNotPaused {
        require(msg.value > 0, "Payment required");
        uint256 total = msg.value;
        uint256 currentTokenId = nextTokenId++;

        // Calcola le quote
        uint256 ftAmount = (total * FT_SHARE) / 1000;
        uint256 creatorAmount = (total * CREATOR_SHARE) / 1000;
        uint256 charityAmount = (total * CHARITY_SHARE) / 1000;

        // Mint NFT
        oceanMangaNFT.mint(msg.sender, currentTokenId, 1, abi.encode(tokenURI));
        // Lock NFT for lockPeriod
        nftLockEnd[currentTokenId] = block.timestamp + lockPeriod;

        // Mint FT
        uint256 ftTokensToMint = (ftAmount * ftRatio) / 1 ether;
        cosmixFT.mint(msg.sender, ftTokensToMint);

        // Distribuisci pagamenti
        payable(creator).transfer(creatorAmount);
        payable(charityFund).transfer(charityAmount);

        emit PhotoMinted(msg.sender, total, currentTokenId, ftTokensToMint, true);
    }

    function isNFTLocked(uint256 tokenId) public view returns (bool) {
        return block.timestamp < nftLockEnd[tokenId];
    }

    function setLockPeriod(uint256 newPeriod) external onlyOwner {
        lockPeriod = newPeriod;
        emit LockPeriodChanged(newPeriod);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
