// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca Lawyer - ITALY Florence

import "../interfaces/IERC1363.sol";
import "../interfaces/IERC1363Receiver.sol";
import "../interfaces/IERC1363Spender.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC1363Mock is ERC20, IERC1363 {
    constructor() ERC20("Mock1363", "M1363") {}

    function transferAndCall(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        require(
            IERC1363Receiver(to).onTransferReceived(msg.sender, msg.sender, value, "") ==
                IERC1363Receiver.onTransferReceived.selector,
            "ERC1363: receiver rejected tokens"
        );
        return true;
    }

    function approveAndCall(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        require(
            IERC1363Spender(spender).onApprovalReceived(msg.sender, value, "") ==
                IERC1363Spender.onApprovalReceived.selector,
            "ERC1363: spender rejected approval"
        );
        return true;
    }
    
    // Implement missing interface functions
    function transferAndCall(address to, uint256 value, bytes calldata data) external override returns (bool) {
        _transfer(msg.sender, to, value);
        require(
            IERC1363Receiver(to).onTransferReceived(msg.sender, msg.sender, value, data) ==
                IERC1363Receiver.onTransferReceived.selector,
            "ERC1363: receiver rejected tokens"
        );
        return true;
    }
    
    function approveAndCall(address spender, uint256 value, bytes calldata data) external override returns (bool) {
        _approve(msg.sender, spender, value);
        require(
            IERC1363Spender(spender).onApprovalReceived(msg.sender, value, data) ==
                IERC1363Spender.onApprovalReceived.selector,
            "ERC1363: spender rejected approval"
        );
        return true;
    }

    // Relaxed versions for testing
    function transferAndCallRelaxed(address to, uint256 value, bytes memory data) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approveAndCallRelaxed(address spender, uint256 value, bytes memory data) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
}
