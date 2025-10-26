// scripts/deploy_metrics.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  const admin = deployer.address;

  // Se l'orchestrator non è ancora deployato, usa address zero e chiamerai setOrchestrator dopo
  const orchestratorAddress = "0x0000000000000000000000000000000000000000";
  const initialInterval = 3600; // 1 hour default

  console.log("Deploying SolidaryMetrics with admin:", admin);

  const Metrics = await ethers.getContractFactory("SolidaryMetrics");
  const metrics = await upgrades.deployProxy(Metrics, [admin, orchestratorAddress, initialInterval], { initializer: "initialize" });

  await metrics.deployed();
  console.log("SolidaryMetrics deployed to:", metrics.address);
  console.log("Admin (DEFAULT_ADMIN_ROLE):", admin);
  console.log("SNAPSHOT_CREATOR_ROLE initially granted to admin as well.");
}

main().catch((e) => { console.error(e); process.exit(1); });
