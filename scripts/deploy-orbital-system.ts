// scripts/deploy-orbital-system.ts
import { ethers } from "hardhat";

async function main() {
  console.log("🌌 Deploying Solidary Orbital System...");
  console.log("🪐 From Arctic to Tierra del Fuego - Global Observatory Activated!");
  
  const contracts = [
    {
      name: "PlanetNFTFactory",
      factory: "PlanetNFTFactory",
      role: "🪐 Factory dei Pianeti Orbitali"
    },
    {
      name: "SolidaryComics", 
      factory: "SolidaryComics_StellaDoppia",
      role: "🌕 Satellite Lunare Iconico"
    },
    {
      name: "ModuleRouter",
      factory: "ModuleRouter",
      role: "🔄 Router del Sistema Solare"
    },
    {
      name: "ImpactLogger",
      factory: "ImpactLogger", 
      role: "📊 Logger dell'Impatto Globale"
    }
  ];

  const deployed = {};
  
  for (const contract of contracts) {
    console.log(`\n🚀 Deploying ${contract.name}...`);
    console.log(`   ${contract.role}`);
    
    try {
      const Factory = await ethers.getContractFactory(contract.factory);
      const instance = await Factory.deploy();
      await instance.waitForDeployment();
      const address = await instance.getAddress();
      
      deployed[contract.name] = address;
      console.log(`✅ ${contract.name} deployed to: ${address}`);
      
    } catch (error) {
      console.log(`❌ Error deploying ${contract.name}: ${error.message}`);
    }
  }
  
  console.log("\n🎉 Solidary Orbital System Deployed!");
  console.log("🌍 Observatory Network: FROM ARCTIC TO JAPAN!");
  
  return deployed;
}

main().catch(console.error);
