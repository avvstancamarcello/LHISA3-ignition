const { upgrades } = require("hardhat");

async function main() {
  console.log("🎭 DEPLOYING OCEANMANGA RARE SYSTEM");
  console.log("═══════════════════════════════════════");

  try {
    const [deployer] = await ethers.getSigners();
    console.log("📍 Deployer:", deployer.address);
    
    const balance = await deployer.provider.getBalance(deployer.address);
    console.log("💰 Balance:", ethers.formatEther(balance), "ETH");

    // Contract addresses (from ecosystem deployment)
    const nftAddress = process.env.NFT_CONTRACT_ADDRESS || "0x0000000000000000000000000000000000000000";
    const ftAddress = process.env.FT_CONTRACT_ADDRESS || "0x0000000000000000000000000000000000000000";
    const metricsAddress = process.env.METRICS_CONTRACT_ADDRESS || "0x0000000000000000000000000000000000000000";
    const charityAddress = "0xf84eb8B95407f04Dee8fF9acaC0e0AC7231bAb2A"; // Caritas International

    console.log("\n📋 CONTRACT ADDRESSES:");
    console.log("══════════════════════");
    console.log("NFT Contract:", nftAddress);
    console.log("FT Contract:", ftAddress);
    console.log("Metrics Oracle:", metricsAddress);
    console.log("Charity Wallet:", charityAddress);

    // Deploy SolidarySystemMetrics if needed
    let actualMetricsAddress = metricsAddress;
    if (metricsAddress === "0x0000000000000000000000000000000000000000") {
      console.log("\n🔮 Deploying SolidarySystemMetrics Oracle...");
      
      const Metrics = await ethers.getContractFactory("SolidarySystemMetrics");
      const metrics = await upgrades.deployProxy(
        Metrics,
        [
          deployer.address, // admin
          deployer.address, // initial orchestrator (will be updated)
          3600 // 1 hour interval
        ],
        { 
          initializer: 'initialize',
          kind: 'uups' 
        }
      );
      
      await metrics.waitForDeployment();
      actualMetricsAddress = await metrics.getAddress();
      console.log("✅ Metrics Oracle deployed:", actualMetricsAddress);
    }

    console.log("\n🎭 Deploying OceanMangaRareSystem (Upgradeable)...");
    
    const RareSystem = await ethers.getContractFactory("OceanMangaRareSystem");
    
    const rareSystem = await upgrades.deployProxy(
      RareSystem,
      [
        nftAddress === "0x0000000000000000000000000000000000000000" ? deployer.address : nftAddress,
        ftAddress === "0x0000000000000000000000000000000000000000" ? deployer.address : ftAddress,
        actualMetricsAddress,
        charityAddress,
        "https://oceanmanga.solidary.it/rare/" // Base URI for rare NFTs
      ],
      { 
        initializer: 'initialize',
        kind: 'uups' 
      }
    );
    
    await rareSystem.waitForDeployment();
    const rareSystemAddress = await rareSystem.getAddress();
    
    console.log("✅ OceanMangaRareSystem deployed:", rareSystemAddress);

    console.log("\n🌟 Setting up celebrity examples...");
    
    // Add some example celebrities (mock addresses for demo)
    const celebrities = [
      {
        address: "0x1234567890123456789012345678901234567890",
        name: "Satoshi Nakamoto"
      },
      {
        address: "0xABCDEF123456789012345678901234567890ABCDEF",
        name: "Vitalik Buterin"
      },
      {
        address: "0x9876543210987654321098765432109876543210",
        name: "Elon Musk"
      }
    ];

    for (let celebrity of celebrities) {
      try {
        const tx = await rareSystem.approveCelebrity(celebrity.address, celebrity.name);
        await tx.wait();
        console.log(`✅ Approved celebrity: ${celebrity.name}`);
      } catch (error) {
        console.log(`⚠️ Failed to approve ${celebrity.name}:`, error.message);
      }
    }

    console.log("\n🔍 Verifying deployment...");
    
    try {
      const rareCharityPercentage = await rareSystem.rareCharityPercentage();
      const nextRareTokenId = await rareSystem.nextRareTokenId();
      const totalRareValue = await rareSystem.totalRareValue();
      
      console.log("📊 Rare charity percentage:", rareCharityPercentage.toString(), "%");
      console.log("🎯 Next rare token ID:", nextRareTokenId.toString());
      console.log("💎 Total rare value:", ethers.formatEther(totalRareValue), "ETH");
      
    } catch (error) {
      console.log("⚠️ Verification partially failed:", error.message);
    }

    // Save deployment info
    const deploymentInfo = {
      timestamp: new Date().toISOString(),
      network: "base",
      deployer: deployer.address,
      contracts: {
        OceanMangaRareSystem: rareSystemAddress,
        SolidarySystemMetrics: actualMetricsAddress,
        NFTContract: nftAddress,
        FTContract: ftAddress
      },
      wallets: {
        deployer: deployer.address,
        charity: charityAddress,
        charityAlias: "caritasinternational.cb.id"
      },
      rareNFTConfig: {
        baseURI: "https://oceanmanga.solidary.it/rare/",
        charityPercentage: "50%",
        startingTokenId: 10000,
        valueStabilizationFactor: "20%"
      },
      celebrities: celebrities,
      features: [
        "Premium rare NFT minting",
        "Celebrity endorsement system", 
        "Value stabilization for FT tokens",
        "Charity donation integration",
        "Metrics oracle integration",
        "Upgradeable proxy pattern"
      ],
      gasUsed: "Upgradeable",
      status: "READY_FOR_RARE_MINTING"
    };

    const fs = require('fs');
    fs.writeFileSync('OCEANMANGA_RARE_SYSTEM_DEPLOYED.json', JSON.stringify(deploymentInfo, null, 2));

    console.log("\n🎉 OCEANMANGA RARE SYSTEM DEPLOYED!");
    console.log("═══════════════════════════════════════════");
    console.log("📍 Rare System Address:", rareSystemAddress);
    console.log("📍 Metrics Oracle:", actualMetricsAddress);
    console.log("💾 Config saved to OCEANMANGA_RARE_SYSTEM_DEPLOYED.json");
    
    console.log("\n🎭 RARE NFT FEATURES:");
    console.log("═══════════════════");
    console.log("✅ Premium rare NFT minting (owner only)");
    console.log("✅ Celebrity endorsement system");
    console.log("✅ Custom IPFS CIDs for rare content");
    console.log("✅ Value stabilization for FT ecosystem");
    console.log("✅ 50% charity donation from rare sales");
    console.log("✅ Metrics oracle integration");
    console.log("✅ Upgradeable architecture");
    
    console.log("\n💡 RARE NFT USE CASES:");
    console.log("═══════════════════");
    console.log("• 🎨 Signed artwork by famous artists");
    console.log("• 🎬 Collectibles from movie stars");
    console.log("• 🎮 Gaming items from esports champions");
    console.log("• 🎵 Music memorabilia from musicians");
    console.log("• 🏆 Sports cards from athletes");
    console.log("• 📚 Literary works from authors");
    
    console.log("\n🔮 VALUE STABILIZATION SYSTEM:");
    console.log("═══════════════════════════════");
    console.log("• Rare NFTs increase perceived ecosystem value");
    console.log("• FT tokens maintain stability despite higher supply");
    console.log("• 20% of rare NFT value influences FT pricing");
    console.log("• Charity benefits from premium donations");
    console.log("• Collectors get authentic, endorsed pieces");
    
    console.log("\n🔗 BaseScan Links:");
    console.log("═══════════════════");
    console.log(`Rare System: https://basescan.org/address/${rareSystemAddress}`);
    console.log(`Metrics Oracle: https://basescan.org/address/${actualMetricsAddress}`);

    console.log("\n📱 OWNER FUNCTIONS AVAILABLE:");
    console.log("════════════════════════════");
    console.log("• mintRareNFT() - Create premium collectibles");
    console.log("• approveCelebrity() - Add endorsed personalities");
    console.log("• updateRareValue() - Adjust NFT valuations");
    console.log("• setRareBaseURI() - Update metadata location");
    console.log("• calculateStabilizedFTValue() - Check FT stability");

  } catch (error) {
    console.error("❌ Deploy failed:", error.message);
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});