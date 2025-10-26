// scripts/deploy-solidary-comics-uups.ts
import { ethers, upgrades } from "hardhat";

async function main() {
  console.log("🎨 Deploying SolidaryComics as UUPS Proxy...");
  console.log("🌕 Inceptio Lunae Comicorum - Via ad Lucca Comics 2025!");
  console.log("🚀 UUPS Upgradeable - Transistor Logico-Psicologico!");
  
  const admin = "0x514efc732cc787fb19c90d01edaf5a79d7e2385d";
  const charityWallet = "0x514efc732cc787fb19c90d01edaf5a79d7e2385d";
  
  // Deploy come UUPS Proxy (CORRETTO!)
  const SolidaryComics = await ethers.getContractFactory("SolidaryComics_StellaDoppia");
  
  console.log("🔄 Deploying UUPS proxy...");
  const solidaryComics = await upgrades.deployProxy(
    SolidaryComics,
    [
      admin,           // initialOwner
      charityWallet,   // _charityWallet
      5,               // _feePercent
      admin,           // _creatorWallet
      charityWallet,   // _solidaryWallet
      Math.floor(Date.now() / 1000) + 86400 * 30, // _refundDeadline
      ethers.parseEther("50") // _initialThreshold
    ],
    {
      kind: 'uups',
      initializer: 'initialize'
    }
  );
  
  await solidaryComics.waitForDeployment();
  const proxyAddress = await solidaryComics.getAddress();
  
  console.log("✅ SolidaryComics UUPS Proxy deployed to:", proxyAddress);
  console.log("📋 Implementation address:", await upgrades.erc1967.getImplementationAddress(proxyAddress));
  
  // Test delle funzioni
  console.log("🧪 Testing UUPS proxy...");
  const owner = await solidaryComics.owner();
  console.log("👑 Owner:", owner);
  
  const threshold = await solidaryComics.globalSuccessThreshold();
  console.log("🎯 Threshold:", ethers.formatEther(threshold), "ETH");
  
  console.log("🎉 SolidaryComics UUPS DEPLOYED SUCCESSFULLY!");
  console.log("🌕 Luna Comica UUPS - In Orbita Upgradeable!");
  
  return proxyAddress;
}

main().catch(console.error);
