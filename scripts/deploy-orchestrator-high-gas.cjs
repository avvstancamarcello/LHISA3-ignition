const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("🚀 Deploy OceanMangaOrchestrator con Nonce Manuale");
  console.log("=" * 60);
  console.log("📍 Deployer:", deployer.address);
  console.log("🌐 Network: Polygon (alta congestione)");
  
  // Indirizzi dei contratti già deployati
  const nftAddress = "0xBeC80BF2ef21597c0b40106D8eF70d03fEE44C79";    // OceanMangaNFT
  const ftAddress = "0xE82CCA2448C87c4B07e489714eC16684209D7D58";     // LunaComicsFT
  const creatorAddress = deployer.address;                              // Creator
  const charityAddress = "0xB19Ee3A16554d339111028fe3a76fEE5AE45E8A3";  // SponsorVault
  
  console.log("📋 Parametri costruttore:");
  console.log("  NFT Contract:", nftAddress);
  console.log("  FT Contract:", ftAddress);
  console.log("  Creator:", creatorAddress);
  console.log("  Charity:", charityAddress);
  
  try {
    // Check current nonce status
    const currentNonce = await ethers.provider.getTransactionCount(deployer.address);
    const pendingNonce = await ethers.provider.getTransactionCount(deployer.address, "pending");
    console.log("\n🔍 Stato Nonce:");
    console.log("  Current nonce:", currentNonce);
    console.log("  Pending nonce:", pendingNonce);
    console.log("  Pending transactions:", pendingNonce - currentNonce);
    
    // Use the next available nonce (pending nonce)
    const useNonce = pendingNonce;
    console.log("  Using nonce:", useNonce);
    
    // Check gas conditions
    const feeData = await ethers.provider.getFeeData();
    console.log("\n⛽ Condizioni Gas:");
    console.log("  Network gas price:", ethers.formatUnits(feeData.gasPrice, "gwei"), "gwei");
    
    // Use very high gas price to beat congestion
    const gasPrice = ethers.parseUnits("150", "gwei"); // Even higher
    console.log("  Our gas price:", ethers.formatUnits(gasPrice, "gwei"), "gwei");
    
    // Check balance
    const balance = await ethers.provider.getBalance(deployer.address);
    const estimatedCost = gasPrice * BigInt(3000000); // gasLimit * gasPrice
    console.log("\n💰 Balance Check:");
    console.log("  Current balance:", ethers.formatEther(balance), "MATIC");
    console.log("  Estimated cost:", ethers.formatEther(estimatedCost), "MATIC");
    
    if (balance < estimatedCost) {
      console.log("❌ Insufficient balance for high gas deployment");
      process.exit(1);
    }
    
    console.log("=" * 60);
    
    // Get contract factory
    const OceanMangaOrchestrator = await ethers.getContractFactory("OceanMangaOrchestrator");
    
    console.log("🚀 Deploying with high gas and manual nonce...");
    
    // Deploy with manual nonce and high gas
    const orchestrator = await OceanMangaOrchestrator.deploy(
      nftAddress,
      ftAddress, 
      creatorAddress,
      charityAddress,
      {
        gasLimit: 3000000,
        gasPrice: gasPrice,
        nonce: useNonce  // Use manual nonce to bypass pending txs
      }
    );
    
    console.log("⏳ Transaction sent!");
    console.log("   TX Hash:", orchestrator.deploymentTransaction().hash);
    console.log("   Nonce used:", useNonce);
    console.log("   Gas price:", ethers.formatUnits(gasPrice, "gwei"), "gwei");
    
    console.log("\n⏳ Waiting for confirmation (may take several minutes due to congestion)...");
    
    // Wait for deployment with longer timeout
    await orchestrator.waitForDeployment();
    const deployedAddress = await orchestrator.getAddress();
    
    console.log("\n🎉 DEPLOYMENT SUCCESSFUL!");
    console.log("📍 Contract Address:", deployedAddress);
    
    // Update todo
    console.log("\n🔍 Verifying deployment...");
    const nftContract = await orchestrator.oceanMangaNFT();
    const ftContract = await orchestrator.lunaComicsFT();
    const creator = await orchestrator.creator();
    const charity = await orchestrator.charityFund();
    
    console.log("✅ Verification:");
    console.log("  NFT Contract:", nftContract);
    console.log("  FT Contract:", ftContract);
    console.log("  Creator:", creator);
    console.log("  Charity:", charity);
    
    // Save deployment info
    const fs = require('fs');
    const deploymentInfo = {
      network: "polygon",
      contractName: "OceanMangaOrchestrator",
      address: deployedAddress,
      deployer: deployer.address,
      timestamp: new Date().toISOString(),
      txHash: orchestrator.deploymentTransaction().hash,
      nonce: useNonce,
      gasPrice: ethers.formatUnits(gasPrice, "gwei") + " gwei",
      constructorArgs: {
        nft: nftAddress,
        ft: ftAddress,
        creator: creatorAddress,
        charity: charityAddress
      }
    };
    
    fs.writeFileSync('ORCHESTRATOR_DEPLOYED.json', JSON.stringify(deploymentInfo, null, 2));
    console.log("\n💾 Deployment info saved to ORCHESTRATOR_DEPLOYED.json");
    
    console.log("\n" + "=" * 60);
    console.log("🎉 ORCHESTRATOR SUCCESSFULLY DEPLOYED!");
    console.log("📍 Address:", deployedAddress);
    console.log("⛽ Gas used: High priority to beat congestion");
    console.log("=" * 60);
    
  } catch (error) {
    console.error("\n❌ Deploy failed:", error.message);
    
    if (error.code === 'INSUFFICIENT_FUNDS') {
      console.error("💸 Insufficient funds - need more MATIC for high gas");
    } else if (error.code === 'NONCE_EXPIRED' || error.code === 'REPLACEMENT_UNDERPRICED') {
      console.error("🔄 Nonce/Gas price issue - try increasing gas price further");
    } else if (error.reason) {
      console.error("📋 Reason:", error.reason);
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