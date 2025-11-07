import pkg from 'hardhat';
import fs from 'fs';
const { ethers } = pkg;

async function deployOptimized() {
    console.log("⚡ OPTIMIZED DEPLOYMENT - LOW GAS");
    console.log("=================================");
    
    const [deployer] = await ethers.getSigners();
    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Balance:", ethers.formatEther(balance), "ETH");
    
    // Load progress
    let progress = {};
    try {
        const data = fs.readFileSync('deployment-progress.json', 'utf8');
        progress = JSON.parse(data);
    } catch (error) {
        console.log("No progress file found");
        return;
    }
    
    const CARITAS_WALLET = "0xf84eb8B95407f04Dee8fF9acaC0e0AC7231bAb2A";
    const CREATOR_WALLET = deployer.address;
    
    // Get current gas price and optimize
    const feeData = await ethers.provider.getFeeData();
    console.log("Current gas price:", ethers.formatUnits(feeData.gasPrice, "gwei"), "gwei");
    
    // Try with lower gas price (80% of current)
    const optimizedGasPrice = feeData.gasPrice * 80n / 100n;
    console.log("Using optimized gas price:", ethers.formatUnits(optimizedGasPrice, "gwei"), "gwei");
    
    if (progress.step === 1 && !progress.ft) {
        console.log("\n🪙 Deploying FT with optimized gas...");
        try {
            const FT = await ethers.getContractFactory("LunaComicsFT");
            
            // Deploy with optimized gas settings
            const ft = await FT.deploy({
                gasPrice: optimizedGasPrice,
                gasLimit: 6000000 // Set reasonable limit
            });
            
            console.log("⏳ Waiting for deployment...");
            await ft.waitForDeployment();
            
            const ftAddress = await ft.getAddress();
            console.log("✅ FT deployed:", ftAddress);
            
            progress.step = 2;
            progress.ft = ftAddress;
            fs.writeFileSync('deployment-progress.json', JSON.stringify(progress, null, 2));
            
            const newBalance = await ethers.provider.getBalance(deployer.address);
            console.log("💰 Remaining balance:", ethers.formatEther(newBalance), "ETH");
            
            // Try orchestrator if enough balance
            if (newBalance > ethers.parseEther("0.003")) {
                console.log("\n🎭 Deploying Simple Orchestrator...");
                
                const SimpleOrchestrator = await ethers.getContractFactory("OceanMangaOrchestrator");
                const orchestrator = await SimpleOrchestrator.deploy(
                    progress.nft,
                    ftAddress,
                    CREATOR_WALLET,
                    CARITAS_WALLET,
                    {
                        gasPrice: optimizedGasPrice,
                        gasLimit: 4000000
                    }
                );
                
                await orchestrator.waitForDeployment();
                const orchestratorAddress = await orchestrator.getAddress();
                console.log("✅ Orchestrator deployed:", orchestratorAddress);
                
                // Connect contracts
                console.log("🔗 Connecting contracts...");
                const NFT = await ethers.getContractAt("OceanMangaNFT", progress.nft);
                
                await NFT.setMinter(orchestratorAddress, {
                    gasPrice: optimizedGasPrice
                });
                
                await ft.addMinter(orchestratorAddress, {
                    gasPrice: optimizedGasPrice
                });
                
                progress.step = 3;
                progress.orchestrator = orchestratorAddress;
                progress.status = "BASIC_ECOSYSTEM_COMPLETE";
                fs.writeFileSync('deployment-progress.json', JSON.stringify(progress, null, 2));
                
                console.log("\n🎉 BASIC ECOSYSTEM DEPLOYED!");
                console.log("🖼️ NFT:", progress.nft);
                console.log("🪙 FT:", ftAddress);
                console.log("🎭 Orchestrator:", orchestratorAddress);
                console.log("📊 Impact Tracker:", "0x20e63Ac004aA0997CC2bE7B8bB4419b9385C4689");
                
                const finalBalance = await ethers.provider.getBalance(deployer.address);
                console.log("💰 Final balance:", ethers.formatEther(finalBalance), "ETH");
                console.log("✨ READY FOR TESTING AND MINTING!");
            }
            
        } catch (error) {
            console.error("❌ Deployment error:", error.message);
            
            // If it's a gas issue, suggest waiting for lower gas prices
            if (error.message.includes("insufficient funds")) {
                console.log("💡 Gas prices are high. Consider waiting a few minutes and trying again.");
                console.log("💡 Or add more ETH to the wallet for gas fees.");
            }
        }
    }
}

deployOptimized()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Fatal error:", error);
        process.exit(1);
    });