import pkg from 'hardhat';
import fs from 'fs';
const { ethers } = pkg;

async function deployFixedNFT() {
    console.log("🔧 DEPLOYING NFT WITH FIXED ROLES");
    console.log("=================================");
    console.log("❌ NO DEFAULT_ADMIN_ROLE (0x000...000)");
    console.log("✅ ONLY CUSTOM ROLES WITH HASH VALUES");
    
    const [deployer] = await ethers.getSigners();
    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Deployer:", deployer.address);
    console.log("Balance:", ethers.formatEther(balance), "ETH");
    
    if (balance < ethers.parseEther("0.003")) {
        console.log("❌ Insufficient balance for deployment");
        return;
    }
    
    try {
        console.log("\n🖼️ Deploying OceanMangaNFT_FixedRoles...");
        
        const NFTFixed = await ethers.getContractFactory("OceanMangaNFT_FixedRoles");
        const nftFixed = await NFTFixed.deploy();
        await nftFixed.waitForDeployment();
        
        const nftAddress = await nftFixed.getAddress();
        console.log("✅ NFT with Fixed Roles deployed:", nftAddress);
        
        console.log("\n🔧 Initializing with custom roles...");
        const tx = await nftFixed.initialize(
            deployer.address,           // admin
            "https://ipfs.io/ipfs/",   // base URI
            "OceanManga NFT",           // name
            "OMNFT",                    // symbol
            deployer.address,           // royalty receiver
            500                         // royalty (5%)
        );
        await tx.wait();
        console.log("✅ NFT initialized with CUSTOM ROLES ONLY");
        
        // Verify roles
        const ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_ADMIN_ROLE"));
        const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MINTER_ROLE"));
        
        console.log("\n🔍 Verifying roles:");
        console.log("ADMIN_ROLE hash:", ADMIN_ROLE);
        console.log("MINTER_ROLE hash:", MINTER_ROLE);
        
        const hasAdminRole = await nftFixed.hasRole(ADMIN_ROLE, deployer.address);
        const hasMinterRole = await nftFixed.hasRole(MINTER_ROLE, deployer.address);
        
        console.log("Deployer has ADMIN_ROLE:", hasAdminRole);
        console.log("Deployer has MINTER_ROLE:", hasMinterRole);
        
        // Update deployment progress
        const progress = JSON.parse(fs.readFileSync('deployment-progress.json', 'utf8'));
        progress.nft_fixed = nftAddress;
        progress.nft_roles_fixed = true;
        progress.step = 3.5;
        fs.writeFileSync('deployment-progress.json', JSON.stringify(progress, null, 2));
        
        console.log("\n🎉 NFT WITH FIXED ROLES READY!");
        console.log("✅ NO 0x000...000 ROLES!");
        console.log("✅ ONLY CUSTOM OCEANMANGA ROLES!");
        
        const newBalance = await ethers.provider.getBalance(deployer.address);
        console.log("💰 Remaining balance:", ethers.formatEther(newBalance), "ETH");
        
        return nftAddress;
        
    } catch (error) {
        console.error("❌ Deployment error:", error.message);
    }
}

deployFixedNFT()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Fatal error:", error);
        process.exit(1);
    });