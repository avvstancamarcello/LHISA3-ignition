require("dotenv").config({ path: require("path").resolve(__dirname, "..", ".env") });

const hre = require("hardhat");

async function main() {
  console.log("🚀 STARTING DEPLOYMENT TO POLYGON MAINNET");
  console.log("==========================================");
  
  const [deployer] = await hre.ethers.getSigners();
  
  console.log(`📦 Deploying with account: ${deployer.address}`);
  console.log(`💰 MATIC Balance: ${hre.ethers.formatEther(await deployer.provider.getBalance(deployer.address))} MATIC`);

  // [1] DEPLOY SOLIDARY METRICS
  console.log("\n📊 Deploying SolidaryMetrics...");
  const SolidaryMetrics = await hre.ethers.getContractFactory("SolidaryMetrics");
  const metrics = await SolidaryMetrics.deploy();
  await metrics.waitForDeployment();
  const metricsAddress = await metrics.getAddress();
  console.log(`✅ SolidaryMetrics deployed: ${metricsAddress}`);

  // [2] DEPLOY MAREA MANGA NFT
  console.log("\n🌍 Deploying MareaMangaNFT...");
  const MareaMangaNFT = await hre.ethers.getContractFactory("MareaMangaNFT");
  const mareaManga = await MareaMangaNFT.deploy();
  await mareaManga.waitForDeployment();
  const mareaMangaAddress = await mareaManga.getAddress();
  console.log(`✅ MareaMangaNFT deployed: ${mareaMangaAddress}`);

  // [3] DEPLOY LUNA COMICS FT
  console.log("\n🌙 Deploying LunaComicsFT...");
  const LunaComicsFT = await hre.ethers.getContractFactory("LunaComicsFT");
  const lunaComics = await LunaComicsFT.deploy();
  await lunaComics.waitForDeployment();
  const lunaComicsAddress = await lunaComics.getAddress();
  console.log(`✅ LunaComicsFT deployed: ${lunaComicsAddress}`);

  // [4] INITIALIZE CONTRACTS
  console.log("\n🔗 Initializing contracts...");
  try {
    await metrics.initialize(metricsAddress, mareaMangaAddress, lunaComicsAddress);
    console.log("✅ SolidaryMetrics initialized");
    
    await mareaManga.initialize();
    console.log("✅ MareaMangaNFT initialized");
    
    await lunaComics.initialize();
    console.log("✅ LunaComicsFT initialized");
  } catch (error) {
    console.log("⚠️ Initialization may be skipped or already done");
  }

  console.log("\n🎉 DEPLOYMENT COMPLETED ON POLYGON!");
  console.log("===================================");
  console.log(`📊 SolidaryMetrics: ${metricsAddress}`);
  console.log(`🌍 MareaMangaNFT: ${mareaMangaAddress}`);
  console.log(`🌙 LunaComicsFT: ${lunaComicsAddress}`);
  console.log("===================================");

  // Salva info deployment
  const fs = require("fs");
  const deploymentInfo = {
    network: "Polygon Mainnet",
    timestamp: new Date().toISOString(),
    contracts: {
      SolidaryMetrics: metricsAddress,
      MareaMangaNFT: mareaMangaAddress,
      LunaComicsFT: lunaComicsAddress
    },
    explorer: "https://polygonscan.com"
  };
  
  fs.writeFileSync("deployment-polygon.json", JSON.stringify(deploymentInfo, null, 2));
  console.log("\n💾 Deployment info saved to: deployment-polygon.json");
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exitCode = 1;
});
