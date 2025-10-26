const hre = require("hardhat");

async function main() {
  console.log("🚀 Starting deployment to Base Network...");
  const [deployer] = await hre.ethers.getSigners();
  
  console.log(`📦 Deploying contracts with account: ${deployer.address}`);
  console.log(`💰 Account balance: ${hre.ethers.formatEther(await deployer.provider.getBalance(deployer.address))} ETH`);

  // [1] DEPLOY SOLIDARY METRICS
  console.log("\n📊 Deploying SolidaryMetrics...");
  const SolidaryMetrics = await hre.ethers.getContractFactory("SolidaryMetrics");
  const metrics = await SolidaryMetrics.deploy();
  await metrics.waitForDeployment();
  const metricsAddress = await metrics.getAddress();
  console.log(`✅ SolidaryMetrics deployed to: ${metricsAddress}`);

  // [2] DEPLOY MAREA MANGA NFT
  console.log("\n🌍 Deploying MareaMangaNFT...");
  const MareaMangaNFT = await hre.ethers.getContractFactory("MareaMangaNFT");
  const mareaManga = await MareaMangaNFT.deploy();
  await mareaManga.waitForDeployment();
  const mareaMangaAddress = await mareaManga.getAddress();
  console.log(`✅ MareaMangaNFT deployed to: ${mareaMangaAddress}`);

  // [3] DEPLOY LUNA COMICS FT
  console.log("\n🌙 Deploying LunaComicsFT...");
  const LunaComicsFT = await hre.ethers.getContractFactory("LunaComicsFT");
  const lunaComics = await LunaComicsFT.deploy();
  await lunaComics.waitForDeployment();
  const lunaComicsAddress = await lunaComics.getAddress();
  console.log(`✅ LunaComicsFT deployed to: ${lunaComicsAddress}`);

  // [4] INITIALIZE CONTRACTS
  console.log("\n🔗 Initializing contract relationships...");
  
  try {
    await metrics.initialize(metricsAddress, mareaMangaAddress, lunaComicsAddress);
    console.log("✅ SolidaryMetrics initialized");
    
    await mareaManga.initialize();
    console.log("✅ MareaMangaNFT initialized");
    
    await lunaComics.initialize();
    console.log("✅ LunaComicsFT initialized");
  } catch (error) {
    console.log("⚠️ Initialization skipped or already done");
  }

  console.log("\n🎉 DEPLOYMENT COMPLETATO SU BASE NETWORK!");
  console.log("==========================================");
  console.log(`📊 SolidaryMetrics: ${metricsAddress}`);
  console.log(`🌍 MareaMangaNFT: ${mareaMangaAddress}`);
  console.log(`🌙 LunaComicsFT: ${lunaComicsAddress}`);
  console.log("==========================================");

  // Salva gli indirizzi in un file
  const fs = require("fs");
  const deploymentInfo = {
    network: hre.network.name,
    timestamp: new Date().toISOString(),
    contracts: {
      SolidaryMetrics: metricsAddress,
      MareaMangaNFT: mareaMangaAddress,
      LunaComicsFT: lunaComicsAddress
    }
  };
  
  fs.writeFileSync(
    `deployment-${hre.network.name}-${Date.now()}.json`,
    JSON.stringify(deploymentInfo, null, 2)
  );
  console.log("\n💾 Deployment info saved to file");
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exitCode = 1;
});
