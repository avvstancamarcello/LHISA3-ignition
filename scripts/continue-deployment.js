import pkg from 'hardhat';
import fs from 'fs';
const { ethers } = pkg;

async function continueDeployment() {
    console.log("🔄 CONTINUING DEPLOYMENT - MINIMAL GAS");
    console.log("====================================");
    
    const [deployer] = await ethers.getSigners();
    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Balance:", ethers.formatEther(balance), "ETH");
    
    // Load previous progress
    let progress = {};
    try {
        const data = fs.readFileSync('deployment-progress.json', 'utf8');
        progress = JSON.parse(data);
        console.log("📋 Previous progress loaded - Step", progress.step);
    } catch (error) {
        console.log("📋 No previous progress found");
        return;
    }
    
    const CARITAS_WALLET = "0xf84eb8B95407f04Dee8fF9acaC0e0AC7231bAb2A";
    const CREATOR_WALLET = deployer.address;
    
    // Try to deploy FT with minimal gas
    if (progress.step === 1 && !progress.ft && balance > ethers.parseEther("0.0005")) {
        console.log("\n🪙 Attempting FT deployment with minimal gas...");
        try {
            const FT = await ethers.getContractFactory("LunaComicsFT");
            
            // Get gas estimate
            const deployTx = await FT.getDeployTransaction();
            const gasEstimate = await ethers.provider.estimateGas(deployTx);
            const gasPrice = await ethers.provider.getFeeData();
            const totalCost = gasEstimate * gasPrice.gasPrice;
            
            console.log("Gas estimate:", gasEstimate.toString());
            console.log("Gas price:", ethers.formatUnits(gasPrice.gasPrice, "gwei"), "gwei");
            console.log("Estimated cost:", ethers.formatEther(totalCost), "ETH");
            
            if (balance > totalCost * 110n / 100n) { // 10% buffer
                const ft = await FT.deploy();
                await ft.waitForDeployment();
                const ftAddress = await ft.getAddress();
                console.log("✅ FT deployed:", ftAddress);
                
                progress.step = 2;
                progress.ft = ftAddress;
                fs.writeFileSync('deployment-progress.json', JSON.stringify(progress, null, 2));
                
                const newBalance = await ethers.provider.getBalance(deployer.address);
                console.log("💰 Remaining:", ethers.formatEther(newBalance), "ETH");
            } else {
                console.log("❌ Insufficient funds for FT deployment");
                console.log("💡 Need:", ethers.formatEther(totalCost * 110n / 100n - balance), "ETH more");
            }
        } catch (error) {
            console.error("❌ FT deployment failed:", error.message);
        }
    }
    
    // If we have both NFT and FT, try simple orchestrator
    if (progress.nft && progress.ft && !progress.orchestrator) {
        const currentBalance = await ethers.provider.getBalance(deployer.address);
        if (currentBalance > ethers.parseEther("0.0005")) {
            console.log("\n🎭 Attempting minimal Orchestrator...");
            try {
                // Use the simple non-upgradeable orchestrator to save gas
                const SimpleOrchestrator = await ethers.getContractFactory("OceanMangaOrchestrator");
                
                const gasEstimate = await SimpleOrchestrator.estimateGas.deploy(
                    progress.nft,
                    progress.ft,
                    CREATOR_WALLET,
                    CARITAS_WALLET
                );
                
                const gasPrice = await ethers.provider.getFeeData();
                const totalCost = gasEstimate * gasPrice.gasPrice;
                
                console.log("Orchestrator gas estimate:", gasEstimate.toString());
                console.log("Estimated cost:", ethers.formatEther(totalCost), "ETH");
                
                if (currentBalance > totalCost * 110n / 100n) {
                    const orchestrator = await SimpleOrchestrator.deploy(
                        progress.nft,
                        progress.ft,
                        CREATOR_WALLET,
                        CARITAS_WALLET
                    );
                    await orchestrator.waitForDeployment();
                    const orchestratorAddress = await orchestrator.getAddress();
                    console.log("✅ Simple Orchestrator deployed:", orchestratorAddress);
                    
                    // Connect contracts with minimal gas
                    console.log("🔗 Connecting contracts...");
                    const NFT = await ethers.getContractAt("OceanMangaNFT", progress.nft);
                    const FT = await ethers.getContractAt("LunaComicsFT", progress.ft);
                    
                    await NFT.setMinter(orchestratorAddress);
                    await FT.addMinter(orchestratorAddress);
                    
                    progress.step = 3;
                    progress.orchestrator = orchestratorAddress;
                    progress.status = "BASIC_ECOSYSTEM_COMPLETE";
                    fs.writeFileSync('deployment-progress.json', JSON.stringify(progress, null, 2));
                    
                    console.log("\n🎉 BASIC ECOSYSTEM COMPLETE!");
                    console.log("🖼️ NFT:", progress.nft);
                    console.log("🪙 FT:", progress.ft);
                    console.log("🎭 Orchestrator:", orchestratorAddress);
                    console.log("📊 Impact Tracker:", "0x20e63Ac004aA0997CC2bE7B8bB4419b9385C4689");
                    
                } else {
                    console.log("❌ Insufficient funds for Orchestrator");
                    console.log("💡 Need:", ethers.formatEther(totalCost * 110n / 100n - currentBalance), "ETH more");
                }
            } catch (error) {
                console.error("❌ Orchestrator deployment failed:", error.message);
            }
        }
    }
    
    // Final status
    const finalBalance = await ethers.provider.getBalance(deployer.address);
    console.log("\n💰 Final balance:", ethers.formatEther(finalBalance), "ETH");
    
    if (progress.status === "BASIC_ECOSYSTEM_COMPLETE") {
        console.log("✨ ECOSYSTEM READY FOR TESTING!");
        console.log("💡 Add more funds later for advanced features (Impact Tracking V2, Swapper)");
    }
}

continueDeployment()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Error:", error);
        process.exit(1);
    });