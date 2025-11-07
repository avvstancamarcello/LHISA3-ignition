import pkg from 'hardhat';
import fs from 'fs';
const { ethers } = pkg;

async function fixConnections() {
    console.log("🔗 FIXING CONTRACT CONNECTIONS");
    console.log("==============================");
    
    // Load progress
    const data = fs.readFileSync('deployment-progress.json', 'utf8');
    const progress = JSON.parse(data);
    
    console.log("📋 Loaded addresses:");
    console.log("NFT:", progress.nft);
    console.log("FT:", progress.ft);
    console.log("Orchestrator:", progress.orchestrator);
    
    const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
    
    try {
        console.log("\n🖼️ Connecting NFT...");
        const NFT = await ethers.getContractAt("OceanMangaNFT", progress.nft);
        const tx1 = await NFT.grantRole(MINTER_ROLE, progress.orchestrator);
        await tx1.wait();
        console.log("✅ NFT minter role granted");
        
        console.log("\n🪙 Connecting FT...");
        const FT = await ethers.getContractAt("LunaComicsFT", progress.ft);
        const tx2 = await FT.addMinter(progress.orchestrator);
        await tx2.wait();
        console.log("✅ FT minter role granted");
        
        // Update progress
        progress.step = 3;
        progress.status = "BASIC_ECOSYSTEM_COMPLETE";
        progress.connected = true;
        fs.writeFileSync('deployment-progress.json', JSON.stringify(progress, null, 2));
        
        console.log("\n🎉 ALL CONTRACTS CONNECTED!");
        console.log("✨ ECOSYSTEM READY FOR TESTING!");
        
        // Final summary
        console.log("\n📋 DEPLOYMENT SUMMARY:");
        console.log("🖼️ NFT Contract:", progress.nft);
        console.log("🪙 FT Contract:", progress.ft);
        console.log("🎭 Orchestrator:", progress.orchestrator);
        console.log("📊 Impact Tracker:", "0x20e63Ac004aA0997CC2bE7B8bB4419b9385C4689");
        console.log("💝 Charity Wallet:", "0xf84eb8B95407f04Dee8fF9acaC0e0AC7231bAb2A");
        
        const [deployer] = await ethers.getSigners();
        const balance = await ethers.provider.getBalance(deployer.address);
        console.log("💰 Remaining balance:", ethers.formatEther(balance), "ETH");
        
    } catch (error) {
        console.error("❌ Connection error:", error.message);
    }
}

fixConnections()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Fatal error:", error);
        process.exit(1);
    });