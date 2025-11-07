const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SolidarySystemReputationManager3 - Object Tracking", function () {
  let reputationManager, producer, buyer, thirdParty;
  const barcode = "TOY-2025-0001";
  const pin = "SECRET123";

  beforeEach(async function () {
    [producer, buyer, thirdParty] = await ethers.getSigners();
    const ReputationManager = await ethers.getContractFactory("SolidarySystemReputationManager3");
    reputationManager = await ReputationManager.deploy();
    await reputationManager.waitForDeployment();
  });

  it("should register, transfer, update status, message, and retrieve object info", async function () {
    // Register object
    const mintTx = await reputationManager.connect(producer).registerObject(barcode, pin, producer.address);
    const mintReceipt = await mintTx.wait();
    const mintHash = mintReceipt.logs[0].args.mintHash;
    expect(mintHash).to.be.a("string");

    // Transfer ownership
    await reputationManager.connect(producer).transferOwnership(mintHash, buyer.address);
    const infoAfterTransfer = await reputationManager.getObjectInfo(mintHash);
    expect(infoAfterTransfer.owner).to.equal(buyer.address);

    // Update status
    await reputationManager.connect(buyer).updateObjectStatus(mintHash, "in use");
    const infoAfterStatus = await reputationManager.getObjectInfo(mintHash);
    expect(infoAfterStatus.status).to.equal("in use");

    // Send message
    await reputationManager.connect(thirdParty).sendMessageToOwner(mintHash, "Vorrei acquistare il tuo giocattolo!");
    const messages = await reputationManager.getObjectMessages(mintHash);
    expect(messages.length).to.be.greaterThan(0);
    expect(messages[messages.length - 1].content).to.equal("Vorrei acquistare il tuo giocattolo!");

    // Update status to recycled
    await reputationManager.connect(buyer).updateObjectStatus(mintHash, "recycled");
    const infoAfterRecycle = await reputationManager.getObjectInfo(mintHash);
    expect(infoAfterRecycle.status).to.equal("recycled");
  });
});
