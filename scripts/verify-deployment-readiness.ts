// scripts/verify-deployment-readiness.ts
import { ethers } from "hardhat";

async function main() {
  console.log("🔍 Verifying Deployment Readiness...");
  
  const contractsToDeploy = [
    "SolidaryComics_StellaDoppia",
    "PlanetNFTFactory", 
    "ModuleRouter",
    "ImpactLogger",
    "ReputationManager",
    "UniversalMultiChainOrchestrator"
  ];

  console.log("📋 Checking contract compilation...");
  
  for (const contractName of contractsToDeploy) {
    try {
      await ethers.getContractFactory(contractName);
      console.log(`✅ ${contractName}: COMPILABLE`);
    } catch (error) {
      console.log(`❌ ${contractName}: ${error.message}`);
    }
  }

  console.log("\n🎯 Deployment Readiness Check Complete!");
}

main().catch(console.error);
