// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract TimelockNFTVault is Ownable {
    struct StakeInfo {
        uint256 amount;
        uint256 startTimestamp;
        bool requestedWithdraw;
        bool withdrawn;
    }

    uint256 public constant LOCK_PERIOD = 21 days;
    uint256 public constant MAX_PERIOD = 30 days;
    uint256 public constant CANCEL_WINDOW = 15 days;

    IERC20 public immutable stakingToken;
    IERC721 public immutable nft;

    // tokenId => StakeInfo
    mapping(uint256 => StakeInfo) public stakes;

    event Staked(address indexed user, uint256 indexed tokenId, uint256 amount);
    event WithdrawRequested(address indexed user, uint256 indexed tokenId);
    event Withdrawn(address indexed user, uint256 indexed tokenId, uint256 amount);
    event Cancelled(address indexed user, uint256 indexed tokenId);

    constructor(address _stakingToken, address _nft) {
        stakingToken = IERC20(_stakingToken);
        nft = IERC721(_nft);
    }

    function stakeForNFT(uint256 tokenId, uint256 amount) external {
        require(nft.ownerOf(tokenId) == msg.sender, "Not NFT owner");
        require(stakes[tokenId].amount == 0, "Already staked");
        require(amount > 0, "Amount zero");
        stakingToken.transferFrom(msg.sender, address(this), amount);
        stakes[tokenId] = StakeInfo({
            amount: amount,
            startTimestamp: block.timestamp,
            requestedWithdraw: false,
            withdrawn: false
        });
        emit Staked(msg.sender, tokenId, amount);
    }

    function requestWithdraw(uint256 tokenId) external {
        require(nft.ownerOf(tokenId) == msg.sender, "Not NFT owner");
        StakeInfo storage info = stakes[tokenId];
        require(info.amount > 0, "No stake");
        require(!info.requestedWithdraw, "Already requested");
        require(block.timestamp >= info.startTimestamp + CANCEL_WINDOW, "Too early");
        info.requestedWithdraw = true;
        emit WithdrawRequested(msg.sender, tokenId);
    }

    // Only admin can process withdrawal after lock period or max period
    function processWithdraw(uint256 tokenId) external onlyOwner {
        StakeInfo storage info = stakes[tokenId];
        require(info.amount > 0, "No stake");
        require(info.requestedWithdraw, "Not requested");
        require(!info.withdrawn, "Already withdrawn");
        require(
            block.timestamp >= info.startTimestamp + LOCK_PERIOD ||
            block.timestamp >= info.startTimestamp + MAX_PERIOD,
            "Lock not expired"
        );
        address nftOwner = nft.ownerOf(tokenId);
        uint256 amount = info.amount;
        info.withdrawn = true;
        stakingToken.transfer(nftOwner, amount);
        emit Withdrawn(nftOwner, tokenId, amount);
    }

    // Emergency: admin can cancel stake and return funds after max period
    function adminCancel(uint256 tokenId) external onlyOwner {
        StakeInfo storage info = stakes[tokenId];
        require(info.amount > 0, "No stake");
        require(!info.withdrawn, "Already withdrawn");
        require(block.timestamp >= info.startTimestamp + MAX_PERIOD, "Too early");
        address nftOwner = nft.ownerOf(tokenId);
        uint256 amount = info.amount;
        info.withdrawn = true;
        stakingToken.transfer(nftOwner, amount);
        emit Cancelled(nftOwner, tokenId);
    }
}
