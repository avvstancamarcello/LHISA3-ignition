import pkg from 'hardhat';
const { ethers } = pkg;

async function main() {
    const nftAddress = "0x3a4bddf577D2F4AA5DF172185247704B42594EF3";
    console.log("🔧 MANUAL CONTRACT INITIALIZATION");
    console.log("==================================");
    console.log(`📍 Contract: ${nftAddress}`);
    
    try {
        const [deployer] = await ethers.getSigners();
        console.log(`👤 Deployer: ${deployer.address}`);
        
        const OceanMangaNFT = await ethers.getContractFactory("OceanMangaNFT_SecureFinal");
        const nft = await OceanMangaNFT.attach(nftAddress);
        
        // Define roles
        const ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEAN_MANGA_ADMIN"));
        const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEAN_MANGA_MINTER"));
        const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEAN_MANGA_MANAGER"));
        const UPGRADER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEAN_MANGA_UPGRADER"));
        
        console.log("\n🔑 Attempting manual initialization...");
        
        // Try to call initialize directly
        try {
            const tx = await nft.initialize(
                "OceanManga NFT Collection",
                "OCEAN",
                "https://ipfs.io/ipfs/",
                deployer.address, // Caritas wallet - using deployer for now
                500 // 5% royalty
            );
            await tx.wait();
            console.log("✅ Manual initialization successful!");
        } catch (initError) {
            console.log("⚠️ Direct initialization failed:", initError.message);
            
            // Try to manually assign roles if contract allows
            console.log("\n🔧 Attempting manual role assignment...");
            try {
                // Check if we can assign roles directly
                const grantRoleTx = await nft.grantRole(ADMIN_ROLE, deployer.address);
                await grantRoleTx.wait();
                console.log("✅ ADMIN_ROLE granted!");
                
                const grantMinterTx = await nft.grantRole(MINTER_ROLE, deployer.address);
                await grantMinterTx.wait();
                console.log("✅ MINTER_ROLE granted!");
                
                const grantManagerTx = await nft.grantRole(MANAGER_ROLE, deployer.address);
                await grantManagerTx.wait();
                console.log("✅ MANAGER_ROLE granted!");
                
                const grantUpgraderTx = await nft.grantRole(UPGRADER_ROLE, deployer.address);
                await grantUpgraderTx.wait();
                console.log("✅ UPGRADER_ROLE granted!");
                
            } catch (roleError) {
                console.log("❌ Role assignment failed:", roleError.message);
            }
        }
        
        // Final verification
        console.log("\n🔍 FINAL VERIFICATION:");
        const hasAdmin = await nft.hasRole(ADMIN_ROLE, deployer.address);
        const hasMinter = await nft.hasRole(MINTER_ROLE, deployer.address);
        console.log(`✅ Has ADMIN_ROLE: ${hasAdmin}`);
        console.log(`✅ Has MINTER_ROLE: ${hasMinter}`);
        
    } catch (error) {
        console.error("❌ Initialization error:", error.message);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });