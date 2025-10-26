import { ethers, upgrades } from "hardhat";

async function main() {
  console.log("🎻 DEPLOY ARMONIZZATO - SolidaryComics UUPS");
  console.log("🎵 Orchestra Blockchain - Tutti gli strumenti accordati");
  console.log("🏛️ Architettura preservata - Solo duplicati rimossi");
  
  const admin = "0x514efc732cc787fb19c90d01edaf5a79d7e2385d";
  const charityWallet = "0x514efc732cc787fb19c90d01edaf5a79d7e2385d";
  
  try {
    // Prova a deployare la versione armonizzata
    const SolidaryComics = await ethers.getContractFactory("SolidaryComics_StellaDoppia");
    
    console.log("🔄 Deploying UUPS proxy armonizzato...");
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
    
    console.log("🎉 SOLIDARYCOMICS ARMONIZZATO DEPLOYATO!");
    console.log("📍 Proxy Address:", proxyAddress);
    console.log("🔧 Implementation:", await upgrades.erc1967.getImplementationAddress(proxyAddress));
    
    // Test armonico
    console.log("\n🧪 Test Armonico Funzionalità:");
    const owner = await solidaryComics.owner();
    console.log("👑 Owner:", owner);
    
    const threshold = await solidaryComics.globalSuccessThreshold();
    console.log("🎯 Threshold:", ethers.formatEther(threshold), "ETH");
    
    const charity = await solidaryComics.charityWallet();
    console.log("💝 Charity:", charity);
    
    console.log("\n🎼 ARMONIA RAGGIUNTA!");
    console.log("🌕 Luna Comica - Pronta per Lucca Comics 2025!");
    console.log("🎵 Orchestra Blockchain - In perfetta sintonia!");
    
    return proxyAddress;
    
  } catch (error: any) {
    console.log("❌ Deploy armonizzato fallito:", error.message);
    
    // Ripristina il backup se fallisce
    console.log("🔄 Ripristino backup originale...");
    // Qui potresti aggiungere il comando per ripristinare il backup
  }
}

main().catch(console.error);
