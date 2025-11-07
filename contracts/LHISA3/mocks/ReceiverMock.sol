// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IERC1363Receiver.sol";
import "../interfaces/IERC1363Spender.sol";

contract ReceiverMock is IERC1363Receiver, IERC1363Spender {
    event Received(address operator, address from, uint256 value, bytes data);
    event Approved(address owner, uint256 value, bytes data);

    function onTransferReceived(address operator, address from, uint256 value, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        emit Received(operator, from, value, data);
        return IERC1363Receiver.onTransferReceived.selector;
    }

    function onApprovalReceived(address owner, uint256 value, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        emit Approved(owner, value, data);
        return IERC1363Spender.onApprovalReceived.selector;
    }
}
