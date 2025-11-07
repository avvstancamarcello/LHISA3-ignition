// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICosmicsMintable {
    function mint(address to, uint256 amount) external;
}

contract AirdropWhitelist is Ownable {
    event Claimed(address indexed user, uint256 amount);
    event Whitelisted(address indexed user, uint256 amount);
    event Removed(address indexed user);
    event MintModeChanged(bool enabled);
    event TokenChanged(address token);

    mapping(address => uint256) public allocation;
    mapping(address => bool) public claimed;
    address public token;
    bool public mintOnClaim;

    constructor(address _token, bool _mintOnClaim) {
        token = _token;
        mintOnClaim = _mintOnClaim;
    }

    function setToken(address _token) external onlyOwner {
        token = _token;
        emit TokenChanged(_token);
    }

    function setMintMode(bool enabled) external onlyOwner {
        mintOnClaim = enabled;
        emit MintModeChanged(enabled);
    }

    function addToWhitelist(address[] calldata accounts, uint256[] calldata amounts) external onlyOwner {
        require(accounts.length == amounts.length, "Length mismatch");
        for (uint256 i = 0; i < accounts.length; i++) {
            allocation[accounts[i]] = amounts[i];
            emit Whitelisted(accounts[i], amounts[i]);
        }
    }

    function removeFromWhitelist(address account) external onlyOwner {
        allocation[account] = 0;
        emit Removed(account);
    }

    function claim() external {
        require(allocation[msg.sender] > 0, "No allocation");
        require(!claimed[msg.sender], "Already claimed");
        claimed[msg.sender] = true;
        uint256 amount = allocation[msg.sender];
        if (mintOnClaim) {
            ICosmicsMintable(token).mint(msg.sender, amount);
        } else {
            require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
        }
        emit Claimed(msg.sender, amount);
    }
}
