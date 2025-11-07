const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Orchestrators Suite", function () {
  let mintLockModule, postLockModule, orchestratorMintLock, orchestratorPostLock, owner, user;

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();
    // Deploy MintLockModule
    const MintLock = await ethers.getContractFactory("MintLockModule");
    mintLockModule = await MintLock.deploy();
    await mintLockModule.waitForDeployment();
    // Deploy PostLockDistributionModule
    const PostLock = await ethers.getContractFactory("PostLockDistributionModule");
    postLockModule = await PostLock.deploy();
    await postLockModule.waitForDeployment();
    // Deploy OrchestratorMintLock
    const OrchestratorMintLock = await ethers.getContractFactory("OceanMangaOrchestratorMintLock");
    orchestratorMintLock = await OrchestratorMintLock.deploy(await mintLockModule.getAddress());
    await orchestratorMintLock.waitForDeployment();
    // Deploy OrchestratorPostLock
    const OrchestratorPostLock = await ethers.getContractFactory("OceanMangaOrchestratorPostLock");
    orchestratorPostLock = await OrchestratorPostLock.deploy(await postLockModule.getAddress());
    await orchestratorPostLock.waitForDeployment();
  });

  it("should mint and lock NFT via orchestrator", async function () {
    await expect(orchestratorMintLock.connect(user).mintPhoto("ipfs://testuri", { value: 1000 }))
      .to.not.be.reverted;
    // In un test reale, verificheresti eventi e stato del modulo
  });

  it("should check NFT lock status via orchestrator", async function () {
    const locked = await orchestratorMintLock.isLocked(1);
    expect(locked).to.be.a("boolean");
  });

  it("should distribute post-lock via orchestrator", async function () {
    await expect(orchestratorPostLock.distribute(1)).to.not.be.reverted;
    // In un test reale, verificheresti eventi e saldo destinatari
  });

  // Puoi aggiungere test per liquidazione, ruoli, residue withdrawal, ecc.
});
