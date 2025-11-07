import pkg from 'hardhat';
import fs from 'fs';
const { ethers, upgrades } = pkg;

async function main() {
    console.log("🌊 DEPLOYMENT OCEANMANGA ECOSYSTEM CON IMPACT TRACKING");
    console.log("=" * 60);
    
    const [deployer] = await ethers.getSigners();
    console.log("Deploying from:", deployer.address);
    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Balance:", ethers.formatEther(balance), "ETH");
    
    // Caritas International wallet
    const CARITAS_WALLET = "0xf84eb8B95407f04Dee8fF9acaC0e0AC7231bAb2A";
    const CREATOR_WALLET = deployer.address;
    
    console.log("\n📊 STEP 1: Deploy Impact Tracker");
    
    // Deploy Impact Tracker
    const ImpactTracker = await ethers.getContractFactory("OceanMangaImpactTracker");
    const impactTracker = await upgrades.deployProxy(
        ImpactTracker,
        [CARITAS_WALLET, ethers.ZeroAddress], // orchestrator will be set later
        { initializer: "initialize" }
    );
    await impactTracker.waitForDeployment();
    console.log("✅ Impact Tracker deployed:", await impactTracker.getAddress());
    
    console.log("\n🖼️ STEP 2: Deploy NFT Contract");
    
    // Deploy NFT
    const NFTContract = await ethers.getContractFactory("OceanMangaNFT");
    const nftContract = await NFTContract.deploy();
    await nftContract.waitForDeployment();
    console.log("✅ NFT Contract deployed:", await nftContract.getAddress());
    
    console.log("\n🪙 STEP 3: Deploy FT Contract");
    
    // Deploy FT
    const FTContract = await ethers.getContractFactory("LunaComicsFT");
    const ftContract = await FTContract.deploy();
    await ftContract.waitForDeployment();
    console.log("✅ FT Contract deployed:", await ftContract.getAddress());
    
    console.log("\n🎭 STEP 4: Deploy Orchestrator V2");
    
    // Deploy Orchestrator V2 with Impact Tracking
    const OrchestratorV2 = await ethers.getContractFactory("OceanMangaOrchestratorV2");
    const orchestratorV2 = await upgrades.deployProxy(
        OrchestratorV2,
        [
            await nftContract.getAddress(),
            await ftContract.getAddress(),
            CREATOR_WALLET,
            CARITAS_WALLET,
            await impactTracker.getAddress()
        ],
        { initializer: "initialize" }
    );
    await orchestratorV2.waitForDeployment();
    console.log("✅ Orchestrator V2 deployed:", await orchestratorV2.getAddress());
    
    console.log("\n🔗 STEP 5: Connect Contracts");
    
    // Set orchestrator in impact tracker
    await impactTracker.setOrchestrator(await orchestratorV2.getAddress());
    console.log("✅ Impact tracker configured");
    
    // Set orchestrator as minter for NFT and FT
    await nftContract.setMinter(await orchestratorV2.getAddress());
    console.log("✅ NFT minter role assigned");
    
    await ftContract.addMinter(await orchestratorV2.getAddress());
    console.log("✅ FT minter role assigned");
    
    console.log("\n🚀 STEP 6: Deploy Advanced Swapper");
    
    // Deploy Advanced Swapper
    const AdvancedSwapper = await ethers.getContractFactory("LunaComicsAdvancedSwapper");
    const swapper = await upgrades.deployProxy(
        AdvancedSwapper,
        [await ftContract.getAddress()],
        { initializer: "initialize" }
    );
    await swapper.waitForDeployment();
    console.log("✅ Advanced Swapper deployed:", await swapper.getAddress());
    
    console.log("\n📋 DEPLOYMENT SUMMARY");
    console.log("=" * 60);
    console.log("🎭 Orchestrator V2:    ", await orchestratorV2.getAddress());
    console.log("📊 Impact Tracker:     ", await impactTracker.getAddress());
    console.log("🖼️  NFT Contract:       ", await nftContract.getAddress());
    console.log("🪙 FT Contract:        ", await ftContract.getAddress());
    console.log("🔄 Advanced Swapper:   ", await swapper.getAddress());
    console.log("💝 Charity Wallet:     ", CARITAS_WALLET);
    console.log("👨‍💻 Creator Wallet:     ", CREATOR_WALLET);
    
    console.log("\n✨ CARATTERISTICHE AVANZATE ATTIVATE:");
    console.log("- ✅ Impact Tracking per ogni mint");
    console.log("- ✅ Rare NFT System (threshold: 0.1 ETH)");
    console.log("- ✅ Photo Categories con validation");
    console.log("- ✅ User Impact Score & Global Stats");
    console.log("- ✅ IPFS Integration per impact verification");
    console.log("- ✅ Advanced Token Swapping");
    console.log("- ✅ Upgradeable Proxy Pattern");
    
    console.log("\n🎯 PROSSIMI PASSI:");
    console.log("1. Test mint con category: portrait, landscape, abstract...");
    console.log("2. Verifica impact tracking nel frontend");
    console.log("3. Setup IPFS per impact verification");
    console.log("4. Deploy su Base mainnet quando pronto");
    
    // Save addresses to file
    const deploymentInfo = {
        network: "base",
        timestamp: new Date().toISOString(),
        contracts: {
            orchestratorV2: await orchestratorV2.getAddress(),
            impactTracker: await impactTracker.getAddress(),
            nftContract: await nftContract.getAddress(),
            ftContract: await ftContract.getAddress(),
            advancedSwapper: await swapper.getAddress()
        },
        wallets: {
            creator: CREATOR_WALLET,
            charity: CARITAS_WALLET
        },
        features: {
            impactTracking: true,
            rareNFTs: true,
            photoCategories: true,
            advancedSwapping: true,
            upgradeableProxies: true
        }
    };
    
    fs.writeFileSync(
        'deployment-impact-ecosystem.json', 
        JSON.stringify(deploymentInfo, null, 2)
    );
    
    console.log("\n💾 Deployment info saved to: deployment-impact-ecosystem.json");
    console.log("\n🎉 DEPLOYMENT COMPLETATO CON SUCCESSO!");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Deployment failed:", error);
        process.exit(1);
    });