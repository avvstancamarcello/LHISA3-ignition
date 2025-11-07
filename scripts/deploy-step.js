import pkg from 'hardhat';
import fs from 'fs';
const { ethers, upgrades } = pkg;

async function deployStep() {
    console.log("🚀 STEP-BY-STEP DEPLOYMENT - OCEANMANGA");
    console.log("=====================================");
    
    const [deployer] = await ethers.getSigners();
    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Wallet:", deployer.address);
    console.log("Balance:", ethers.formatEther(balance), "ETH");
    
    const CARITAS_WALLET = "0xf84eb8B95407f04Dee8fF9acaC0e0AC7231bAb2A";
    const CREATOR_WALLET = deployer.address;
    const IMPACT_TRACKER = "0x20e63Ac004aA0997CC2bE7B8bB4419b9385C4689";
    
    // Check what can be deployed with current balance
    if (balance < ethers.parseEther("0.003")) {
        console.log("❌ Insufficient funds for any deployment");
        return;
    }
    
    console.log("\n🖼️ Step 1: NFT Contract");
    try {
        const NFT = await ethers.getContractFactory("OceanMangaNFT");
        const nft = await NFT.deploy();
        await nft.waitForDeployment();
        const nftAddress = await nft.getAddress();
        console.log("✅ NFT deployed:", nftAddress);
        
        // Save progress
        const progress = {
            step: 1,
            nft: nftAddress,
            timestamp: new Date().toISOString()
        };
        fs.writeFileSync('deployment-progress.json', JSON.stringify(progress, null, 2));
        
        const newBalance = await ethers.provider.getBalance(deployer.address);
        console.log("💰 Remaining balance:", ethers.formatEther(newBalance), "ETH");
        
        if (newBalance > ethers.parseEther("0.003")) {
            console.log("\n🪙 Step 2: FT Contract");
            const FT = await ethers.getContractFactory("LunaComicsFT");
            const ft = await FT.deploy();
            await ft.waitForDeployment();
            const ftAddress = await ft.getAddress();
            console.log("✅ FT deployed:", ftAddress);
            
            progress.step = 2;
            progress.ft = ftAddress;
            fs.writeFileSync('deployment-progress.json', JSON.stringify(progress, null, 2));
            
            const finalBalance = await ethers.provider.getBalance(deployer.address);
            console.log("💰 Final balance:", ethers.formatEther(finalBalance), "ETH");
            
            if (finalBalance > ethers.parseEther("0.002")) {
                console.log("\n🎭 Step 3: Basic Orchestrator (non-upgradeable)");
                const SimpleOrchestrator = await ethers.getContractFactory("OceanMangaOrchestrator");
                const orchestrator = await SimpleOrchestrator.deploy(
                    nftAddress,
                    ftAddress, 
                    CREATOR_WALLET,
                    CARITAS_WALLET
                );
                await orchestrator.waitForDeployment();
                const orchestratorAddress = await orchestrator.getAddress();
                console.log("✅ Simple Orchestrator deployed:", orchestratorAddress);
                
                // Connect contracts
                await nft.setMinter(orchestratorAddress);
                await ft.addMinter(orchestratorAddress);
                
                progress.step = 3;
                progress.orchestrator = orchestratorAddress;
                progress.status = "BASIC_ECOSYSTEM_READY";
                fs.writeFileSync('deployment-progress.json', JSON.stringify(progress, null, 2));
                
                console.log("\n🎉 BASIC ECOSYSTEM DEPLOYED!");
                console.log("📋 NFT:", nftAddress);
                console.log("📋 FT:", ftAddress);
                console.log("📋 Orchestrator:", orchestratorAddress);
                console.log("📋 Impact Tracker:", IMPACT_TRACKER);
                console.log("\n✨ Ready for minting! Add more funds later for advanced features.");
            }
        }
        
    } catch (error) {
        console.error("❌ Deployment error:", error.message);
    }
}

deployStep()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Fatal error:", error);
        process.exit(1);
    });