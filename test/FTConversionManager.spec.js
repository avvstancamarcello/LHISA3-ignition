const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("FTConversionManager", function () {
  let manager, owner, user, tokenA, tokenB, oracle;

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();
    // Deploy dummy oracle
    const Oracle = await ethers.getContractFactory("MockOracle");
    oracle = await Oracle.deploy();
    await oracle.waitForDeployment();
    // Deploy dummy FT tokens
    const FTToken = await ethers.getContractFactory("MockFTToken");
    tokenA = await FTToken.deploy();
    tokenB = await FTToken.deploy();
    await tokenA.waitForDeployment();
    await tokenB.waitForDeployment();
    // Deploy manager
    const Manager = await ethers.getContractFactory("FTConversionManager");
    manager = await Manager.deploy();
    await manager.waitForDeployment();
    await manager.setPriceOracle(await oracle.getAddress());
  });

  it("should set and trigger rate alert", async function () {
    await manager.connect(user).setRateAlert(100);
    await oracle.setRate(120);
    await expect(manager.checkRateAlert(user.address)).to.emit(manager, "RateAlertTriggered").withArgs(user.address, 120);
  });

  it("should convert between FT tokens and record history", async function () {
    await tokenA.mint(user.address, 100);
    // No ERC20 approve logic needed for mock
    await expect(manager.connect(user).convertFTtoFT(await tokenA.getAddress(), await tokenB.getAddress(), 50)).to.emit(manager, "FTConverted");
    const history = await manager.getConversionHistory(user.address);
    expect(history.length).to.equal(1);
    expect(history[0].from).to.equal(await tokenA.getAddress());
    expect(history[0].to).to.equal(await tokenB.getAddress());
    expect(history[0].amount.toString()).to.equal("50");
  });

  it("should notify FT mint and allow conversion with quote", async function () {
    await manager.notifyFTMint(user.address, 100);
    const [rate, estimatedGasCost] = await manager.connect(user).getConversionQuote.staticCall(50);
    expect(rate.toString()).to.equal((await oracle.getFTConversionRate()).toString());
  });
});

// Dummy contracts for testing
const { Contract } = require("ethers");
const { deployMockContract } = require("@ethereum-waffle/mock-contract");

// Solidity mocks
// pragma solidity ^0.8.21;
// contract MockOracle {
//     uint256 public rate = 100;
//     function setRate(uint256 r) public { rate = r; }
//     function getFTConversionRate() external view returns (uint256) { return rate; }
// }
// contract MockFTToken {
//     mapping(address => uint256) public balanceOf;
//     function mint(address to, uint256 amount) public { balanceOf[to] += amount; }
//     function burn(address from, uint256 amount) public { balanceOf[from] -= amount; }
//     function approve(address, uint256) public pure returns (bool) { return true; }
// }
