// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

contract MockOracle {
    uint256 public rate = 100;
    function setRate(uint256 r) public { rate = r; }
    function getFTConversionRate() external view returns (uint256) { return rate; }
}
