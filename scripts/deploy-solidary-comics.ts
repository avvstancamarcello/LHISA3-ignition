// scripts/deploy-solidary-comics.ts
import { ethers } from "hardhat";

async function main() {
  console.log("🎨 Deploying SolidaryComics - The Iconic Orbital Satellite...");
  console.log("🌕 Inceptio Lunae Comicorum - Via ad Lucca Comics 2025!");
  console.log("🚀 Transistor Logico-Psicologico Activatus!");
  
  const admin = "0x514efc732cc787fb19c90d01edaf5a79d7e2385d";
  const charityWallet = "0x514efc732cc787fb19c90d01edaf5a79d7e2385d";
  
  // Deploy del contratto iconico
  const SolidaryComics = await ethers.getContractFactory("SolidaryComics_StellaDoppia");
  const solidaryComics = await SolidaryComics.deploy();
  
  await solidaryComics.waitForDeployment();
  const comicsAddress = await solidaryComics.getAddress();
  
  console.log("✅ SolidaryComics deployed to:", comicsAddress);
  
  // Initialize con parametri per Lucca Comics
  console.log("🔄 Initializing for Lucca Comics 2025...");
  const tx = await solidaryComics.initialize(
    admin,           // initialOwner
    charityWallet,   // charityWallet  
    5,               // 5% fee per competitività
    admin,           // creatorWallet
    charityWallet,   // solidaryWallet
    Math.floor(Date.now() / 1000) + 86400 * 30, // 30 giorni deadline
    ethers.parseEther("50") // 50 ETH threshold (più accessibile)
  );
  
  await tx.wait();
  
  console.log("🎉 SolidaryComics initialized successfully!");
  console.log("🌕 Luna Comica in Orbita - Sistema Terra-Luna Attivato!");
  
  return comicsAddress;
}

main().catch(console.error);
