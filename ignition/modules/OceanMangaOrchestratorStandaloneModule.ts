import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const OceanMangaOrchestratorStandaloneModule = buildModule("OceanMangaOrchestratorStandalone", (m) => {
  
  // Indirizzi dei contratti già deployati su Polygon
  const nftAddress = "0xBeC80BF2ef21597c0b40106D8eF70d03fEE44C79"; // OceanMangaNFT
  const ftAddress = "0xE82CCA2448C87c4B07e489714eC16684209D7D58";  // LunaComicsFT
  const creatorAddress = "0x8495B3f7493263685fFcDA2602fFfF349d4eD3B8"; // Deploy address as creator
  const charityAddress = "0xB19Ee3A16554d339111028fe3a76fEE5AE45E8A3";  // SponsorVault as charity
  
  // Deploy OceanMangaOrchestrator con configurazioni specifiche per Polygon
  const orchestrator = m.contract("OceanMangaOrchestrator", [
    nftAddress,
    ftAddress, 
    creatorAddress,
    charityAddress
  ], {
    id: "OceanMangaOrchestratorStandalone"
  });

  return { 
    orchestrator
  };
});

export default OceanMangaOrchestratorStandaloneModule;