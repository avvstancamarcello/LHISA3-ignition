import pkg from 'hardhat';
const { ethers } = pkg;

async function investigateNFT() {
    console.log("🔍 INVESTIGAZIONE NFT SICURO");
    console.log("============================");
    
    const [deployer] = await ethers.getSigners();
    const SECURE_NFT = "0xF7646D1918B9c55896De905043f3F09F50dE5A0d";
    
    const ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_ADMIN_ROLE"));
    const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MINTER_ROLE"));
    const DEFAULT_ADMIN = "0x0000000000000000000000000000000000000000000000000000000000000000";
    
    try {
        const nft = await ethers.getContractAt("OceanMangaNFT_FixedRoles", SECURE_NFT);
        
        console.log("📋 Contract Info:");
        console.log("Address:", SECURE_NFT);
        console.log("Deployer:", deployer.address);
        
        // Verifica se il contratto supporta le funzioni base
        try {
            const name = await nft.name();
            const symbol = await nft.symbol();
            console.log("Name:", name);
            console.log("Symbol:", symbol);
        } catch (e) {
            console.log("⚠️ Name/Symbol non disponibili:", e.message);
        }
        
        // Verifica ruoli usando eventi
        console.log("\n🔍 Checking all possible roles...");
        
        // Verifica DEFAULT_ADMIN_ROLE (dovrebbe essere false)
        const hasDefaultAdmin = await nft.hasRole(DEFAULT_ADMIN, deployer.address);
        console.log("Has DEFAULT_ADMIN_ROLE (should be false):", hasDefaultAdmin);
        
        // Verifica ruoli custom
        const hasAdmin = await nft.hasRole(ADMIN_ROLE, deployer.address);
        const hasMinter = await nft.hasRole(MINTER_ROLE, deployer.address);
        console.log("Has ADMIN_ROLE:", hasAdmin);
        console.log("Has MINTER_ROLE:", hasMinter);
        
        // Se non ha ruoli, proviamo a vedere chi li ha
        if (!hasAdmin && !hasMinter) {
            console.log("\n🔍 Searching for role holders...");
            
            // Il contratto potrebbe essere stato inizializzato con un admin diverso
            // Proviamo a vedere se ci sono eventi di RoleGranted
            
            // Per ora, proviamo a dare ruoli direttamente se abbiamo DEFAULT_ADMIN_ROLE
            if (hasDefaultAdmin) {
                console.log("🔧 Using DEFAULT_ADMIN_ROLE to grant custom roles...");
                try {
                    const grantAdminTx = await nft.grantRole(ADMIN_ROLE, deployer.address);
                    await grantAdminTx.wait();
                    console.log("✅ ADMIN_ROLE granted");
                    
                    const grantMinterTx = await nft.grantRole(MINTER_ROLE, deployer.address);
                    await grantMinterTx.wait();
                    console.log("✅ MINTER_ROLE granted");
                    
                } catch (grantError) {
                    console.log("❌ Cannot grant roles:", grantError.message);
                }
            } else {
                console.log("⚠️ No admin rights - contract might need redeployment");
            }
        }
        
        // Final check
        const finalAdmin = await nft.hasRole(ADMIN_ROLE, deployer.address);
        const finalMinter = await nft.hasRole(MINTER_ROLE, deployer.address);
        const finalDefault = await nft.hasRole(DEFAULT_ADMIN, deployer.address);
        
        console.log("\n📊 FINAL STATUS:");
        console.log("ADMIN_ROLE:", finalAdmin);
        console.log("MINTER_ROLE:", finalMinter);
        console.log("DEFAULT_ADMIN_ROLE:", finalDefault);
        
        if (finalAdmin && finalMinter && !finalDefault) {
            console.log("✅ NFT SICURO CONFIGURATO CORRETTAMENTE!");
            return true;
        } else if (!finalDefault) {
            console.log("✅ SICUREZZA OK (no DEFAULT_ADMIN) ma ruoli mancanti");
            return false;
        } else {
            console.log("⚠️ SICUREZZA COMPROMESSA (ha DEFAULT_ADMIN)");
            return false;
        }
        
    } catch (error) {
        console.error("❌ Investigation error:", error.message);
        return false;
    }
}

investigateNFT()
    .then((success) => {
        if (success) {
            console.log("\n🎉 NFT investigation successful!");
        } else {
            console.log("\n⚠️ NFT needs attention or redeployment");
        }
        process.exit(0);
    })
    .catch((error) => {
        console.error("❌ Fatal error:", error);
        process.exit(1);
    });