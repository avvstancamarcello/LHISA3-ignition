const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("🚀 Deploy FULL SYSTEM su BASE");
  console.log("=" * 50);
  console.log("📍 Deployer:", deployer.address);
  console.log("🌐 Network: Base Mainnet");
  
  try {
    const balance = await ethers.provider.getBalance(deployer.address);
    const feeData = await ethers.provider.getFeeData();
    
    console.log("\n💰 Balance:", ethers.formatEther(balance), "ETH");
    console.log("⛽ Gas Price:", ethers.formatUnits(feeData.gasPrice, "gwei"), "gwei");
    
    // 1. Deploy NFT Contract
    console.log("\n🎨 Deploying OceanMangaNFT (ERC1155)...");
    const OceanMangaNFT = await ethers.getContractFactory("OceanMangaNFT");
    const nftContract = await OceanMangaNFT.deploy();
    await nftContract.waitForDeployment();
    const nftAddress = await nftContract.getAddress();
    console.log("✅ NFT deployed:", nftAddress);
    
    // 2. Deploy FT Contract
    console.log("\n🪙 Deploying LunaComicsFT (ERC20)...");
    const LunaComicsFT = await ethers.getContractFactory("LunaComicsFT");
    const ftContract = await LunaComicsFT.deploy();
    await ftContract.waitForDeployment();
    const ftAddress = await ftContract.getAddress();
    console.log("✅ FT deployed:", ftAddress);
    
    // 3. Deploy Orchestrator with real addresses
    console.log("\n🎭 Deploying OceanMangaOrchestrator...");
    const OceanMangaOrchestrator = await ethers.getContractFactory("OceanMangaOrchestrator");
    const orchestrator = await OceanMangaOrchestrator.deploy(
      nftAddress,
      ftAddress,
      deployer.address, // creator
      deployer.address  // charity (temp)
    );
    await orchestrator.waitForDeployment();
    const orchestratorAddress = await orchestrator.getAddress();
    console.log("✅ Orchestrator deployed:", orchestratorAddress);
    
    // 4. Set up permissions (NFT/FT allow orchestrator to mint)
    console.log("\n🔐 Setting up permissions...");
    
    // Grant minter role to orchestrator on NFT
    const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
    await nftContract.grantRole(MINTER_ROLE, orchestratorAddress);
    console.log("✅ NFT minter role granted to orchestrator");
    
    // Grant minter role to orchestrator on FT
    await ftContract.grantRole(MINTER_ROLE, orchestratorAddress);
    console.log("✅ FT minter role granted to orchestrator");
    
    // 5. Save deployment info
    const deploymentInfo = {
      network: "base",
      chainId: 8453,
      deployer: deployer.address,
      timestamp: new Date().toISOString(),
      contracts: {
        OceanMangaNFT: nftAddress,
        LunaComicsFT: ftAddress,
        OceanMangaOrchestrator: orchestratorAddress
      },
      baseScanLinks: {
        nft: `https://basescan.org/address/${nftAddress}`,
        ft: `https://basescan.org/address/${ftAddress}`,
        orchestrator: `https://basescan.org/address/${orchestratorAddress}`
      }
    };
    
    const fs = require('fs');
    fs.writeFileSync('BASE_FULL_SYSTEM_DEPLOYED.json', JSON.stringify(deploymentInfo, null, 2));
    
    // Calculate total cost
    const finalBalance = await ethers.provider.getBalance(deployer.address);
    const totalCost = balance - finalBalance;
    
    console.log("\n🎉 FULL SYSTEM DEPLOYED!");
    console.log("📍 NFT Contract:", nftAddress);
    console.log("📍 FT Contract:", ftAddress);
    console.log("📍 Orchestrator:", orchestratorAddress);
    console.log("💸 Total Cost:", ethers.formatEther(totalCost), "ETH");
    console.log("🔗 BaseScan Orchestrator:", `https://basescan.org/address/${orchestratorAddress}`);
    
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