require("dotenv").config();
const { ethers, upgrades } = require("hardhat");
const { parseUnits } = require("ethers");

async function main() {
  // Indirizzi dei contratti già deployati
  const owner = "0x8495B3f7493263685fFcDA2602fFfF349d4eD3B8";
  const cosmixToken = "0x419bd0C2FD55762058e6003Fe23A48f7E1839080"; // CosmixProtocolToken
  const oceanMangaNFT = "0x729f6225ED8fec69CdA7F98C2B5405C4Ce524b03"; // OceanMangaNFT
  // ReputationManager: da deployare, inserire qui l'indirizzo dopo deploy
  let reputationManager = process.env.REPUTATION_MANAGER_ADDRESS || "";

  // Deploy Impact Logger Orchestrator
  const ImpactLogger = await ethers.getContractFactory("contracts/core_infrastructure/SolidarySystemImpactLogger1.sol:SolidarySystemImpactLogger1");
  const impactLogger = await upgrades.deployProxy(
    ImpactLogger,
    [owner, cosmixToken, reputationManager, owner, owner], // admin, token, reputation, orchestrator, multiChainOrchestrator
    { initializer: "initialize" }
  );
  await impactLogger.waitForDeployment();
  console.log("ImpactLogger (orchestrator) deployed:", await impactLogger.getAddress());

  // Deploy Module Router Orchestrator
  const ModuleRouter = await ethers.getContractFactory("contracts/core_infrastructure/SolidarySystemModuleRouter2.sol:SolidarySystemModuleRouter2");
  const moduleRouter = await upgrades.deployProxy(
    ModuleRouter,
    [owner], // solo admin
    { initializer: "initialize" }
  );
  await moduleRouter.waitForDeployment();
  console.log("ModuleRouter (orchestrator) deployed:", await moduleRouter.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
