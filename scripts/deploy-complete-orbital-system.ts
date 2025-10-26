// scripts/deploy-complete-orbital-system.ts
import { ethers, upgrades } from "hardhat";

async function main() {
  console.log("🌌 Deploying Complete Orbital System with Aircraft Carrier...");
  console.log("🚢 Includendo Portaerei Logica RefundManager!");
  
  const deployed = {};
  
  // 1. 🚢 PRIMA LA PORTAEREI (RefundManager)
  console.log("\n🚢 FASE 1: Deploy Portaerei Logica...");
  try {
    const RefundManager = await ethers.getContractFactory("RefundManager");
    const refundManager = await upgrades.deployProxy(
      RefundManager,
      [
        "0x514efc732cc787fb19c90d01edaf5a79d7e2385d", // creator
        "0x514efc732cc787fb19c90d01edaf5a79d7e2385d", // solidary
        Math.floor(Date.now() / 1000) + 86400 * 180, // 180 giorni
        ethers.parseEther("1000") // 1000 ETH
      ],
      { kind: 'uups', initializer: '__RefundManager_init' }
    );
    
    await refundManager.waitForDeployment();
    deployed["RefundManager"] = await refundManager.getAddress();
    console.log("✅ RefundManager:", deployed["RefundManager"]);
  } catch (error) {
    console.log("❌ RefundManager error:", error.message);
  }

  // 2. 🎨 POI SOLIDARY COMICS
  console.log("\n🎨 FASE 2: Deploy Solidary Comics...");
  try {
    const SolidaryComics = await ethers.getContractFactory("SolidaryComics_StellaDoppia");
    const solidaryComics = await SolidaryComics.deploy();
    await solidaryComics.waitForDeployment();
    deployed["SolidaryComics"] = await solidaryComics.getAddress();
    console.log("✅ SolidaryComics:", deployed["SolidaryComics"]);
  } catch (error) {
    console.log("❌ SolidaryComics error:", error.message);
  }

  // 3. 🪐 INFINE GLI ALTRI MODULI ORBITALI
  const orbitalModules = [
    { name: "PlanetNFTFactory", role: "🪐 Factory Pianeti" },
    { name: "ModuleRouter", role: "🔄 Router Sistema" },
    { name: "ImpactLogger", role: "📊 Logger Impatto" },
    { name: "ReputationManager", role: "⭐ Sistema Reputazione" }
  ];

  console.log("\n🪐 FASE 3: Deploy Moduli Orbitali...");
  for (const module of orbitalModules) {
    try {
      const Factory = await ethers.getContractFactory(module.name);
      const instance = await Factory.deploy();
      await instance.waitForDeployment();
      deployed[module.name] = await instance.getAddress();
      console.log(`✅ ${module.name}: ${deployed[module.name]}`);
    } catch (error) {
      console.log(`❌ ${module.name}: ${error.message}`);
    }
  }

  console.log("\n🎉 SISTEMA ORBITALE COMPLETO CON PORTAEREI!");
  console.log("🚢 RefundManager attivo per operazioni di recupero!");
  console.log("🌍 From Arctic to Japan - RECOVERY READY!");
  
  return deployed;
}

main().catch(console.error);
