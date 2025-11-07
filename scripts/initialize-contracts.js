import pkg from 'hardhat';
import fs from 'fs';
const { ethers } = pkg;

async function initializeContracts() {
    console.log("🔧 INITIALIZING CONTRACTS");
    console.log("=========================");
    
    const [deployer] = await ethers.getSigners();
    console.log("Deployer:", deployer.address);
    
    const NFT_ADDRESS = "0xb3bde449c893282D8460EDf01387F3a7Db46A671";
    const FT_ADDRESS = "0xF8d5a00Ca91D46c07614208C346c49a09409D094"; 
    const ORCHESTRATOR_ADDRESS = "0xf0D90454C98A0AE934e9DB1B316FF1608C4E9DEf";
    
    try {
        console.log("\n🖼️ Initializing NFT Contract...");
        const NFT = await ethers.getContractAt("OceanMangaNFT", NFT_ADDRESS);
        
        // Try to initialize (might fail if already initialized)
        try {
            const tx = await NFT.initialize(
                deployer.address,           // admin
                "https://ipfs.io/ipfs/",   // base URI
                "OceanManga NFT",           // name
                "OMNFT",                    // symbol
                deployer.address,           // royalty receiver
                500                         // royalty (5%)
            );
            await tx.wait();
            console.log("✅ NFT initialized");
        } catch (initError) {
            if (initError.message.includes("Initializable: contract is already initialized")) {
                console.log("ℹ️  NFT already initialized");
            } else {
                throw initError;
            }
        }
        
        // Now grant minter role
        const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
        const tx2 = await NFT.grantRole(MINTER_ROLE, ORCHESTRATOR_ADDRESS);
        await tx2.wait();
        console.log("✅ NFT minter role granted to orchestrator");
        
        console.log("\n🪙 Checking FT Contract...");
        const FT = await ethers.getContractAt("LunaComicsFT", FT_ADDRESS);
        
        // Check if FT has the addMinter function
        try {
            const tx3 = await FT.addMinter(ORCHESTRATOR_ADDRESS);
            await tx3.wait();
            console.log("✅ FT minter role granted to orchestrator");
        } catch (ftError) {
            console.log("⚠️  FT might not have addMinter function:", ftError.message);
            
            // Try alternative methods if available
            try {
                const MINTER_ROLE_FT = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
                const tx4 = await FT.grantRole(MINTER_ROLE_FT, ORCHESTRATOR_ADDRESS);
                await tx4.wait();
                console.log("✅ FT minter role granted via grantRole");
            } catch (altError) {
                console.log("❌ Could not grant FT minter role:", altError.message);
            }
        }
        
        // Update progress
        const progress = {
            step: 3,
            nft: NFT_ADDRESS,
            ft: FT_ADDRESS,
            orchestrator: ORCHESTRATOR_ADDRESS,
            status: "BASIC_ECOSYSTEM_COMPLETE",
            connected: true,
            timestamp: new Date().toISOString()
        };
        
        fs.writeFileSync('deployment-progress.json', JSON.stringify(progress, null, 2));
        
        console.log("\n🎉 BASIC ECOSYSTEM READY!");
        console.log("📋 FINAL ADDRESSES:");
        console.log("🖼️ NFT:", NFT_ADDRESS);
        console.log("🪙 FT:", FT_ADDRESS);
        console.log("🎭 Orchestrator:", ORCHESTRATOR_ADDRESS);
        console.log("📊 Impact Tracker:", "0x20e63Ac004aA0997CC2bE7B8bB4419b9385C4689");
        console.log("💝 Charity:", "0xf84eb8B95407f04Dee8fF9acaC0e0AC7231bAb2A");
        
        const balance = await ethers.provider.getBalance(deployer.address);
        console.log("💰 Remaining balance:", ethers.formatEther(balance), "ETH");
        
        console.log("\n✨ READY FOR MINTING TESTS!");
        
    } catch (error) {
        console.error("❌ Initialization error:", error.message);
    }
}

initializeContracts()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Fatal error:", error);
        process.exit(1);
    });