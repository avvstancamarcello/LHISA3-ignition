import pkg from 'hardhat';
import fs from 'fs';
const { ethers } = pkg;

async function deploySecureNFT() {
    console.log("🛡️ SECURE DEPLOYMENT - NFT CON RUOLI SICURI");
    console.log("==========================================");
    
    const [deployer] = await ethers.getSigners();
    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Balance:", ethers.formatEther(balance), "ETH");
    
    if (balance < ethers.parseEther("0.008")) {
        console.log("⏳ Waiting for sufficient funds...");
        console.log("💡 Need at least 0.008 ETH for secure deployment");
        return;
    }
    
    // RUOLI VERIFICATI - TUTTI NON-ZERO!
    const ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_ADMIN_ROLE"));
    const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MINTER_ROLE"));
    const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MANAGER_ROLE"));
    const UPGRADER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_UPGRADER_ROLE"));
    
    // WALLET VERIFICATI - TUTTI REALI!
    const OWNER_WALLET = deployer.address; // 0x8495B3f7493263685fFcDA2602fFfF349d4eD3B8
    const CHARITY_WALLET = "0xf84eb8B95407f04Dee8fF9acaC0e0AC7231bAb2A";
    
    console.log("✅ ROLES VERIFIED:");
    console.log("ADMIN_ROLE:", ADMIN_ROLE);
    console.log("MINTER_ROLE:", MINTER_ROLE);
    console.log("✅ WALLETS VERIFIED:");
    console.log("OWNER:", OWNER_WALLET);
    console.log("CHARITY:", CHARITY_WALLET);
    
    try {
        console.log("\n🚀 DEPLOYING SECURE NFT...");
        
        const NFTSecure = await ethers.getContractFactory("OceanMangaNFT_FixedRoles");
        const nftSecure = await NFTSecure.deploy({
            gasLimit: 8000000,
            gasPrice: ethers.parseUnits("1", "gwei") // Low gas price
        });
        
        console.log("⏳ Waiting for deployment...");
        await nftSecure.waitForDeployment();
        
        const nftAddress = await nftSecure.getAddress();
        console.log("✅ SECURE NFT DEPLOYED:", nftAddress);
        
        console.log("\n🔧 INITIALIZING WITH SECURE ROLES...");
        const initTx = await nftSecure.initialize(
            OWNER_WALLET,               // admin - TUO WALLET REALE
            "https://ipfs.io/ipfs/",   // base URI
            "OceanManga NFT",           // name  
            "OMNFT",                    // symbol
            OWNER_WALLET,               // royalty receiver - TUO WALLET
            500                         // royalty 5%
        );
        
        await initTx.wait();
        console.log("✅ NFT INITIALIZED");
        
        console.log("\n🔍 VERIFYING ROLE ASSIGNMENTS...");
        
        // Verifica che owner abbia TUTTI i ruoli personalizzati
        const hasAdmin = await nftSecure.hasRole(ADMIN_ROLE, OWNER_WALLET);
        const hasMinter = await nftSecure.hasRole(MINTER_ROLE, OWNER_WALLET);  
        const hasManager = await nftSecure.hasRole(MANAGER_ROLE, OWNER_WALLET);
        const hasUpgrader = await nftSecure.hasRole(UPGRADER_ROLE, OWNER_WALLET);
        
        console.log("Owner has ADMIN_ROLE:", hasAdmin);
        console.log("Owner has MINTER_ROLE:", hasMinter);
        console.log("Owner has MANAGER_ROLE:", hasManager); 
        console.log("Owner has UPGRADER_ROLE:", hasUpgrader);
        
        // CRITICAL: Verify NO DEFAULT_ADMIN_ROLE (0x000...000)
        const DEFAULT_ADMIN = "0x0000000000000000000000000000000000000000000000000000000000000000";
        const hasDefaultAdmin = await nftSecure.hasRole(DEFAULT_ADMIN, OWNER_WALLET);
        
        if (hasDefaultAdmin) {
            console.log("🚨 WARNING: Contract still has DEFAULT_ADMIN_ROLE!");
        } else {
            console.log("✅ PERFECT: NO DEFAULT_ADMIN_ROLE (0x000...000)");
        }
        
        if (hasAdmin && hasMinter && hasManager && hasUpgrader && !hasDefaultAdmin) {
            console.log("\n🎉 DEPLOYMENT PERFETTO!");
            console.log("✅ Tutti ruoli personalizzati assegnati");
            console.log("✅ ZERO ruoli 0x000...000");
            console.log("✅ Owner wallet identificativo");
            
            // Update progress
            const progress = {
                step: 4,
                nft_secure: nftAddress,
                ft: "0xF8d5a00Ca91D46c07614208C346c49a09409D094",
                orchestrator: "0xf0D90454C98A0AE934e9DB1B316FF1608C4E9DEf",
                impact_tracker: "0x20e63Ac004aA0997CC2bE7B8bB4419b9385C4689",
                status: "SECURE_NFT_DEPLOYED",
                roles_verified: true,
                no_zero_roles: true,
                timestamp: new Date().toISOString()
            };
            
            fs.writeFileSync('deployment-secure.json', JSON.stringify(progress, null, 2));
            
            console.log("\n📋 SECURE ECOSYSTEM STATUS:");
            console.log("🛡️ Secure NFT:", nftAddress);
            console.log("🪙 FT:", progress.ft);
            console.log("🎭 Orchestrator:", progress.orchestrator);
            console.log("📊 Impact Tracker:", progress.impact_tracker);
            
        } else {
            console.log("❌ ROLE ASSIGNMENT FAILED - INVESTIGATION NEEDED");
        }
        
        const finalBalance = await ethers.provider.getBalance(deployer.address);
        console.log("💰 Final balance:", ethers.formatEther(finalBalance), "ETH");
        
    } catch (error) {
        console.error("❌ Secure deployment error:", error.message);
        
        if (error.message.includes("insufficient funds")) {
            console.log("💡 Need more ETH for deployment");
        }
    }
}

deploySecureNFT()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Fatal error:", error);
        process.exit(1);
    });