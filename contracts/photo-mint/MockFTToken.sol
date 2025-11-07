// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

contract MockFTToken {
    mapping(address => uint256) public balanceOf;
    function mint(address to, uint256 amount) public { balanceOf[to] += amount; }
    function burn(address from, uint256 amount) public { balanceOf[from] -= amount; }
    function approve(address, uint256) public pure returns (bool) { return true; }
}
