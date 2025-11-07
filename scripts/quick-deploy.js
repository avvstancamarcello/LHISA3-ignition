import pkg from 'hardhat';
import fs from 'fs';
const { ethers, upgrades } = pkg;

async function quickDeploy() {
    console.log("⚡ QUICK DEPLOYMENT - OCEANMANGA ECOSYSTEM");
    console.log("=========================================");
    
    const [deployer] = await ethers.getSigners();
    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Wallet:", deployer.address);
    console.log("Balance:", ethers.formatEther(balance), "ETH");
    
    if (balance < ethers.parseEther("0.012")) {
        console.log("❌ Need more funds! Current:", ethers.formatEther(balance), "ETH");
        console.log("💡 Required: ~0.015 ETH for full deployment");
        return;
    }
    
    const CARITAS_WALLET = "0xf84eb8B95407f04Dee8fF9acaC0e0AC7231bAb2A";
    const CREATOR_WALLET = deployer.address;
    const IMPACT_TRACKER = "0x20e63Ac004aA0997CC2bE7B8bB4419b9385C4689"; // Already deployed!
    
    console.log("\n🖼️ DEPLOYING NFT...");
    const NFT = await ethers.getContractFactory("OceanMangaNFT");
    const nft = await NFT.deploy();
    await nft.waitForDeployment();
    console.log("✅ NFT:", await nft.getAddress());
    
    console.log("\n🪙 DEPLOYING FT...");
    const FT = await ethers.getContractFactory("LunaComicsFT");
    const ft = await FT.deploy();
    await ft.waitForDeployment();
    console.log("✅ FT:", await ft.getAddress());
    
    console.log("\n🎭 DEPLOYING ORCHESTRATOR V2...");
    const OrchestratorV2 = await ethers.getContractFactory("OceanMangaOrchestratorV2");
    const orchestrator = await upgrades.deployProxy(
        OrchestratorV2,
        [
            await nft.getAddress(),
            await ft.getAddress(),
            CREATOR_WALLET,
            CARITAS_WALLET,
            IMPACT_TRACKER
        ],
        { initializer: "initialize" }
    );
    await orchestrator.waitForDeployment();
    console.log("✅ Orchestrator V2:", await orchestrator.getAddress());
    
    console.log("\n🔄 DEPLOYING SWAPPER...");
    const Swapper = await ethers.getContractFactory("LunaComicsAdvancedSwapper");
    const swapper = await upgrades.deployProxy(
        Swapper,
        [await ft.getAddress()],
        { initializer: "initialize" }
    );
    await swapper.waitForDeployment();
    console.log("✅ Swapper:", await swapper.getAddress());
    
    console.log("\n🔗 CONNECTING CONTRACTS...");
    
    // Get Impact Tracker contract
    const ImpactTracker = await ethers.getContractFactory("OceanMangaImpactTracker");
    const impactTracker = ImpactTracker.attach(IMPACT_TRACKER);
    
    // Connect everything
    await impactTracker.setOrchestrator(await orchestrator.getAddress());
    await nft.setMinter(await orchestrator.getAddress());
    await ft.addMinter(await orchestrator.getAddress());
    
    console.log("✅ ALL CONTRACTS CONNECTED!");
    
    // Final summary
    const deployment = {
        network: "base",
        timestamp: new Date().toISOString(),
        contracts: {
            orchestratorV2: await orchestrator.getAddress(),
            impactTracker: IMPACT_TRACKER,
            nftContract: await nft.getAddress(),
            ftContract: await ft.getAddress(),
            advancedSwapper: await swapper.getAddress()
        },
        wallets: {
            creator: CREATOR_WALLET,
            charity: CARITAS_WALLET
        }
    };
    
    fs.writeFileSync('quick-deployment.json', JSON.stringify(deployment, null, 2));
    
    console.log("\n🎉 ECOSYSTEM DEPLOYED SUCCESSFULLY!");
    console.log("📋 Summary saved to: quick-deployment.json");
    console.log("\n✨ READY FOR TESTING!");
}

quickDeploy()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Deployment failed:", error);
        process.exit(1);
    });