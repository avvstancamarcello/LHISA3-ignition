/* scripts/deploy_universal_orchestrator_v2.js
 * Deploy proxy UUPS di UniversalMultiChainOrchestratorV2
 *
 * Requisiti:
 * - hardhat
 * - @openzeppelin/hardhat-upgrades
 * - dotenv (opzionale per variabili d'ambiente)
 *
 * Env supportate (opzionali, altrimenti address(0)):
 *   ADMIN
 *   SOLIDARY_HUB
 *   REPUTATION_MANAGER
 *   ALGORAND_BRIDGE
 *   ETH_POLYGON_BRIDGE
 *   BBTM_INTERFACE
 *   OCEAN_MANGA_NFT
 *   LUNA_COMICS_FT
 *   SOLIDARY_METRICS
 */

require("dotenv").config();
const { ethers, upgrades } = require("hardhat");

function addrOrZero(v) {
  return v && v.trim() !== "" ? v.trim() : "0x0000000000000000000000000000000000000000";
}

async function main() {
  const [deployer] = await ethers.getSigners();

  // admin: se non impostato, usa il deployer
  const admin = addrOrZero(process.env.ADMIN || deployer.address);

  // riferimenti (tutti opzionali/collegabili dopo con setSolidaryEcosystem / updateBridgeContracts)
  const solidaryHub        = addrOrZero(process.env.SOLIDARY_HUB);
  const reputationManager  = addrOrZero(process.env.REPUTATION_MANAGER);
  const algorandBridge     = addrOrZero(process.env.ALGORAND_BRIDGE);
  const ethPolygonBridge   = addrOrZero(process.env.ETH_POLYGON_BRIDGE);
  const bbtmInterface      = addrOrZero(process.env.BBTM_INTERFACE);
  const oceanMangaNFT      = addrOrZero(process.env.OCEAN_MANGA_NFT);
  const lunaComicsFT       = addrOrZero(process.env.LUNA_COMICS_FT);
  const solidaryMetrics    = addrOrZero(process.env.SOLIDARY_METRICS);

  console.log("== Deploy UniversalMultiChainOrchestratorV2 ==");
  console.log("Deployer:", deployer.address);
  console.log("Admin   :", admin);
  console.log("Refs (can be zero & wired later):");
  console.log({
    solidaryHub, reputationManager, algorandBridge, ethPolygonBridge, bbtmInterface,
    oceanMangaNFT, lunaComicsFT, solidaryMetrics
  });

  const Orchestrator = await ethers.getContractFactory("UniversalMultiChainOrchestratorV2");
  const orch = await upgrades.deployProxy(
    Orchestrator,
    [
      admin,
      solidaryHub,
      reputationManager,
      algorandBridge,
      ethPolygonBridge,
      bbtmInterface,
      oceanMangaNFT,
      lunaComicsFT,
      solidaryMetrics
    ],
    { initializer: "initialize", kind: "uups" }
  );

  await orch.deployed();
  console.log("UniversalMultiChainOrchestratorV2 (proxy) deployed at:", orch.address);

  // Implementation address (utile per audit/verify)
  const impl = await upgrades.erc1967.getImplementationAddress(orch.address);
  const adminProxy = await upgrades.erc1967.getAdminAddress(orch.address);
  console.log("Implementation:", impl);
  console.log("ProxyAdmin   :", adminProxy);

  // Suggerimento ruoli: sono già assegnati in initialize all'admin passato.
  // Eventuali role-grant aggiuntivi si fanno nello script di "wiring" successivo.
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
