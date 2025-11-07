const { ethers } = require("hardhat");

async function main() {
  try {
    console.log("Starting script...");
    const [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);

    // Address del proxy SolidaryHub su Polygon
    const proxyAddress = "0x221be674D710e9AaD3129407538a5D84B5BF3FDb";
    console.log("Proxy address:", proxyAddress);

    // Deploy new implementation
    console.log("Getting contract factory...");
    const SolidaryHub = await ethers.getContractFactory("SolidarySystemHub");
    console.log("Deploying new implementation...");
    const newImpl = await SolidaryHub.deploy({
      maxFeePerGas: ethers.parseUnits("300", "gwei"),
      maxPriorityFeePerGas: ethers.parseUnits("50", "gwei"),
    });
    console.log("Waiting for deployment...");
    await newImpl.waitForDeployment();
    const newImplAddress = await newImpl.getAddress();
    console.log("New implementation deployed at:", newImplAddress);

    // Ora chiama upgradeTo sul proxy
    console.log("Getting proxy contract...");
    const proxy = await ethers.getContractAt("SolidarySystemHub", proxyAddress);
    console.log("Upgrading proxy...");
    const upgradeTx = await proxy.upgradeTo(newImplAddress);
    console.log("Upgrade tx sent:", upgradeTx.hash);
    await upgradeTx.wait();
    console.log("Upgraded successfully");

    // Ora chiama emergencyGrantRoles
    console.log("Granting roles...");
    const grantTx = await proxy.emergencyGrantRoles();
    console.log("Grant tx sent:", grantTx.hash);
    await grantTx.wait();
    console.log("Roles granted");

    // Ora inizializza l'ecosistema
    console.log("Initializing ecosystem...");
    const orchestrator = "0x89CfA5418326f22999Ac2265aA48D173A4Da6f86"; // OrchestratorV2
    const nftPlanet = "0xBeC80BF2ef21597c0b40106D8eF70d03fEE44C79"; // OceanMangaNFT
    const ftSatellite = "0xE82CCA2448C87c4B07e489714eC16684209D7D58"; // LunaComicsFT
    const metrics = "0xf7d5dED91d12FF8A9F08888dF2Da1E680af0F9FB"; // Metrics
    const reputationManager = "0xd9f12bC43287BC98392C52C16E12c27e55E0fF0b"; // ReputationManager
    const impactLogger = "0x3E01ecA61f0ac7A25dF2142D3C036292808E0B91"; // ImpactLogger
    const moduleRouter = "0x0c415b3c53727fd1Ab02D3EC337aDB4b2399277e"; // Router
    const multiChainOrchestrator = "0x89CfA5418326f22999Ac2265aA48D173A4Da6f86"; // OrchestratorV2
    const moduleUtils = "0x0000000000000000000000000000000000000000"; // Placeholder

    const initTx = await proxy.initializeEcosystem(
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
    console.log("Init tx sent:", initTx.hash);
    await initTx.wait();
    console.log("Ecosystem initialized successfully");

    // Test funzioni view
    console.log("Testing view functions...");
    const stats = await proxy.getEcosystemStatistics();
    console.log("Ecosystem Statistics:");
    console.log("Total Modules:", stats[0].toString());
    console.log("Active Modules:", stats[1].toString());
    console.log("Total Calls:", stats[2].toString());
    console.log("Total Emergencies:", stats[3].toString());
    console.log("Total CIDs:", stats[4].toString());

    const health = await proxy.getEcosystemHealth();
    console.log("Ecosystem Health - Overall Score:", health.overallScore.toString());

    const state = await proxy.getEnhancedEcosystemState();
    console.log("Ecosystem State - Total Users:", state.totalUsers.toString());

    console.log("Script completed successfully!");
  } catch (error) {
    console.error("Error in script:", error);
    process.exit(1);
  }
}

main();