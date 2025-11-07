// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library SolidaryHealthUtils {
    function calculateHealthScore(uint256 totalUsers, uint256 totalImpact, uint256 globalReputation) internal pure returns (uint256) {
        // Logica di calcolo personalizzabile
        return totalUsers + totalImpact + globalReputation;
    }
}
