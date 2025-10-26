const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("SolidaryMetrics (upgradeable)", function () {
  let Metrics, metrics, admin, other;

  beforeEach(async function () {
    [admin, other] = await ethers.getSigners();
    Metrics = await ethers.getContractFactory("SolidaryMetrics");
    metrics = await upgrades.deployProxy(Metrics, [admin.address, ethers.constants.AddressZero, 1], { initializer: "initialize" });
    await metrics.deployed();
  });

  it("initialize sets admin and allows snapshot creation by admin", async function () {
    // admin has SNAPSHOT_CREATOR_ROLE
    const snapshotCreatorRole = await metrics.SNAPSHOT_CREATOR_ROLE();
    expect(await metrics.hasRole(snapshotCreatorRole, admin.address)).to.be.true;
  });

  it("createSnapshot fails for unauthorized", async function () {
    await expect(metrics.connect(other).createSnapshot("note")).to.be.reverted;
  });

  it("createSnapshot works for authorized and returns id", async function () {
    const tx = await metrics.connect(admin).createSnapshot("first");
    const receipt = await tx.wait();
    // event SnapshotCreated emitted; verify latestSnapshotId
    const id = await metrics.latestSnapshotId();
    expect(id).to.equal(1);

    const snap = await metrics.getSnapshot(1);
    expect(snap.id).to.equal(1);
    expect(snap.timestamp).to.be.greaterThan(0);
    expect(snap.cid).to.be.a('string');
  });

  it("registerExternalCID can update CID (admin only)", async function () {
    await metrics.connect(admin).createSnapshot("forcid");
    await expect(metrics.connect(other).registerExternalCID(1, "ipfs://QmTest")).to.be.reverted;
    await metrics.connect(admin).registerExternalCID(1, "ipfs://QmTest");
    const snap = await metrics.getSnapshot(1);
    expect(snap.cid).to.equal("ipfs://QmTest");
  });
});
