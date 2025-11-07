import pkg from 'hardhat';
const { ethers } = pkg;

async function main() {
    const nftAddress = "0x3a4bddf577D2F4AA5DF172185247704B42594EF3";
    console.log("🔍 VERIFYING DEPLOYED NFT CONTRACT");
    console.log("=====================================");
    console.log(`📍 Contract Address: ${nftAddress}`);
    
    try {
        const OceanMangaNFT = await ethers.getContractFactory("OceanMangaNFT_SecureFinal");
        const nft = await OceanMangaNFT.attach(nftAddress);
        
        // Define custom roles
        const ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEAN_MANGA_ADMIN"));
        const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEAN_MANGA_MINTER"));
        const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEAN_MANGA_MANAGER"));
        const UPGRADER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEAN_MANGA_UPGRADER"));
        
        console.log("\n🔑 ROLE VERIFICATION:");
        console.log(`ADMIN_ROLE: ${ADMIN_ROLE}`);
        console.log(`MINTER_ROLE: ${MINTER_ROLE}`);
        console.log(`MANAGER_ROLE: ${MANAGER_ROLE}`);
        console.log(`UPGRADER_ROLE: ${UPGRADER_ROLE}`);
        
        // Check deployer roles
        const [deployer] = await ethers.getSigners();
        console.log(`\n👤 Deployer: ${deployer.address}`);
        
        const hasAdmin = await nft.hasRole(ADMIN_ROLE, deployer.address);
        const hasMinter = await nft.hasRole(MINTER_ROLE, deployer.address);
        const hasManager = await nft.hasRole(MANAGER_ROLE, deployer.address);
        const hasUpgrader = await nft.hasRole(UPGRADER_ROLE, deployer.address);
        
        console.log(`✅ Has ADMIN_ROLE: ${hasAdmin}`);
        console.log(`✅ Has MINTER_ROLE: ${hasMinter}`);
        console.log(`✅ Has MANAGER_ROLE: ${hasManager}`);
        console.log(`✅ Has UPGRADER_ROLE: ${hasUpgrader}`);
        
        // Check if DEFAULT_ADMIN_ROLE is used (should be false)
        const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";
        const hasDefaultAdmin = await nft.hasRole(DEFAULT_ADMIN_ROLE, deployer.address);
        console.log(`🚫 Has DEFAULT_ADMIN_ROLE: ${hasDefaultAdmin} (should be FALSE)`);
        
        // Test contract name and symbol
        const name = await nft.name();
        const symbol = await nft.symbol();
        console.log(`\n📝 Contract Name: ${name}`);
        console.log(`📝 Contract Symbol: ${symbol}`);
        
        console.log("\n✅ CONTRACT VERIFICATION COMPLETE!");
        
    } catch (error) {
        console.error("❌ Verification error:", error.message);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });