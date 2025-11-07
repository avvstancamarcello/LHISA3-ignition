const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deployer address:", deployer.address);

  // Address del proxy SolidaryHub su Base
  const proxyAddress = "0x0c415b3c53727fd1Ab02D3EC337aDB4b2399277e";

  // Deploy new implementation
  console.log("Deploying new implementation...");
  const SolidaryHub = await ethers.getContractFactory("SolidarySystemHub");
  const newImpl = await SolidaryHub.deploy();
  await newImpl.waitForDeployment();
  const newImplAddress = await newImpl.getAddress();
  console.log("New implementation deployed at:", newImplAddress);

  // Ora chiama upgradeTo sul proxy
  const proxy = await ethers.getContractAt("SolidarySystemHub", proxyAddress);
  console.log("Upgrading proxy...");
  await proxy.upgradeTo(newImplAddress);
  console.log("Upgraded");

  // Ora chiama emergencyGrantRoles
  console.log("Granting roles...");
  await proxy.emergencyGrantRoles();
  console.log("Roles granted");

  // Ora inizializza l'ecosistema
  console.log("Initializing ecosystem...");
  const orchestrator = "0xf7d5dED91d12FF8A9F08888dF2Da1E680af0F9FB"; // OrchestratorV2
  const nftPlanet = "0xE82CCA2448C87c4B07e489714eC16684209D7D58"; // OceanMangaNFT
  const ftSatellite = "0x3E01ecA61f0ac7A25dF2142D3C036292808E0B91"; // LunaComicsFT
  const metrics = "0x6dAD7a431C8527fEAB2940149688980689c14e5e"; // Metrics
  const reputationManager = "0x89CfA5418326f22999Ac2265aA48D173A4Da6f86"; // ReputationManager
  const impactLogger = "0x60da14D6a614720bcDC5EEE28d0D2E510fac836F"; // ImpactLogger
  const moduleRouter = "0xB86e162e3008D0dDFB5bB2e3BA27144AE5D9edBe"; // Router
  const multiChainOrchestrator = "0xf7d5dED91d12FF8A9F08888dF2Da1E680af0F9FB"; // OrchestratorV2
  const moduleUtils = "0x0000000000000000000000000000000000000000"; // Placeholder

  await proxy.initializeEcosystem(
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
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });