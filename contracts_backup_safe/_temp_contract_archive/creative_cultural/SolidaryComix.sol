// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

// Copyright © 2025 Avv. Marcello Stanca - Firenze, Italia. All Rights Reserved.
// Hoc contractum, pars SystemSolidary, ab Auctore Marcello Stanca ad solam Caritas Internationalis (MCMLXXVI) usum conceditur.
// (This smart contract, part of the Solidary System, is granted for free use to Caritas Internationalis only (1976) by the author, Marcello Stanca.)

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../core_justice/RefundManager.sol";

contract SolidaryComix_DoubleStar is
    Initializable,
    ERC1155Upgradeable,
    ERC1155SupplyUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    RefundManager
{
    uint256 public constant FT_COMIX_ID = 0;
    uint256 public constant NFT_PASS_ID = 1;

    uint256 public feePercent;
    address public charityWallet;

    event ComixDonation(address indexed user, uint256 amount);
    
    // Economic Parameters
    uint256 public constant NFT_MINT_PRICE = 0.001 ether; // NFT minting price in ETH
    uint256 public constant MINT_PRICE_COMIX = 10 * 10**18; // Alternative price: 10 COMIX tokens
    uint256 public constant AIRDROP_AMOUNT = 100 * 10**18; // 100 COMIX airdrop per NFT
    uint256 public constant HOURLY_LOTTERY_PRIZE = 100 * 10**18; // 100 COMIX hourly lottery prize
    uint256 public constant DONATION_PERCENTAGE = 250; // 2.5% donation percentage (250 basis points)

    // Economic parameters access functions
    function getEconomicParams() public pure returns (
        uint256 nftPrice,
        uint256 comixPrice,
        uint256 airdropAmount,
        uint256 lotteryPrize,
        uint256 donationPercent
    ) {
        return (
            NFT_MINT_PRICE,
            MINT_PRICE_COMIX,
            AIRDROP_AMOUNT,
            HOURLY_LOTTERY_PRIZE,
            DONATION_PERCENTAGE
        );
    }

    function getNftMintPrice() public pure returns (uint256) {
        return NFT_MINT_PRICE;
    }

    function getAirdropAmount() public pure returns (uint256) {
        return AIRDROP_AMOUNT;
    }

    function getLotteryPrize() public pure returns (uint256) {
        return HOURLY_LOTTERY_PRIZE;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address /* initialOwner */, // Managed by RefundManager
        address _charityWallet,
        uint256 _feePercent,
        address _creatorWallet,
        address _solidaryWallet,
        uint256 _refundDeadline,
        uint256 _initialThreshold
    ) public initializer {
        // Initialize ERC1155 first, then RefundManager
        __ERC1155_init(""); // Initialize ERC1155 with empty URI
        __RefundManager_init(_creatorWallet, _solidaryWallet, _refundDeadline, _initialThreshold);

        // RefundManager includes: Ownable, ReentrancyGuard, UUPS
        // Business logic preserved
        // UUPS harmonization - Initializers centralized in RefundManager

        require(_charityWallet != address(0), "Invalid charity wallet");
        charityWallet = _charityWallet;
        feePercent = _feePercent;
    }

    function purchaseAccess() external payable nonReentrant {
        _recordContribution(msg.sender, msg.value); // Record user contribution
        uint256 ftValue = (msg.value * 49) / 100; // Calculate FT value (49% of payment)
        _mint(msg.sender, NFT_PASS_ID, 1, ""); // Mint NFT pass
        uint256 comixPrice = 0.01 ether; // COMIX token price
        uint256 amountComixToMint = ftValue / comixPrice; // Calculate COMIX amount to mint
        _mint(msg.sender, FT_COMIX_ID, amountComixToMint, ""); // Mint COMIX tokens
    }

    // Override _update function for transfer logic
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        // First: Execute original transfer logic
        super._update(from, to, ids, values);

        // Then: Apply fees (only for transfers between wallets)
        if (from != address(0) && to != address(0) && feePercent > 0) {
            for (uint256 i = 0; i < ids.length; ++i) {
                if (ids[i] == FT_COMIX_ID) { // Only apply fees to COMIX token transfers
                    uint256 currentBalance = balanceOf(from, ids[i]);
                    if (currentBalance > 0) {
                        uint256 fee = (values[i] * feePercent) / 100; // Calculate fee amount
                        if (fee > 0 && fee <= currentBalance) {
                            // Transfer fee to charity wallet
                            _safeTransferFrom(from, charityWallet, ids[i], fee, "");
                            emit ComixDonation(from, fee); // Emit donation event
                        }
                    }
                }
            }
        }
    }

    // Admin functions
    function setFeePercent(uint256 newFee) external onlyOwner {
        require(newFee <= 10, "Fee too high"); // Maximum fee 10%
        feePercent = newFee;
    }

    function updateCharityWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "Invalid wallet"); // Validate new wallet address
        charityWallet = newWallet;
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri); // Update token metadata URI
    }

    // ERC165 interface support
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // UUPS upgrade authorization
    function _authorizeUpgrade(address newImplementation)
        internal
        virtual
        override(UUPSUpgradeable, RefundManager)
        onlyOwner
    {
        // Upgrade authorization logic
    }
}
