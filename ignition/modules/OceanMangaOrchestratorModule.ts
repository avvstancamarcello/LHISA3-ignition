import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const OceanMangaOrchestratorModule = buildModule("OceanMangaOrchestratorModule", (m) => {
  // Indirizzi dei contratti deployati
  const oceanMangaNFTAddress = "0xBeC80BF2ef21597c0b40106D8eF70d03fEE44C79"; // Polygon
  const lunaComicsFTAddress = "0xE82CCA2448C87c4B07e489714eC16684209D7D58";  // Polygon
  
  // Wallet creator e charity (sostituisci con i tuoi indirizzi)
  const creatorWallet = "0x514EFc732Cc787fb19C90d01eDaf5a79d7E2385D";
  const charityWallet = "0x514EFc732Cc787fb19C90d01eDaf5a79d7E2385D"; // Cambia con indirizzo charity

  const orchestrator = m.contract("OceanMangaOrchestrator", [
    oceanMangaNFTAddress,
    lunaComicsFTAddress,
    creatorWallet,
    charityWallet
  ]);

  return {
    orchestrator,
  };
});

export default OceanMangaOrchestratorModule;