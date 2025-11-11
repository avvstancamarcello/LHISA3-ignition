// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AdvancedSwapper is Ownable {
    address public orchestrator;
    address public protocolToken;
    mapping(address => bool) public supportedTokens;
    mapping(address => uint256) public minAmounts;
    mapping(address => uint8) public tokenDecimals;

    event TokenSupported(address indexed token, uint256 minAmount, string symbol, uint8 decimals);
    event Swapped(address indexed user, address indexed tokenIn, uint256 amountIn, address indexed tokenOut, uint256 amountOut);

    constructor(address _orchestrator, address _protocolToken) {
        orchestrator = _orchestrator;
        protocolToken = _protocolToken;
    }

    function addSupportedToken(address token, uint256 minAmount, string memory /*symbol*/, uint8 decimals) external onlyOwner {
        supportedTokens[token] = true;
        minAmounts[token] = minAmount;
        tokenDecimals[token] = decimals;
        emit TokenSupported(token, minAmount, "", decimals);
    }

    function swap(address tokenIn, uint256 amountIn, address tokenOut) external {
        require(supportedTokens[tokenIn], "Token in not supported");
        require(supportedTokens[tokenOut], "Token out not supported");
        require(amountIn >= minAmounts[tokenIn], "Amount too low");
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        // For demo: 1:1 swap, replace with real logic
        IERC20(tokenOut).transfer(msg.sender, amountIn);
        emit Swapped(msg.sender, tokenIn, amountIn, tokenOut, amountIn);
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }
}
