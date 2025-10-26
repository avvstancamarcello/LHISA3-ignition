const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  const admin = deployer.address;

  const nftAddr = "0x0000000000000000000000000000000000000000"; // set dopo il deploy
  const ftAddr  = "0x0000000000000000000000000000000000000000"; // set dopo il deploy

  const Orchestrator = await ethers.getContractFactory("Orchestrator");
  const orch = await upgrades.deployProxy(Orchestrator, [admin, nftAddr, ftAddr], { initializer: "initialize" });
  await orch.deployed();

  console.log("Orchestrator deployed to:", orch.address);
}

main().catch((e) => { console.error(e); process.exit(1); });
