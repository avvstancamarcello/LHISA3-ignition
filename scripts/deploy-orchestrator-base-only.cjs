const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("🚀 Deploy SOLO OceanMangaOrchestrator su BASE");
  console.log("=" * 50);
  console.log("📍 Deployer:", deployer.address);
  console.log("🌐 Network: Base Mainnet");
  console.log("💎 BaseScan: https://basescan.org");
  
  // Useremo indirizzi mock per i contratti NFT/FT su Base
  // In una implementazione reale, deployeremmo prima NFT e FT
  const mockNFTAddress = "0x0000000000000000000000000000000000000001"; // Mock address
  const mockFTAddress = "0x0000000000000000000000000000000000000002";  // Mock address
  const creatorAddress = deployer.address;
  const charityAddress = deployer.address; // Temporary
  
  console.log("\n📋 Parametri Orchestrator:");
  console.log("  Mock NFT:", mockNFTAddress);
  console.log("  Mock FT:", mockFTAddress);
  console.log("  Creator:", creatorAddress);
  console.log("  Charity:", charityAddress);
  console.log("=" * 50);
  
  try {
    // Check balance and gas
    const balance = await ethers.provider.getBalance(deployer.address);
    const feeData = await ethers.provider.getFeeData();
    
    console.log("\n💰 Pre-Deploy Check:");
    console.log("  Balance:", ethers.formatEther(balance), "ETH");
    console.log("  Gas Price:", ethers.formatUnits(feeData.gasPrice, "gwei"), "gwei");
    
    // Estimate deployment cost
    const estimatedGas = BigInt(1500000); // Conservative estimate
    const estimatedCost = estimatedGas * feeData.gasPrice;
    
    console.log("  Estimated Gas:", estimatedGas.toString());
    console.log("  Estimated Cost:", ethers.formatEther(estimatedCost), "ETH");
    
    if (balance < estimatedCost) {
      console.log("❌ Insufficient balance for deployment");
      process.exit(1);
    }
    
    // Deploy OceanMangaOrchestrator
    console.log("\n🎭 Deploying OceanMangaOrchestrator...");
    const OceanMangaOrchestrator = await ethers.getContractFactory("OceanMangaOrchestrator");
    
    const orchestrator = await OceanMangaOrchestrator.deploy(
      mockNFTAddress,
      mockFTAddress,
      creatorAddress,
      charityAddress,
      {
        gasLimit: 1500000,    // Conservative gas limit
        gasPrice: feeData.gasPrice
      }
    );
    
    console.log("⏳ Transaction sent!");
    console.log("   Waiting for confirmation...");
    
    await orchestrator.waitForDeployment();
    const orchestratorAddress = await orchestrator.getAddress();
    
    console.log("\n🎉 DEPLOYMENT SUCCESSFUL!");
    console.log("📍 OceanMangaOrchestrator Address:", orchestratorAddress);
    console.log("🔗 BaseScan:", `https://basescan.org/address/${orchestratorAddress}`);
    
    // Verify deployment
    console.log("\n🔍 Verifying deployment...");
    const nftContract = await orchestrator.nftContract();
    const ftContract = await orchestrator.ftContract();
    const creator = await orchestrator.creator();
    const charity = await orchestrator.charity();
    
    console.log("  NFT Contract:", nftContract);
    console.log("  FT Contract:", ftContract);
    console.log("  Creator:", creator);
    console.log("  Charity:", charity);
    
    // Save deployment info
    const deploymentInfo = {
      network: "base",
      chainId: 8453,
      deployer: deployer.address,
      timestamp: new Date().toISOString(),
      OceanMangaOrchestrator: orchestratorAddress,
      txHash: orchestrator.deploymentTransaction().hash,
      mockAddresses: {
        nft: mockNFTAddress,
        ft: mockFTAddress
      },
      note: "Mock addresses used - deploy real NFT/FT contracts later"
    };
    
    const fs = require('fs');
    fs.writeFileSync('BASE_ORCHESTRATOR_DEPLOYED.json', JSON.stringify(deploymentInfo, null, 2));
    console.log("\n💾 Deployment info saved to BASE_ORCHESTRATOR_DEPLOYED.json");
    
    // Show cost
    const finalBalance = await ethers.provider.getBalance(deployer.address);
    const actualCost = balance - finalBalance;
    console.log("\n💸 Actual deployment cost:", ethers.formatEther(actualCost), "ETH");
    console.log("💰 Remaining balance:", ethers.formatEther(finalBalance), "ETH");
    
    console.log("\n" + "=" * 50);
    console.log("🎯 ORCHESTRATOR DEPLOYED SU BASE!");
    console.log("🔄 Next: Deploy real NFT/FT contracts and update orchestrator");
    console.log("=" * 50);
    
  } catch (error) {
    console.error("\n❌ Deploy failed:", error.message);
    
    if (error.transaction) {
      console.error("TX Hash:", error.transaction.hash);
      console.error("BaseScan TX:", `https://basescan.org/tx/${error.transaction.hash}`);
    }
    
    if (error.code === 'INSUFFICIENT_FUNDS') {
      console.error("💸 Need more ETH for deployment");
    }
    
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });