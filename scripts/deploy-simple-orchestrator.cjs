const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("🚀 Deploy OceanMangaOrchestrator SIMPLE (standalone)");
  console.log("📍 Deployer:", deployer.address);
  console.log("🌐 Network: Base Mainnet");
  
  try {
    // Deploy simple orchestrator
    console.log("\n🎭 Deploying OceanMangaOrchestratorSimple...");
    const OrchestratorSimple = await ethers.getContractFactory("OceanMangaOrchestratorSimple");
    
    const orchestrator = await OrchestratorSimple.deploy(
      deployer.address, // creator
      deployer.address  // charity
    );
    
    await orchestrator.waitForDeployment();
    const address = await orchestrator.getAddress();
    
    console.log("✅ Simple Orchestrator deployed:", address);
    console.log("🔗 BaseScan:", `https://basescan.org/address/${address}`);
    
    // Test the contract
    console.log("\n🧪 Testing contract...");
    const creator = await orchestrator.creator();
    const charity = await orchestrator.charityFund();
    console.log("  Creator:", creator);
    console.log("  Charity:", charity);
    
    const deploymentInfo = {
      network: "base",
      chainId: 8453,
      timestamp: new Date().toISOString(),
      OrchestratorSimple: address,
      note: "Standalone version - no external NFT/FT contracts needed"
    };
    
    const fs = require('fs');
    fs.writeFileSync('BASE_SIMPLE_ORCHESTRATOR.json', JSON.stringify(deploymentInfo, null, 2));
    
    console.log("\n🎉 SIMPLE ORCHESTRATOR READY!");
    console.log("💡 This version stores NFT metadata internally");
    console.log("🔧 Update React app to use:", address);
    
  } catch (error) {
    console.error("❌ Deploy failed:", error.message);
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });