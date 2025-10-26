// scripts/debug-solidary-comics.ts
import { ethers } from "hardhat";

async function main() {
  const comicsAddress = "0x59ca56c7eB17E165aBcC7193218544A7F6101851";
  
  console.log("🔍 Debugging SolidaryComics deployment...");
  
  // Verifica che il contratto esista
  const code = await ethers.provider.getCode(comicsAddress);
  console.log("Contract deployed:", code !== "0x" ? "✅ YES" : "❌ NO");
  
  if (code !== "0x") {
    try {
      // Prova a leggere valori senza initialize
      const contract = await ethers.getContractAt("SolidaryComics_StellaDoppia", comicsAddress);
      
      console.log("📋 Contract basic info:");
      try {
        const owner = await contract.owner();
        console.log("   Owner:", owner);
      } catch (e) {
        console.log("   ❌ Cannot read owner - likely not initialized");
      }
      
      try {
        const threshold = await contract.globalSuccessThreshold();
        console.log("   Threshold:", ethers.formatEther(threshold), "ETH");
      } catch (e) {
        console.log("   ❌ Cannot read threshold");
      }
      
    } catch (error) {
      console.log("❌ Error interacting with contract:", error.message);
    }
  }
}

main().catch(console.error);
