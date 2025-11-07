import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const OceanMangaOrchestratorModule = buildModule("OceanMangaOrchestratorModule", (m) => {
  // Indirizzi dei contratti deployati su Polygon (Chain 137)
  const oceanMangaNFTAddress = "0xBeC80BF2ef21597c0b40106D8eF70d03fEE44C79";
  const lunaComicsFTAddress = "0xE82CCA2448C87c4B07e489714eC16684209D7D58";
  
  // Wallet creator e charity
  const creatorWallet = "0x514EFc732Cc787fb19C90d01eDaf5a79d7E2385D";
  const charityWallet = "0x514EFc732Cc787fb19C90d01eDaf5a79d7E2385D";

  const orchestrator = m.contract("OceanMangaOrchestrator", [
    oceanMangaNFTAddress,
    lunaComicsFTAddress,
    creatorWallet,
    charityWallet
  ], {
    // Opzioni per Polygon - tempi di attesa più lunghi
    confirmations: 5, // Attendi 5 conferme
    timeout: 300000,  // Timeout 5 minuti
  });

  return {
    orchestrator,
  };
});

export default OceanMangaOrchestratorModule;