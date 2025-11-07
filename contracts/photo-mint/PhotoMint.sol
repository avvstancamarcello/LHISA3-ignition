// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IMintableNFT {
    function mint(address to, string memory tokenURI) external;
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract PhotoMint is Ownable {
    IMintableNFT public nft;
    IERC20 public ft;
    address public creator;
    address public charityFund;

    uint256 public constant NFT_SHARE = 55;
    uint256 public constant FT_SHARE = 45;
    uint256 public constant CREATOR_SHARE = 25; // 2.5% of total
    uint256 public constant CHARITY_SHARE = 25; // 2.5% of total

    event PhotoMinted(address indexed to, string tokenURI, uint256 value);

    constructor(
        address _nft,
        address _ft,
        address _creator,
        address _charity
    ) Ownable() {
        nft = IMintableNFT(_nft);
        ft = IERC20(_ft);
        creator = _creator;
        charityFund = _charity;
    }

    function mintPhoto(string memory tokenURI) external payable {
        require(msg.value > 0, "Payment required");

        uint256 total = msg.value;

        // Calculate shares
        uint256 nftAmount = (total * NFT_SHARE) / 100;
        uint256 ftAmount = (total * FT_SHARE) / 100;
        uint256 creatorAmount = (total * CREATOR_SHARE) / 1000;
        uint256 charityAmount = (total * CHARITY_SHARE) / 1000;

        // Mint NFT
        nft.mint(msg.sender, tokenURI);

        // Distribute payments (assuming addresses are payable)
        payable(address(nft)).transfer(nftAmount);
        payable(address(ft)).transfer(ftAmount - creatorAmount - charityAmount);
        payable(creator).transfer(creatorAmount);
        payable(charityFund).transfer(charityAmount);

        emit PhotoMinted(msg.sender, tokenURI, total);
    }

    // Function to update charity fund after voting (admin only)
    function setCharityFund(address _charity) external onlyOwner {
        charityFund = _charity;
    }
}