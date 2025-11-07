const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("🚀 Deploy OceanMangaOrchestrator su BASE NETWORK");
  console.log("=" * 60);
  console.log("📍 Deployer:", deployer.address);
  console.log("🌐 Network: Base Mainnet");
  console.log("💎 BaseScan: https://basescan.org");
  
  // NOTA: Su Base deployeremo NUOVI contratti NFT e FT
  // poiché quelli su Polygon non sono accessibili da Base
  
  console.log("\n📋 STRATEGIA DEPLOY:");
  console.log("1. Deploy OceanMangaNFT su Base");
  console.log("2. Deploy LunaComicsFT su Base");
  console.log("3. Deploy OceanMangaOrchestrator su Base");
  console.log("4. Configurare tutto insieme");
  
  const creatorAddress = deployer.address;
  const charityAddress = deployer.address; // Temporary, can be changed later
  
  console.log("\n📋 Parametri:");
  console.log("  Creator:", creatorAddress);
  console.log("  Charity (temp):", charityAddress);
  console.log("=" * 60);
  
  try {
    // Check balance and gas
    const balance = await ethers.provider.getBalance(deployer.address);
    const feeData = await ethers.provider.getFeeData();
    
    console.log("\n💰 Pre-Deploy Check:");
    console.log("  Balance:", ethers.formatEther(balance), "ETH");
    console.log("  Gas Price:", ethers.formatUnits(feeData.gasPrice, "gwei"), "gwei");
    
    let deployedAddresses = {
      network: "base",
      chainId: 8453,
      deployer: deployer.address,
      timestamp: new Date().toISOString()
    };
    
    // Import upgrades plugin
    const { upgrades } = require("hardhat");
    
    // 1. Deploy OceanMangaNFT (UPGRADEABLE)
    console.log("\n🎨 1/3 Deploying OceanMangaNFT (Upgradeable)...");
    const OceanMangaNFT = await ethers.getContractFactory("OceanMangaNFT");
    
    const nft = await upgrades.deployProxy(OceanMangaNFT, [
      deployer.address,      // admin
      "",                    // initialURI (empty for now)
      "OceanManga NFT",      // name
      "OCEANFT",             // symbol
      deployer.address,      // royaltyReceiver
      500                    // royaltyFeeNumerator (5%)
    ], {
      initializer: 'initialize',
      gasLimit: 2000000,     // Ridotto gas limit
      gasPrice: feeData.gasPrice
    });
    
    await nft.waitForDeployment();
    const nftAddress = await nft.getAddress();
    deployedAddresses.OceanMangaNFT = nftAddress;
    
    console.log("  ✅ OceanMangaNFT deployed:", nftAddress);
    console.log("  🔗 BaseScan:", `https://basescan.org/address/${nftAddress}`);
    
    // 2. Deploy LunaComicsFTok (UPGRADEABLE)
    console.log("\n🪙 2/3 Deploying LunaComicsFTok (Upgradeable)...");
    const LunaComicsFTok = await ethers.getContractFactory("LunaComicsFTok");
    
    const ft = await upgrades.deployProxy(LunaComicsFTok, [
      deployer.address,      // admin
      "LunaComics Token",    // name
      "LUNA",                // symbol
      18,                    // decimals
      ethers.parseEther("100000"), // initialSupply ridotto (100K tokens)
      deployer.address       // initialHolder
    ], {
      initializer: 'initialize',
      gasLimit: 2000000,     // Ridotto gas limit
      gasPrice: feeData.gasPrice
    });
    
    await ft.waitForDeployment();
    const ftAddress = await ft.getAddress();
    deployedAddresses.LunaComicsFTok = ftAddress;
    
    console.log("  ✅ LunaComicsFTok deployed:", ftAddress);
    console.log("  🔗 BaseScan:", `https://basescan.org/address/${ftAddress}`);
    
    // 3. Deploy OceanMangaOrchestrator
    console.log("\n🎭 3/3 Deploying OceanMangaOrchestrator...");
    const OceanMangaOrchestrator = await ethers.getContractFactory("OceanMangaOrchestrator");
    
    const orchestrator = await OceanMangaOrchestrator.deploy(
      nftAddress,
      ftAddress,
      creatorAddress,
      charityAddress,
      {
        gasLimit: 2000000,    // Ridotto anche per orchestrator
        gasPrice: feeData.gasPrice
      }
    );
    
    await orchestrator.waitForDeployment();
    const orchestratorAddress = await orchestrator.getAddress();
    deployedAddresses.OceanMangaOrchestrator = orchestratorAddress;
    
    console.log("  ✅ OceanMangaOrchestrator deployed:", orchestratorAddress);
    console.log("  🔗 BaseScan:", `https://basescan.org/address/${orchestratorAddress}`);
    
    // 4. Configure contracts
    console.log("\n⚙️  4/4 Configuring contracts...");
    
    // Set orchestrator in NFT contract
    console.log("  Setting orchestrator in NFT...");
    const setOrchestratorNFT = await nft.setOrchestrator(orchestratorAddress);
    await setOrchestratorNFT.wait();
    console.log("  ✅ NFT orchestrator set");
    
    // Set orchestrator in FT contract
    console.log("  Setting orchestrator in FT...");
    const setOrchestratorFT = await ft.setOrchestrator(orchestratorAddress);
    await setOrchestratorFT.wait();
    console.log("  ✅ FT orchestrator set");
    
    // Verify configuration
    console.log("\n🔍 Verifying configuration...");
    const nftOrchestrator = await nft.orchestrator();
    const ftOrchestrator = await ft.orchestrator();
    const orchestratorNFT = await orchestrator.nftContract();
    const orchestratorFT = await orchestrator.ftContract();
    
    const nftConfigOk = nftOrchestrator.toLowerCase() === orchestratorAddress.toLowerCase();
    const ftConfigOk = ftOrchestrator.toLowerCase() === orchestratorAddress.toLowerCase();
    const orchestratorNFTOk = orchestratorNFT.toLowerCase() === nftAddress.toLowerCase();
    const orchestratorFTOk = orchestratorFT.toLowerCase() === ftAddress.toLowerCase();
    
    console.log("  NFT → Orchestrator:", nftConfigOk ? "✅" : "❌");
    console.log("  FT → Orchestrator:", ftConfigOk ? "✅" : "❌");
    console.log("  Orchestrator → NFT:", orchestratorNFTOk ? "✅" : "❌");
    console.log("  Orchestrator → FT:", orchestratorFTOk ? "✅" : "❌");
    
    const allConfigOk = nftConfigOk && ftConfigOk && orchestratorNFTOk && orchestratorFTOk;
    
    if (allConfigOk) {
      console.log("\n🎉 DEPLOYMENT COMPLETATO CON SUCCESSO!");
      console.log("=" * 60);
      console.log("🌐 BASE NETWORK - Tutti i contratti deployati e configurati!");
      console.log("=" * 60);
      
      console.log("\n📍 INDIRIZZI DEPLOYATI:");
      console.log("  🎨 OceanMangaNFT:      ", nftAddress);
      console.log("  🪙 LunaComicsFTok:     ", ftAddress);
      console.log("  🎭 OceanMangaOrchestrator:", orchestratorAddress);
      
      console.log("\n🔗 BASESCAN LINKS:");
      console.log("  NFT: https://basescan.org/address/" + nftAddress);
      console.log("  FT:  https://basescan.org/address/" + ftAddress);
      console.log("  Orchestrator: https://basescan.org/address/" + orchestratorAddress);
      
      // Save addresses
      const fs = require('fs');
      fs.writeFileSync('BASE_DEPLOYED_ADDRESSES.json', JSON.stringify(deployedAddresses, null, 2));
      console.log("\n💾 Indirizzi salvati in BASE_DEPLOYED_ADDRESSES.json");
      
      // Update final balance
      const finalBalance = await ethers.provider.getBalance(deployer.address);
      const costETH = balance - finalBalance;
      console.log("\n💸 Costo totale deploy:", ethers.formatEther(costETH), "ETH");
      console.log("💰 Balance rimanente:", ethers.formatEther(finalBalance), "ETH");
      
      console.log("\n" + "=" * 60);
      console.log("🎯 PRONTO PER L'INTEGRAZIONE NELLA REACT APP!");
      console.log("=" * 60);
      
    } else {
      console.log("\n❌ Configurazione fallita - alcuni contratti non sono collegati correttamente");
      process.exit(1);
    }
    
  } catch (error) {
    console.error("\n❌ Deploy failed:", error.message);
    
    if (error.transaction) {
      console.error("TX Hash:", error.transaction.hash);
      console.error("BaseScan TX:", `https://basescan.org/tx/${error.transaction.hash}`);
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