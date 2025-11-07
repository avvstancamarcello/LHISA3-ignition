// Rename this file to integration-ft-nft-orchestrator.spec.js for best compatibility with Hardhat/Mocha.
// If you see errors, ensure all imports use require() and no TypeScript-specific syntax remains.
import hre from "hardhat";
const { ethers, upgrades } = hre;
import { expect } from "chai";

describe("Local Integration Test: FT/NFT/Orchestrator", function () {
  let nft, ft, orchestrator, deployer, user;

  before(async () => {
    [deployer, user] = await ethers.getSigners();

    // Deploy NFT (upgradeable proxy)
    const NFTFactory = await ethers.getContractFactory("OceanMangaNFT");
    nft = await upgrades.deployProxy(NFTFactory, [
      deployer.address,
      "ipfs://baseuri/{id}.json",
      "OceanManga",
      "OCEAN",
      deployer.address,
      500
    ], { kind: 'uups' });

    // Deploy FT (upgradeable proxy)
    const FTFactory = await ethers.getContractFactory("CosmixSolidaryToken");
    ft = await upgrades.deployProxy(FTFactory, [deployer.address, ethers.parseEther("1000000"), deployer.address], { kind: 'uups' });

    // Deploy Orchestrator (upgradeable proxy)
    const OrchestratorFactory = await ethers.getContractFactory("OceanMangaOrchestratorV3");
    orchestrator = await upgrades.deployProxy(OrchestratorFactory, [await nft.getAddress(), await ft.getAddress(), deployer.address, deployer.address], { kind: 'uups' });

    // Grant MINTER_ROLE to orchestrator on NFT
    const NFT_MINTER_ROLE = await nft.MINTER_ROLE();
    await nft.grantRole(NFT_MINTER_ROLE, await orchestrator.getAddress());

    // Grant MINTER_ROLE to orchestrator on FT
    const FT_MINTER_ROLE = await ft.MINTER_ROLE();
    await ft.grantRole(FT_MINTER_ROLE, await orchestrator.getAddress());
  });

  it("should mint NFT+FT combo and lock NFT", async () => {
    const tokenURI = "ipfs://testuri";
    const mintTx = await orchestrator.connect(user).mintPhotoCombo(tokenURI, { value: ethers.parseEther("1") });
    await mintTx.wait();

    // Check NFT minted
    expect(await nft.balanceOf(user.address, 1)).to.equal(1);
    // Check FT minted
    expect(await ft.balanceOf(user.address)).to.be.gt(0);
    // Check NFT lock
    expect(await orchestrator.isNFTLocked(1)).to.equal(true);
  });

  it("should allow owner to pause and unpause orchestrator", async () => {
    await orchestrator.pause();
    await expect(
      orchestrator.connect(user).mintPhotoCombo("ipfs://testuri", { value: ethers.parseEther("1") })
    ).to.be.revertedWith("Pausable: paused");
    await orchestrator.unpause();
  });

  it("should allow lock period to be changed", async () => {
    await orchestrator.setLockPeriod(60 * 24 * 60 * 60); // 60 days
    expect(await orchestrator.lockPeriod()).to.equal(60 * 24 * 60 * 60);
  });

  // Add more tests for integration with modules as needed
});
