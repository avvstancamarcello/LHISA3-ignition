// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Interfacce corrette per i contratti deployati
interface IOceanMangaNFT {
    function mint(address to, uint256 id, uint256 amount, bytes calldata data) external;
}

interface ILunaComicsFT {
    // Mint fungible tokens (non-payable in actual CosmixProtocolToken)
    function mint(address to, uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function mintWithEth(address to, uint256 minOut) external payable returns (uint256 out);
}

// Interfacce per conformità con i contratti esistenti
interface ISolidaryOrchestratorReadable {
    function nftPlanetContract() external view returns (address);
    function ftSatelliteContract() external view returns (address);
}

interface ISolidaryOrchestratorReadableFT {
    function nftPlanetContract() external view returns (address);
    function ftSatelliteContract() external view returns (address);
}

interface IAdvancedSwapper {
    function swap(address tokenIn, uint256 amountIn, address tokenOut) external;
}

contract OceanMangaOrchestrator is OwnableUpgradeable, ReentrancyGuardUpgradeable, ISolidaryOrchestratorReadable, ISolidaryOrchestratorReadableFT {
    IOceanMangaNFT public oceanMangaNFT;
    ILunaComicsFT public lunaComicsFT;
    
    address public creator;
    address public charityFund;

    // Percentuali (base 1000 per maggiore precisione)
    uint256 public constant NFT_SHARE = 550;      // 55%
    uint256 public constant FT_SHARE = 450;       // 45%
    uint256 public constant CREATOR_SHARE = 25;   // 2.5%
    uint256 public constant CHARITY_SHARE = 25;   // 2.5%
    
    // Ratio FT per ETH (es: 1 ETH = 1000 FT)
    uint256 public ftRatio = 1000;
    
    // ID NFT incrementale
    uint256 public nextTokenId = 1;

    // Optional external swapper + protocol token (same as lunaComicsFT address)
    address public swapper; // AdvancedSwapper contract
    mapping(address => bool) public authorizedSwapTokens; // allowlist for swap targets
    uint256 public maxFtPerMint; // cap for ftAmount path

    // New event for extended combo mint
    event MintedCombo(
        address indexed recipient,
        uint256 indexed tokenId,
        uint256 netFT,
        uint256 creatorRoyalty,
        uint256 charityRoyalty
    );

    event PhotoMinted(
        address indexed user, 
        string tokenURI, 
        uint256 ethPaid, 
        uint256 nftId, 
        uint256 ftAmount
    );

    constructor(
        address _nft,
        address _ft,
        address _creator,
        address _charity
    ) {
        _transferOwnership(msg.sender);
        oceanMangaNFT = IOceanMangaNFT(_nft);
        lunaComicsFT = ILunaComicsFT(_ft);
        creator = _creator;
        charityFund = _charity;
    }

    /**
     * @notice Legacy mint function (kept for backward compatibility)
     * Uses ETH value to derive FT amount via token's payable mint (mintWithEth). No swap, recipient = msg.sender.
     */
    function mintPhotoCombo(string memory tokenURI) external payable nonReentrant {
        require(msg.value > 0, "Payment required");

        uint256 total = msg.value;
        uint256 currentTokenId = nextTokenId++;
        
        // Calcola le quote
        // uint256 nftAmount = (total * NFT_SHARE) / 1000; // Unused for now
        uint256 ftAmount = (total * FT_SHARE) / 1000;
        uint256 creatorAmount = (total * CREATOR_SHARE) / 1000;
        uint256 charityAmount = (total * CHARITY_SHARE) / 1000;

        // 1. Mint NFT (ERC1155: id, amount, data)
        oceanMangaNFT.mint(msg.sender, currentTokenId, 1, abi.encode(tokenURI));

        // 2. Mint FT derivando dall'ETH: usiamo il token payable mintWithEth per legare costo a payment
        uint256 preBal = IERC20(address(lunaComicsFT)).balanceOf(address(this));
        // Minta su orchestrator, poi trasferisce net a user e royalties a creator/charity
        uint256 mintedGross = lunaComicsFT.mintWithEth{value: ftAmount}(address(this), 0);
        uint256 postBal = IERC20(address(lunaComicsFT)).balanceOf(address(this));
        require(postBal - preBal == mintedGross, "Mint mismatch");
        uint256 creatorRoyalty = (mintedGross * CREATOR_SHARE) / 1000;
        uint256 charityRoyalty = (mintedGross * CHARITY_SHARE) / 1000;
        uint256 netFT = mintedGross - creatorRoyalty - charityRoyalty;
        IERC20(address(lunaComicsFT)).transfer(msg.sender, netFT);
        IERC20(address(lunaComicsFT)).transfer(creator, creatorRoyalty);
        IERC20(address(lunaComicsFT)).transfer(charityFund, charityRoyalty);

        // 3. Distribuisci pagamenti
        uint256 remaining = total - ftAmount - creatorAmount - charityAmount;
        if (remaining > 0) {
            // Il resto rimane nel contratto orchestratore
        }
        payable(creator).transfer(creatorAmount);
        payable(charityFund).transfer(charityAmount);

        emit PhotoMinted(msg.sender, tokenURI, total, currentTokenId, netFT);
    }

    /**
     * @notice Extended mint function allowing explicit FT amount and optional immediate swap.
     * @param tokenURI Metadata reference for the NFT.
     * @param recipient Address receiving the NFT and net FT tokens.
     * @param ftAmount Total FT tokens to be minted (gross before royalties).
     * @param swapAmount Portion of net FT to swap immediately ( <= netFT ).
     * @param swapTargetToken Target token address for the swap (must be supported by swapper).
     * Requirements:
     *  - msg.value >= 0.0001 ether (min mint fee)
     *  - ftAmount > 0 and ftAmount - 2*royalty > 0
     *  - swapAmount <= netFT
     *  - swapper set if swapAmount > 0
     * Royalties (2.5% + 2.5%) are minted directly to creator & charity.
     */
    function mintPhotoCombo(
        string memory tokenURI,
        address recipient,
        uint256 ftAmount,
        uint256 swapAmount,
        address swapTargetToken
    ) external payable nonReentrant {
        require(msg.value >= 0.0001 ether, "Insufficient minting fee");
        require(recipient != address(0), "Invalid recipient");
        // If ftAmount path is used, limit it. If zero, we'll derive from ETH.
        if (ftAmount > 0) {
            require(maxFtPerMint == 0 || ftAmount <= maxFtPerMint, "ftAmount>cap");
        }

        uint256 mintedGross;
        uint256 creatorRoyalty;
        uint256 charityRoyalty;
        uint256 netFT;

        // Decide mint path: (A) from ETH via mintWithEth or (B) explicit ftAmount
        if (ftAmount == 0) {
            // Derive FT from ETH share
            uint256 ethForFT = (msg.value * FT_SHARE) / 1000;
            uint256 preBalFT = IERC20(address(lunaComicsFT)).balanceOf(address(this));
            mintedGross = lunaComicsFT.mintWithEth{value: ethForFT}(address(this), 0);
            uint256 postBalFT = IERC20(address(lunaComicsFT)).balanceOf(address(this));
            require(postBalFT - preBalFT == mintedGross, "MintWithEth mismatch");
        } else {
            // Standard mint path (not linked to ETH). Mint to contract then distribute.
            mintedGross = ftAmount;
            lunaComicsFT.mint(address(this), mintedGross);
        }

        creatorRoyalty = (mintedGross * CREATOR_SHARE) / 1000; // 2.5%
        charityRoyalty = (mintedGross * CHARITY_SHARE) / 1000; // 2.5%
        netFT = mintedGross - creatorRoyalty - charityRoyalty;
        require(netFT > 0, "Net FT zero");
        require(swapAmount <= netFT, "Swap > netFT");
        if (swapAmount > 0) {
            require(swapper != address(0), "Swapper not set");
            require(swapTargetToken != address(0), "swapTargetToken=0");
            require(authorizedSwapTokens[swapTargetToken], "swapTarget not allowed");
        }
        if (swapAmount > 0) {
            require(swapper != address(0), "Swapper not set");
            require(swapTargetToken != address(0), "swapTargetToken=0");
        }

        uint256 currentTokenId = nextTokenId++;
    // Mint NFT to recipient
        oceanMangaNFT.mint(recipient, currentTokenId, 1, abi.encode(tokenURI));

    // Distribute FT: royalties
    IERC20(address(lunaComicsFT)).transfer(creator, creatorRoyalty);
    IERC20(address(lunaComicsFT)).transfer(charityFund, charityRoyalty);

        // Mint net FT: if swap required, split mint between recipient and orchestrator
        if (swapAmount > 0) {
            uint256 toHolder = netFT - swapAmount; // portion that remains with recipient
            IERC20(address(lunaComicsFT)).transfer(recipient, toHolder);
            // Approve and perform swap
            lunaComicsFT.approve(swapper, swapAmount);
            uint256 outPre = IERC20(swapTargetToken).balanceOf(address(this));
            IAdvancedSwapper(swapper).swap(address(lunaComicsFT), swapAmount, swapTargetToken);
            uint256 outPost = IERC20(swapTargetToken).balanceOf(address(this));
            uint256 amountOut = outPost - outPre;
            require(amountOut > 0, "No swap output");
            IERC20(swapTargetToken).transfer(recipient, amountOut);
        } else {
            IERC20(address(lunaComicsFT)).transfer(recipient, netFT);
        }

        emit MintedCombo(recipient, currentTokenId, netFT, creatorRoyalty, charityRoyalty);
    }

    function setSwapper(address _swapper) external onlyOwner {
        swapper = _swapper;
    }

    function setAuthorizedSwapToken(address token, bool allowed) external onlyOwner {
        authorizedSwapTokens[token] = allowed;
    }

    function setMaxFtPerMint(uint256 cap) external onlyOwner {
        maxFtPerMint = cap;
    }
    
    // Implementazione delle interfacce
    function nftPlanetContract() external view override(ISolidaryOrchestratorReadable, ISolidaryOrchestratorReadableFT) returns (address) {
        return address(oceanMangaNFT);
    }
    
    function ftSatelliteContract() external view override(ISolidaryOrchestratorReadable, ISolidaryOrchestratorReadableFT) returns (address) {
        return address(lunaComicsFT);
    }

    function setFTRatio(uint256 _newRatio) external onlyOwner {
        ftRatio = _newRatio;
    }

    function setAddresses(
        address _creator,
        address _charity
    ) external onlyOwner {
        creator = _creator;
        charityFund = _charity;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}