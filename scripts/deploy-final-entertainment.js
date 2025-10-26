const { ethers } = require("hardhat");

async function main() {
  console.log("🎪 DEPLOY VotoGratis Entertainment - VERSIONE FINALE");
  
  try {
    // IL NOME CORRETTO È "VotoGratis" (dal file .sol)
    console.log("🔍 Caricando contratto: VotoGratis");
    const VotoGratis = await ethers.getContractFactory("VotoGratis");
    
    console.log("🚀 Avvio deploy...");
    const votoGratis = await VotoGratis.deploy();
    
    console.log("⏳ Waiting for deployment...");
    await votoGratis.waitForDeployment();
    
    const address = await votoGratis.getAddress();
    console.log("🎉 DEPLOY COMPLETATO!");
    console.log("✅ VotoGratis Entertainment deployed to:", address);
    console.log("🔗 Explorer: https://basescan.org/address/" + address);
    
    return address;
    
  } catch (error) {
    console.log("❌ ERRORE durante il deploy:");
    console.log("   💥", error.message);
    
    if (error.message.includes("artifact")) {
      console.log("   🔧 Suggerimento: Verifica il nome del contratto nel file .sol");
    }
    throw error;
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
