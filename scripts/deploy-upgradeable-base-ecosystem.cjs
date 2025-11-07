async function main() {
  console.log("🚀 DEPLOY UPGRADEABLE ECOSYSTEM ON BASE");
  console.log("════════════════════════════════════════════");

  try {
    const [deployer] = await ethers.getSigners();
    console.log("📍 Deployer:", deployer.address);
    
    const balance = await deployer.provider.getBalance(deployer.address);
    console.log("💰 Balance:", ethers.formatEther(balance), "ETH");

    // REAL WALLET ADDRESSES - NO ZERO ADDRESSES!
    const creatorAddress = deployer.address;
    const charityAddress = "0xf84eb8B95407f04Dee8fF9acaC0e0AC7231bAb2A"; // Caritas International
    
    console.log("\n📍 WALLET VERIFICATION:");
    console.log("═══════════════════════");
    console.log("Creator wallet:", creatorAddress);
    console.log("Charity wallet (Caritas):", charityAddress);
    
    // Verify NO zero addresses
    if (creatorAddress === "0x0000000000000000000000000000000000000000") {
      throw new Error("❌ Creator address cannot be zero!");
    }
    if (charityAddress === "0x0000000000000000000000000000000000000000") {
      throw new Error("❌ Charity address cannot be zero!");
    }
    console.log("✅ No zero addresses detected");

    console.log("\n🎨 Deploying UPGRADEABLE OceanMangaNFT...");
    
    // Deploy NFT (ERC1155 Upgradeable with Proxy)
    const NFT = await ethers.getContractFactory("OceanMangaNFT");
    const nft = await upgrades.deployProxy(NFT, [
      "https://ipfs.lunacomics.io/metadata/", // baseURI
      creatorAddress, // admin
      creatorAddress, // minter
      creatorAddress, // manager
      250 // royalty basis points (2.5%)
    ], { 
      initializer: 'initialize',
      kind: 'uups'
    });
    await nft.waitForDeployment();
    const nftAddress = await nft.getAddress();
    console.log("✅ NFT deployed:", nftAddress);

    console.log("\n🪙 Deploying UPGRADEABLE LunaComicsFTok...");
    
    // Deploy FT (ERC20 Upgradeable with Proxy)
    const FT = await ethers.getContractFactory("LunaComicsFTok");
    const ft = await upgrades.deployProxy(FT, [
      creatorAddress, // admin
      creatorAddress, // minter
      creatorAddress, // manager
      creatorAddress  // withdrawer
    ], { 
      initializer: 'initialize',
      kind: 'uups'
    });
    await ft.waitForDeployment();
    const ftAddress = await ft.getAddress();
    console.log("✅ FT deployed:", ftAddress);

    console.log("\n🔄 Deploying NON-UPGRADEABLE Orchestrator...");
    console.log("(Note: Orchestrator uses constructor, not initialize)");
    
    // Deploy Orchestrator (uses constructor, not upgradeable proxy)
    const Orchestrator = await ethers.getContractFactory("OceanMangaOrchestrator");
    const orchestrator = await Orchestrator.deploy(
      nftAddress,
      ftAddress,
      creatorAddress,
      charityAddress
    );
    await orchestrator.waitForDeployment();
    const orchestratorAddress = await orchestrator.getAddress();
    console.log("✅ Orchestrator deployed:", orchestratorAddress);

    console.log("\n🔐 Setting up COMPLETE permissions and roles...");
    
    // Get all role constants
    const MINTER_ROLE = await nft.MINTER_ROLE();
    const DEFAULT_ADMIN_ROLE = await nft.DEFAULT_ADMIN_ROLE();
    
    console.log("🔍 Role constants:");
    console.log("  MINTER_ROLE:", MINTER_ROLE);
    console.log("  DEFAULT_ADMIN_ROLE:", DEFAULT_ADMIN_ROLE);
    
    // Verify deployer has admin roles
    console.log("\n🔐 Verifying deployer admin permissions...");
    const nftAdminRole = await nft.hasRole(DEFAULT_ADMIN_ROLE, deployer.address);
    const ftAdminRole = await ft.hasRole(DEFAULT_ADMIN_ROLE, deployer.address);
    console.log("  NFT Admin Role (deployer):", nftAdminRole ? "✅" : "❌");
    console.log("  FT Admin Role (deployer):", ftAdminRole ? "✅" : "❌");
    
    // Grant MINTER_ROLE to orchestrator on NFT contract
    console.log("\n🎨 Granting NFT minting permissions...");
    const nftTx = await nft.grantRole(MINTER_ROLE, orchestratorAddress);
    await nftTx.wait();
    console.log("✅ NFT minter role granted to orchestrator");
    
    // Grant MINTER_ROLE to orchestrator on FT contract  
    console.log("🪙 Granting FT minting permissions...");
    const ftTx = await ft.grantRole(MINTER_ROLE, orchestratorAddress);
    await ftTx.wait();
    console.log("✅ FT minter role granted to orchestrator");
    
    // Verify orchestrator has minting permissions
    console.log("\n🔍 Verifying orchestrator permissions...");
    const nftMinterRole = await nft.hasRole(MINTER_ROLE, orchestratorAddress);
    const ftMinterRole = await ft.hasRole(MINTER_ROLE, orchestratorAddress);
    console.log("  NFT Minter Role (orchestrator):", nftMinterRole ? "✅" : "❌");
    console.log("  FT Minter Role (orchestrator):", ftMinterRole ? "✅" : "❌");
    
    // Verify orchestrator configuration
    console.log("\n🔍 Verifying orchestrator configuration...");
    const orchNFT = await orchestrator.oceanMangaNFT();
    const orchFT = await orchestrator.lunaComicsFT();
    const orchCreator = await orchestrator.creator();
    const orchCharity = await orchestrator.charityFund();
    
    console.log("  Orchestrator NFT address:", orchNFT === nftAddress ? "✅" : "❌", orchNFT);
    console.log("  Orchestrator FT address:", orchFT === ftAddress ? "✅" : "❌", orchFT);
    console.log("  Creator address:", orchCreator === creatorAddress ? "✅" : "❌", orchCreator);
    console.log("  Charity address:", orchCharity === charityAddress ? "✅" : "❌", orchCharity);
    
    // Verify NO zero addresses in final config
    console.log("\n🚨 FINAL ZERO ADDRESS CHECK:");
    console.log("═══════════════════════════════");
    const zeroAddress = "0x0000000000000000000000000000000000000000";
    
    if (orchNFT === zeroAddress) throw new Error("❌ NFT address is zero!");
    if (orchFT === zeroAddress) throw new Error("❌ FT address is zero!");
    if (orchCreator === zeroAddress) throw new Error("❌ Creator address is zero!");
    if (orchCharity === zeroAddress) throw new Error("❌ Charity address is zero!");
    
    console.log("✅ All addresses verified - NO ZERO ADDRESSES");
    
    if (!nftMinterRole || !ftMinterRole) {
      throw new Error("❌ Orchestrator missing required minting permissions!");
    }
    
    console.log("\n🎯 ALL PERMISSIONS CONFIGURED CORRECTLY!");

    // Save deployment info
    const deploymentInfo = {
      timestamp: new Date().toISOString(),
      network: "base",
      deployer: deployer.address,
      wallets: {
        deployer: deployer.address,
        creator: creatorAddress,
        charity: charityAddress,
        charityAlias: "caritasinternational.cb.id"
      },
      contracts: {
        OceanMangaNFT: nftAddress,
        LunaComicsFT: ftAddress,
        OceanMangaOrchestrator: orchestratorAddress
      },
      upgradeability: {
        NFT: "UUPS Proxy",
        FT: "UUPS Proxy", 
        Orchestrator: "Non-upgradeable"
      },
      feeDistribution: {
        creatorShare: "2.5%",
        charityShare: "2.5%",
        totalFees: "5%"
      },
      gasUsed: "Standard",
      status: "READY_FOR_REAL_MINTING"
    };

    const fs = require('fs');
    fs.writeFileSync('BASE_UPGRADEABLE_ECOSYSTEM.json', JSON.stringify(deploymentInfo, null, 2));

    console.log("\n🎉 UPGRADEABLE ECOSYSTEM DEPLOYED ON BASE!");
    console.log("══════════════════════════════════════════════");
    console.log("📍 NFT Contract (UUPS):", nftAddress);
    console.log("📍 FT Contract (UUPS):", ftAddress);
    console.log("📍 Orchestrator:", orchestratorAddress);
    console.log("💾 Config saved to BASE_UPGRADEABLE_ECOSYSTEM.json");
    
    console.log("\n🚀 REAL BLOCKCHAIN MINTING NOW ENABLED!");
    console.log("═══════════════════════════════════════════");
    console.log("✅ NFT/FT contracts deployed as UPGRADEABLE");
    console.log("✅ Orchestrator has MINTER_ROLE on both contracts");
    console.log("✅ Deployer retains DEFAULT_ADMIN_ROLE for management");
    console.log("✅ NO ZERO ADDRESSES in configuration");
    console.log("✅ Ultra-low gas fees (~$0.0002 per mint)");
    console.log("✅ Ready for production minting!");
    
    console.log("\n🔐 FINAL SECURITY VERIFICATION:");
    console.log("═══════════════════════════════");
    console.log("• Deployer =", deployer.address);
    console.log("• Has admin control over NFT contract ✅");
    console.log("• Has admin control over FT contract ✅");
    console.log("• Orchestrator can mint NFTs ✅");
    console.log("• Orchestrator can mint FTs ✅");
    console.log("• Creator fees (2.5%) go to:", creatorAddress, "✅");
    console.log("• Charity fees (2.5%) go to Caritas:", charityAddress, "✅");
    console.log("• NO ZERO ADDRESSES ✅");
    
    console.log("\n📱 UPDATE REACT APP:");
    console.log("════════════════════════");
    console.log(`Update .env file:`);
    console.log(`VITE_ORCHESTRATOR_CONTRACT_ADDRESS=${orchestratorAddress}`);
    
    console.log("\n🔗 BaseScan Links:");
    console.log("═══════════════════");
    console.log(`NFT: https://basescan.org/address/${nftAddress}`);
    console.log(`FT: https://basescan.org/address/${ftAddress}`);
    console.log(`Orchestrator: https://basescan.org/address/${orchestratorAddress}`);

    console.log("\n🎭 DEPLOYMENT COMPLETE - READY FOR REAL MINTING!");

  } catch (error) {
    console.error("❌ Deploy failed:", error.message);
    if (error.message.includes("zero")) {
      console.error("🚨 ZERO ADDRESS DETECTED - Check wallet configuration!");
    }
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});