// scripts/deploy-refund-manager.ts
import { ethers, upgrades } from "hardhat";

async function main() {
  console.log("🚢 Deploying RefundManager - Logical Aircraft Carrier...");
  console.log("🛟 Portaerei Logica - Recupero Orbitale e Marittimo");
  console.log("🌌 Salvator Modulorum - In Spatio et Mari Aperto!");
  
  const admin = "0x514efc732cc787fb19c90d01edaf5a79d7e2385d";
  const creatorWallet = "0x514efc732cc787fb19c90d01edaf5a79d7e2385d";
  const solidaryWallet = "0x514efc732cc787fb19c90d01edaf5a79d7e2385d";
  
  // Deploy come UUPS Upgradeable (ESSENZIALE per una portaerei!)
  const RefundManager = await ethers.getContractFactory("RefundManager");
  
  console.log("🔄 Deploying UUPS proxy for aircraft carrier...");
  const refundManager = await upgrades.deployProxy(
    RefundManager,
    [
      creatorWallet,
      solidaryWallet, 
      Math.floor(Date.now() / 1000) + 86400 * 180, // 180 giorni deadline
      ethers.parseEther("1000") // 1000 ETH threshold globale
    ],
    {
      kind: 'uups',
      initializer: '__RefundManager_init'
    }
  );
  
  await refundManager.waitForDeployment();
  const proxyAddress = await refundManager.getAddress();
  
  console.log("✅ RefundManager Proxy deployed to:", proxyAddress);
  console.log("📋 Implementation address:", await upgrades.erc1967.getImplementationAddress(proxyAddress));
  console.log("👑 Captain (Owner):", admin);
  
  // Test delle funzioni di recupero
  console.log("🧪 Testing recovery systems...");
  const threshold = await refundManager.globalSuccessThreshold();
  console.log("🎯 Global Success Threshold:", ethers.formatEther(threshold), "ETH");
  
  const refundState = await refundManager.refundState();
  console.log("🛟 Refund State:", refundState === 0 ? "ACTIVE" : "OTHER");
  
  console.log("🎉 Logical Aircraft Carrier DEPLOYED!");
  console.log("🚢 Portaerei Logica - Pronta per Operazioni di Recupero!");
  
  return proxyAddress;
}

main().catch(console.error);
