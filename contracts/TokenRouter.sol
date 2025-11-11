// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenRouter is Ownable {
    address public orchestrator;
    address public protocolToken;

    event Routed(address indexed user, address indexed token, uint256 amount, string action);

    constructor(address _orchestrator, address _protocolToken) {
        orchestrator = _orchestrator;
        protocolToken = _protocolToken;
    }

    function routeTokens(address token, uint256 amount, string memory action) external {
        require(token != address(0), "Token address required");
        require(amount > 0, "Amount must be positive");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit Routed(msg.sender, token, amount, action);
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }
}
