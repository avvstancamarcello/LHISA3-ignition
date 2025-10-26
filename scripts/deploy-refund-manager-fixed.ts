import { ethers, upgrades } from "hardhat";

async function main() {
  console.log("🚢 Deploying ConcreteRefundManager - Logical Aircraft Carrier...");
  console.log("🛟 Portaerei Logica Concreta - Recupero Orbitale e Marittimo!");
  console.log("🌌 Salvator Modulorum - In Spatio et Mari Aperto!");
  
  const admin = "0x514efc732cc787fb19c90d01edaf5a79d7e2385d";
  const creatorWallet = "0x514efc732cc787fb19c90d01edaf5a79d7e2385d";
  const solidaryWallet = "0x514efc732cc787fb19c90d01edaf5a79d7e2385d";
  
  // Deploy del CONTRATTO CONCRETO
  const ConcreteRefundManager = await ethers.getContractFactory("ConcreteRefundManager");
  
  console.log("🔄 Deploying UUPS proxy for concrete aircraft carrier...");
  const refundManager = await upgrades.deployProxy(
    ConcreteRefundManager,
    [
      creatorWallet,
      solidaryWallet, 
      Math.floor(Date.now() / 1000) + 86400 * 180, // 180 giorni deadline
      ethers.parseEther("1000") // 1000 ETH threshold globale
    ],
    {
      kind: 'uups',
      initializer: 'initialize'
    }
  );
  
  await refundManager.waitForDeployment();
  const proxyAddress = await refundManager.getAddress();
  
  console.log("✅ ConcreteRefundManager Proxy deployed to:", proxyAddress);
  console.log("📋 Implementation address:", await upgrades.erc1967.getImplementationAddress(proxyAddress));
  console.log("👑 Captain (Owner):", admin);
  
  // Test delle funzioni di recupero
  console.log("🧪 Testing recovery systems...");
  const threshold = await refundManager.globalSuccessThreshold();
  console.log("🎯 Global Success Threshold:", ethers.formatEther(threshold), "ETH");
  
  const refundState = await refundManager.refundState();
  console.log("🛟 Refund State:", refundState === 0 ? "ACTIVE" : "OTHER");
  
  console.log("🎉 Concrete Logical Aircraft Carrier DEPLOYED!");
  console.log("🚢 Portaerei Logica Concreta - Pronta per Operazioni di Recupero!");
  
  return proxyAddress;
}

main().catch(console.error);
