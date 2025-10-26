import { ethers } from "hardhat";

async function main() {
  console.log("🎯 Using existing SolidaryComics deployment...");
  
  const existingAddress = "0x59ca56c7eB17E165aBcC7193218544A7F6101851";
  
  const SolidaryComics = await ethers.getContractFactory("SolidaryComics_StellaDoppia");
  const comics = SolidaryComics.attach(existingAddress);
  
  try {
    console.log("📊 Checking existing contract...");
    
    const owner = await comics.owner();
    console.log("✅ Owner:", owner);
    
    const threshold = await comics.globalSuccessThreshold();
    console.log("✅ Threshold:", ethers.formatEther(threshold), "ETH");
    
    const charity = await comics.charityWallet();
    console.log("✅ Charity Wallet:", charity);
    
    console.log("🎉 Existing SolidaryComics is WORKING!");
    console.log("📍 Address:", existingAddress);
    console.log("🌕 Using existing deployment for Lucca Comics!");
    
    return existingAddress;
    
  } catch (error) {
    console.log("❌ Existing contract not usable:", error.message);
    console.log("🚀 We need to deploy a new UUPS proxy");
    return null;
  }
}

main().catch(console.error);
