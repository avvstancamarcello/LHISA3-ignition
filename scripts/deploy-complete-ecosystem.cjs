// scripts/deploy-complete-ecosystem.cjs
require('dotenv').config();
const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("🌍 DEPLOY ECOSISTEMA COMPLETO DI GAMIFICAZIONE...");
  
  // 1. DEPLOY CONTRATTO PRINCIPALE
  console.log("🚀 Deploy MareaMangaNFT...");
  const MareaMangaNFT = await ethers.getContractFactory("MareaMangaNFT");
  const mareaManga = await upgrades.deployProxy(MareaMangaNFT, [], { 
    kind: 'uups',
    timeout: 180000
  });
  
  await mareaManga.deployed();
  console.log("✅ MareaMangaNFT deployato:", mareaManga.address);

  // 2. CONFIGURAZIONE INIZIALE
  console.log("⚙️ Configurazione ecosistema...");
  
  // Attiva porti commerciali
  await mareaManga.activatePort(0, 7 * 24 * 60 * 60); // Porto Lucca - 7 giorni
  await mareaManga.activatePort(1, 14 * 24 * 60 * 60); // Tokyo - 14 giorni
  
  // Registra certificatori autorizzati
  const certifierAddress = "0x..."; // Indirizzo certificatore reale
  await mareaManga.registerCertifier(certifierAddress, "CartaCert International License #12345");
  
  console.log("🎉 ECOSISTEMA COMPLETAMENTE CONFIGURATO!");
  console.log("🌐 Frontend pronto all'integrazione!");
}

main().catch((error) => {
  console.error("❌ ERRORE:", error);
  process.exitCode = 1;
});
