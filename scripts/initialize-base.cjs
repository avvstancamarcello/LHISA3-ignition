const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deployer address:", deployer.address);

  // Address del SolidaryHub deployato su Base
  const solidaryHubAddress = "0xec8b6066b99D4ED3dF0626bab463264354274b49";

  // Ottieni il contratto
  const SolidaryHub = await ethers.getContractAt("SolidarySystemHub", solidaryHubAddress);

  // Prima, grantare i ruoli se necessario
  console.log("Granting roles...");
  try {
    await SolidaryHub.emergencyGrantRoles();
    console.log("Roles granted");
  } catch (error) {
    console.log("Roles already granted or error:", error.message);
  }

  // Ora inizializzare l'ecosistema
  console.log("Initializing ecosystem...");
  const orchestrator = "0xf7d5dED91d12FF8A9F08888dF2Da1E680af0F9FB"; // OrchestratorV2
  const nftPlanet = "0xE82CCA2448C87c4B07e489714eC16684209D7D58"; // OceanMangaNFT
  const ftSatellite = "0x3E01ecA61f0ac7A25dF2142D3C036292808E0B91"; // LunaComicsFT
  const metrics = "0x6dAD7a431C8527fEAB2940149688980689c14e5e"; // Metrics
  const reputationManager = "0x89CfA5418326f22999Ac2265aA48D173A4Da6f86"; // ReputationManager
  const impactLogger = "0x60da14D6a614720bcDC5EEE28d0D2E510fac836F"; // ImpactLogger
  const moduleRouter = "0xB86e162e3008D0dDFB5bB2e3BA27144AE5D9edBe"; // Router
  const multiChainOrchestrator = "0xf7d5dED91d12FF8A9F08888dF2Da1E680af0F9FB"; // OrchestratorV2
  const moduleUtils = "0x0000000000000000000000000000000000000000"; // Placeholder, adjust if needed

  try {
    await SolidaryHub.initializeEcosystem(
      orchestrator,
      nftPlanet,
      ftSatellite,
      metrics,
      reputationManager,
      impactLogger,
      moduleRouter,
      multiChainOrchestrator,
      moduleUtils
    );
    console.log("Ecosystem initialized successfully");
  } catch (error) {
    console.log("Initialization failed:", error.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });