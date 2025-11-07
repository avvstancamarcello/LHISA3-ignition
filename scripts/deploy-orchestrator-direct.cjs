const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("Deploying OceanMangaOrchestrator with account:", deployer.address);
  
  // Indirizzi dei contratti già deployati su Polygon
  const nftAddress = "0xBeC80BF2ef21597c0b40106D8eF70d03fEE44C79"; // OceanMangaNFT
  const ftAddress = "0xE82CCA2448C87c4B07e489714eC16684209D7D58";  // LunaComicsFT
  const creatorAddress = "0x8495B3f7493263685fFcDA2602fFfF349d4eD3B8"; // Deploy address as creator
  const charityAddress = "0xB19Ee3A16554d339111028fe3a76fEE5AE45E8A3";  // SponsorVault as charity
  
  console.log("Constructor parameters:");
  console.log("  NFT Contract:", nftAddress);
  console.log("  FT Contract:", ftAddress);
  console.log("  Creator Address:", creatorAddress);
  console.log("  Charity Address:", charityAddress);
  
  // Get contract factory
  const OceanMangaOrchestrator = await ethers.getContractFactory("OceanMangaOrchestrator");
  
  console.log("\nDeploying contract...");
  
  // Check current gas price
  console.log("🔍 Checking current network conditions...");
  const feeData = await ethers.provider.getFeeData();
  console.log("  Current gas price:", ethers.formatUnits(feeData.gasPrice, "gwei"), "gwei");
  
  // Use higher gas price due to network congestion
  const gasPrice = ethers.parseUnits("140", "gwei"); // Higher than current 124 Gwei
  console.log("  Using gas price:", ethers.formatUnits(gasPrice, "gwei"), "gwei");
  
  // Deploy contract with high gas price to beat congestion
  const orchestrator = await OceanMangaOrchestrator.deploy(
    nftAddress,
    ftAddress,
    creatorAddress,
    charityAddress,
    {
      gasLimit: 3000000, // Increased gas limit
      gasPrice: gasPrice  // High gas price to get through congestion
    }
  );
  
  console.log("Transaction sent, waiting for confirmation...");
  console.log("Transaction hash:", orchestrator.deploymentTransaction().hash);
  
  // Wait for deployment
  await orchestrator.waitForDeployment();
  
  const orchestratorAddress = await orchestrator.getAddress();
  console.log("\n✅ OceanMangaOrchestrator deployed to:", orchestratorAddress);
  
  // Verify deployment
  console.log("\nVerifying deployment...");
  const nftContract = await orchestrator.oceanMangaNFT();
  const ftContract = await orchestrator.lunaComicsFT();
  const creator = await orchestrator.creator();
  const charity = await orchestrator.charityFund();
  
  console.log("  NFT Contract set to:", nftContract);
  console.log("  FT Contract set to:", ftContract);
  console.log("  Creator set to:", creator);
  console.log("  Charity set to:", charity);
  
  // Save deployment info
  const deploymentInfo = {
    network: "polygon",
    contractName: "OceanMangaOrchestrator",
    address: orchestratorAddress,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    constructorArgs: {
      nft: nftAddress,
      ft: ftAddress,
      creator: creatorAddress,
      charity: charityAddress
    },
    transactionHash: orchestrator.deploymentTransaction().hash
  };
  
  console.log("\n📋 Deployment Summary:");
  console.log(JSON.stringify(deploymentInfo, null, 2));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });