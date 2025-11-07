// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca - Italy - Florence. Author and owner of the Solidary.it ecosystem and this smart contract.

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../SolidarySystemTokenRouter.sol";

interface ILunaComicsFT {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/**
 * @title LunaComicsAdvancedSwapper
 * @author Avv. Marcello Stanca
 * @notice Advanced token swapper for LunaComics FT with multi-token support on Base network
 * @dev Enables conversion between LUNA tokens and popular Base network tokens
 */
contract LunaComicsAdvancedSwapper is OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    
    ILunaComicsFT public lunaToken;
    SolidarySystemTokenRouter public router;
    
    // Supported tokens on Base network
    struct SupportedToken {
        IERC20Upgradeable token;
        uint256 conversionRate; // Rate in 1e18 precision (1e18 = 1:1 ratio)
        bool active;
        string symbol;
        uint8 decimals;
    }
    
    mapping(address => SupportedToken) public supportedTokens;
    address[] public tokenList;
    
    // Conversion fees (in basis points, 10000 = 100%)
    uint256 public conversionFeeBps; // 0.30% default fee, ora inizializzato nell'initializer
    uint256 public constant MAX_FEE_BPS = 500; // Max 5% fee
    
    // Fee collection
    address public feeCollector;
    uint256 public collectedFees;
    
    // Events
    event TokenSwapped(
        address indexed user,
        address indexed fromToken,
        address indexed toToken,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 fee
    );
    
    event TokenAdded(address indexed token, string symbol, uint256 rate);
    event TokenUpdated(address indexed token, uint256 newRate, bool active);
    event ConversionFeeUpdated(uint256 oldFee, uint256 newFee);
    event FeeCollectorUpdated(address oldCollector, address newCollector);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        address _lunaToken,
        address _router,
        address _feeCollector
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        lunaToken = ILunaComicsFT(_lunaToken);
        router = SolidarySystemTokenRouter(_router);
        feeCollector = _feeCollector;
        conversionFeeBps = 30; // 0.30% default fee

        // Initialize with popular Base network tokens
        _initializeBaseTokens();
    }
    // UUPS upgradeability authorization
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    function _initializeBaseTokens() internal {
        // ETH/WETH (Base network native)
        _addSupportedToken(
            address(0x4200000000000000000000000000000000000006), // WETH on Base
            1e18, // 1:1 with LUNA
            "WETH",
            18
        );
        
        // USDC on Base
        _addSupportedToken(
            address(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913), // USDC on Base
            1e12, // 1 LUNA = 0.000001 USDC (6 decimals)
            "USDC",
            6
        );
        
        // DAI on Base  
        _addSupportedToken(
            address(0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb), // DAI on Base
            1e15, // 1 LUNA = 0.001 DAI
            "DAI",
            18
        );
        
        // cbETH (Coinbase Wrapped ETH)
        _addSupportedToken(
            address(0x2Ae3F1Ec7F1F5012CFEab0185bfc7aa3cf0DEc22), // cbETH on Base
            1e18, // 1:1 with LUNA initially
            "cbETH",
            18
        );
    }
    
    /**
     * @notice Swap LUNA tokens for another supported token
     * @param targetToken Address of token to receive
     * @param lunaAmount Amount of LUNA tokens to swap
     * @param minAmountOut Minimum amount of target token to receive (slippage protection)
     */
    function swapLunaForToken(
        address targetToken,
        uint256 lunaAmount,
        uint256 minAmountOut
    ) external nonReentrant whenNotPaused {
        require(lunaAmount > 0, "Amount must be > 0");
        require(supportedTokens[targetToken].active, "Token not supported");
        require(lunaToken.balanceOf(msg.sender) >= lunaAmount, "Insufficient LUNA balance");
        
        SupportedToken memory tokenInfo = supportedTokens[targetToken];
        
        // Calculate conversion amount using router
        uint256 baseAmount = router.calculateConversionValue(lunaAmount, tokenInfo.conversionRate);
        
        // Calculate fee
        uint256 fee = (baseAmount * conversionFeeBps) / 10000;
        uint256 amountOut = baseAmount - fee;
        
        require(amountOut >= minAmountOut, "Slippage too high");
        require(tokenInfo.token.balanceOf(address(this)) >= amountOut, "Insufficient liquidity");
        
        // Burn LUNA tokens
        lunaToken.transferFrom(msg.sender, address(this), lunaAmount);
        
        // Transfer target token
        tokenInfo.token.transfer(msg.sender, amountOut);
        
        // Collect fee
        collectedFees += fee;
        
        emit TokenSwapped(msg.sender, address(lunaToken), targetToken, lunaAmount, amountOut, fee);
    }
    
    /**
     * @notice Swap supported token for LUNA tokens
     * @param sourceToken Address of token to swap from
     * @param tokenAmount Amount of source token to swap
     * @param minLunaOut Minimum LUNA amount to receive
     */
    function swapTokenForLuna(
        address sourceToken,
        uint256 tokenAmount,
        uint256 minLunaOut
    ) external nonReentrant whenNotPaused {
        require(tokenAmount > 0, "Amount must be > 0");
        require(supportedTokens[sourceToken].active, "Token not supported");
        
        SupportedToken memory tokenInfo = supportedTokens[sourceToken];
        require(tokenInfo.token.balanceOf(msg.sender) >= tokenAmount, "Insufficient token balance");
        
        // Calculate LUNA amount (reverse conversion)
        uint256 lunaAmount = (tokenAmount * 1e18) / tokenInfo.conversionRate;
        
        // Calculate fee in LUNA
        uint256 fee = (lunaAmount * conversionFeeBps) / 10000;
        uint256 lunaOut = lunaAmount - fee;
        
        require(lunaOut >= minLunaOut, "Slippage too high");
        
        // Transfer source token to contract
        tokenInfo.token.transferFrom(msg.sender, address(this), tokenAmount);
        
        // Mint LUNA tokens to user
        lunaToken.mint(msg.sender, lunaOut);
        
        // Collect fee (mint to fee collector)
        if (fee > 0) {
            lunaToken.mint(feeCollector, fee);
        }
        
        emit TokenSwapped(msg.sender, sourceToken, address(lunaToken), tokenAmount, lunaOut, fee);
    }
    
    /**
     * @notice Get quote for LUNA to token swap
     * @param targetToken Target token address
     * @param lunaAmount Amount of LUNA to swap
     * @return amountOut Amount of target token to receive
     * @return fee Fee amount in target token
     */
    function getQuoteLunaToToken(
        address targetToken,
        uint256 lunaAmount
    ) external view returns (uint256 amountOut, uint256 fee) {
        require(supportedTokens[targetToken].active, "Token not supported");
        
        SupportedToken memory tokenInfo = supportedTokens[targetToken];
        uint256 baseAmount = router.calculateConversionValue(lunaAmount, tokenInfo.conversionRate);
        fee = (baseAmount * conversionFeeBps) / 10000;
        amountOut = baseAmount - fee;
    }
    
    /**
     * @notice Get quote for token to LUNA swap
     * @param sourceToken Source token address
     * @param tokenAmount Amount of source token to swap
     * @return lunaOut Amount of LUNA to receive
     * @return fee Fee amount in LUNA
     */
    function getQuoteTokenToLuna(
        address sourceToken,
        uint256 tokenAmount
    ) external view returns (uint256 lunaOut, uint256 fee) {
        require(supportedTokens[sourceToken].active, "Token not supported");
        
        SupportedToken memory tokenInfo = supportedTokens[sourceToken];
        uint256 lunaAmount = (tokenAmount * 1e18) / tokenInfo.conversionRate;
        fee = (lunaAmount * conversionFeeBps) / 10000;
        lunaOut = lunaAmount - fee;
    }
    
    // Admin functions
    function addSupportedToken(
        address token,
        uint256 conversionRate,
        string memory symbol,
        uint8 decimals
    ) external onlyOwner {
        _addSupportedToken(token, conversionRate, symbol, decimals);
    }
    
    function _addSupportedToken(
        address token,
        uint256 conversionRate,
        string memory symbol,
        uint8 decimals
    ) internal {
        require(token != address(0), "Invalid token address");
        require(conversionRate > 0, "Invalid conversion rate");
        
        if (!supportedTokens[token].active && address(supportedTokens[token].token) == address(0)) {
            tokenList.push(token);
        }
        
        supportedTokens[token] = SupportedToken({
            token: IERC20Upgradeable(token),
            conversionRate: conversionRate,
            active: true,
            symbol: symbol,
            decimals: decimals
        });
        
        emit TokenAdded(token, symbol, conversionRate);
    }
    
    function updateTokenRate(address token, uint256 newRate) external onlyOwner {
        require(address(supportedTokens[token].token) != address(0), "Token not found");
        supportedTokens[token].conversionRate = newRate;
        emit TokenUpdated(token, newRate, supportedTokens[token].active);
    }
    
    function setTokenActive(address token, bool active) external onlyOwner {
        require(address(supportedTokens[token].token) != address(0), "Token not found");
        supportedTokens[token].active = active;
        emit TokenUpdated(token, supportedTokens[token].conversionRate, active);
    }
    
    function setConversionFee(uint256 newFeeBps) external onlyOwner {
        require(newFeeBps <= MAX_FEE_BPS, "Fee too high");
        uint256 oldFee = conversionFeeBps;
        conversionFeeBps = newFeeBps;
        emit ConversionFeeUpdated(oldFee, newFeeBps);
    }
    
    function setFeeCollector(address newCollector) external onlyOwner {
        require(newCollector != address(0), "Invalid collector");
        address oldCollector = feeCollector;
        feeCollector = newCollector;
        emit FeeCollectorUpdated(oldCollector, newCollector);
    }
    
    // Emergency functions
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            payable(owner()).transfer(amount);
        } else {
            IERC20Upgradeable(token).transfer(owner(), amount);
        }
    }
    
    // View functions
    function getSupportedTokens() external view returns (address[] memory) {
        return tokenList;
    }
    
    function getTokenInfo(address token) external view returns (SupportedToken memory) {
        return supportedTokens[token];
    }
    
    function getLiquidity(address token) external view returns (uint256) {
        if (token == address(lunaToken)) {
            return type(uint256).max; // LUNA can be minted
        }
        return supportedTokens[token].token.balanceOf(address(this));
    }
    
    // Receive ETH for liquidity
    receive() external payable {}
}