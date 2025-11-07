// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library SolidaryModuleOrchestrationUtils {
    function calculateSuccessRate(uint256 previousRate, bool success) internal pure returns (uint256) {
        if (success) {
            return (previousRate * 99 + 100) / 100;
        } else {
            return (previousRate * 99) / 100;
        }
    }

    function encodeInactiveModule() internal pure returns (bytes memory) {
        return abi.encode("Module inactive");
    }
}
