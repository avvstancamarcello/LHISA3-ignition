require("dotenv").config();
const { ethers, upgrades } = require("hardhat");
const { parseUnits } = require("ethers");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log('Deploying with wallet:', deployer.address);
  const owner = "0x8495B3f7493263685fFcDA2602fFfF349d4eD3B8";
  const charity = "0xf84eb8B95407f04Dee8fF9acaC0e0AC7231bAb2A";
  const creator = "0x514efc732cc787fb19c90d01edaf5a79d7e2385d";
  const ftSupply = parseUnits("10000000", 18); // 10.000.000
  // Variabili sensibili, NON esporre in log/output pubblici
  const NFT_STORAGE_API_KEY = process.env.NFT_STORAGE_API_KEY;
  const VITE_PINATA_API_KEY = process.env.VITE_PINATA_API_KEY;
  const VITE_METAMASK_API_KEY = process.env.VITE_METAMASK_API_KEY;
  const VITE_PINATA_SECRET_KEY = process.env.VITE_PINATA_SECRET_KEY;
  const PINATA_GATEWAY = process.env.PINATA_GATEWAY;

  // Esempio di utilizzo variabili sensibili (solo per chiamate interne, MAI loggare!)
  // Esempio: const pinataApiKey = VITE_PINATA_API_KEY;
  // ...existing code...
  // Usa il nome qualificato per evitare conflitti tra artefatti
  const OceanMangaNFT = await ethers.getContractFactory("contracts/OceanMangaNFT.sol:OceanMangaNFT");
  const oceanMangaNFT = await upgrades.deployProxy(OceanMangaNFT, [owner], { initializer: "initialize" });
  await oceanMangaNFT.waitForDeployment();
  console.log("OceanMangaNFT (upgradeable) deployed:", oceanMangaNFT.address);


  // Deploy CosmixProtocolToken (upgradeable)
  const CosmixProtocolToken = await ethers.getContractFactory("CosmixProtocolToken");
  const ft = await upgrades.deployProxy(CosmixProtocolToken, [owner, ftSupply, charity], { initializer: "initialize" });
  await ft.waitForDeployment();
  console.log("CosmixProtocolToken (upgradeable) deployed:", ft.address);


  // Deploy ReputationManager (upgradeable)
  const ReputationManager = await ethers.getContractFactory("ReputationManager");
  const rep = await upgrades.deployProxy(ReputationManager, [owner], { initializer: "initialize" });
  await rep.waitForDeployment();
  console.log("ReputationManager (upgradeable) deployed:", rep.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
