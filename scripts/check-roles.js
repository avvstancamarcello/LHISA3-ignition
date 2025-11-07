import pkg from 'hardhat';
const { ethers } = pkg;

async function checkRoles() {
    console.log("🔍 CHECKING CONTRACT ROLES");
    console.log("==========================");
    
    const [deployer] = await ethers.getSigners();
    console.log("Deployer:", deployer.address);
    
    const NFT_ADDRESS = "0xb3bde449c893282D8460EDf01387F3a7Db46A671";
    const FT_ADDRESS = "0xF8d5a00Ca91D46c07614208C346c49a09409D094";
    
    const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";
    const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
    
    try {
        console.log("\n🖼️ NFT Contract Roles:");
        const NFT = await ethers.getContractAt("OceanMangaNFT", NFT_ADDRESS);
        
        const hasAdminRole = await NFT.hasRole(DEFAULT_ADMIN_ROLE, deployer.address);
        console.log("Has DEFAULT_ADMIN_ROLE:", hasAdminRole);
        
        const hasMinterRole = await NFT.hasRole(MINTER_ROLE, deployer.address);
        console.log("Has MINTER_ROLE:", hasMinterRole);
        
        console.log("\n🪙 FT Contract:");
        const FT = await ethers.getContractAt("LunaComicsFT", FT_ADDRESS);
        const owner = await FT.owner();
        console.log("FT Owner:", owner);
        console.log("Is deployer owner:", owner.toLowerCase() === deployer.address.toLowerCase());
        
    } catch (error) {
        console.error("❌ Error checking roles:", error.message);
    }
}

checkRoles()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Fatal error:", error);
        process.exit(1);
    });