// scripts/force-initialize-solidary-comics.ts
import { ethers } from "hardhat";

async function main() {
  console.log("🔄 FORCE Initializing SolidaryComics...");
  console.log("🚨 ATTENZIONE: Contratto deployato ma non inizializzato!");
  
  const comicsAddress = "0x59ca56c7eB17E165aBcC7193218544A7F6101851";
  const admin = "0x514efc732cc787fb19c90d01edaf5a79d7e2385d";
  const charityWallet = "0x514efc732cc787fb19c90d01edaf5a79d7e2385d";
  
  const SolidaryComics = await ethers.getContractFactory("SolidaryComics_StellaDoppia");
  const comics = SolidaryComics.attach(comicsAddress);
  
  console.log("🎯 Attempting FORCE initialization...");
  console.log("📍 Contract:", comicsAddress);
  console.log("👑 Setting owner to:", admin);
  console.log("💝 Setting charity to:", charityWallet);
  console.log("🎯 Setting threshold to: 50 ETH");
  
  try {
    const tx = await comics.initialize(
      admin,                    // initialOwner
      charityWallet,            // _charityWallet
      5,                        // _feePercent
      admin,                    // _creatorWallet
      charityWallet,            // _solidaryWallet
      Math.floor(Date.now() / 1000) + 86400 * 30, // 30 giorni
      ethers.parseEther("50"),  // 50 ETH
      {
        gasLimit: 1500000       // ⬆️ Gas molto alto per sicurezza
      }
    );
    
    console.log("⏳ Waiting for initialization transaction...");
    const receipt = await tx.wait();
    console.log("✅ INITIALIZATION SUCCESS! Block:", receipt.blockNumber);
    console.log("📋 Transaction hash:", receipt.hash);
    
    // Verifica i nuovi valori
    console.log("\n🧪 Verifying new values...");
    const newOwner = await comics.owner();
    console.log("👑 New Owner:", newOwner);
    
    const newThreshold = await comics.globalSuccessThreshold();
    console.log("🎯 New Threshold:", ethers.formatEther(newThreshold), "ETH");
    
    const newCharity = await comics.charityWallet();
    console.log("💝 New Charity:", newCharity);
    
    console.log("\n🎉 SOLIDARYCOMICS NOW FULLY OPERATIONAL!");
    console.log("🌕 Luna Comica - FINALMENTE In Orbita!");
    
  } catch (error: any) {
    console.log("❌ FORCE initialization failed:", error.message);
    
    if (error.reason) {
      console.log("🔍 Reason:", error.reason);
    }
    
    // Se fallisce, deployiamo nuovo UUPS
    console.log("\n🚀 Fallback: Deploying new UUPS proxy...");
  }
}

main().catch(console.error);
