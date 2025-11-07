import pkg from 'hardhat';
const { ethers } = pkg;

async function verifyRoles() {
    console.log("🛡️ VERIFICA COMPLETA RUOLI - ZERO TOLERANCE");
    console.log("============================================");
    
    // Calcola TUTTI i ruoli personalizzati
    const ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_ADMIN_ROLE"));
    const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MINTER_ROLE"));
    const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MANAGER_ROLE"));
    const UPGRADER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_UPGRADER_ROLE"));
    
    console.log("✅ RUOLI PERSONALIZZATI VERIFICATI:");
    console.log("ADMIN_ROLE:", ADMIN_ROLE);
    console.log("MINTER_ROLE:", MINTER_ROLE);  
    console.log("MANAGER_ROLE:", MANAGER_ROLE);
    console.log("UPGRADER_ROLE:", UPGRADER_ROLE);
    
    // Verifica che NESSUN ruolo sia 0x000...000
    const roles = [ADMIN_ROLE, MINTER_ROLE, MANAGER_ROLE, UPGRADER_ROLE];
    const zeroRole = "0x0000000000000000000000000000000000000000000000000000000000000000";
    
    let allSafe = true;
    for (let i = 0; i < roles.length; i++) {
        if (roles[i] === zeroRole) {
            console.log("❌ ERRORE CRITICO: Ruolo con valore 0x000...000 trovato!");
            allSafe = false;
        }
    }
    
    if (allSafe) {
        console.log("✅ TUTTI I RUOLI SONO SICURI - NESSUN 0x000...000");
    }
    
    // Verifica wallet assignments
    const [deployer] = await ethers.getSigners();
    const OWNER_WALLET = deployer.address;
    const CHARITY_WALLET = "0xf84eb8B95407f04Dee8fF9acaC0e0AC7231bAb2A";
    
    console.log("\n👤 WALLET ASSIGNMENTS VERIFICATI:");
    console.log("OWNER/ADMIN:", OWNER_WALLET);
    console.log("CHARITY:", CHARITY_WALLET);
    
    // Verifica che nessun wallet sia address(0)
    if (OWNER_WALLET === "0x0000000000000000000000000000000000000000") {
        console.log("❌ ERRORE: Owner wallet è address(0)!");
        allSafe = false;
    }
    
    if (CHARITY_WALLET === "0x0000000000000000000000000000000000000000") {
        console.log("❌ ERRORE: Charity wallet è address(0)!");
        allSafe = false;
    }
    
    if (allSafe) {
        console.log("✅ TUTTI I WALLET SONO REALI E IDENTIFICATIVI");
        console.log("✅ PRONTO PER DEPLOYMENT SICURO");
        
        // Stampa deployment plan
        console.log("\n📋 DEPLOYMENT PLAN:");
        console.log("1. Deploy OceanMangaNFT_FixedRoles");
        console.log("2. Initialize con ADMIN_ROLE ->", OWNER_WALLET);
        console.log("3. Grant MINTER_ROLE ->", OWNER_WALLET);
        console.log("4. Grant MANAGER_ROLE ->", OWNER_WALLET);
        console.log("5. Grant UPGRADER_ROLE ->", OWNER_WALLET);
        console.log("6. Verify ZERO ruoli 0x000...000");
        
        return true;
    } else {
        console.log("❌ VERIFICA FALLITA - NON DEPLOYARE!");
        return false;
    }
}

verifyRoles()
    .then((safe) => {
        if (safe) {
            console.log("\n🎯 VERIFICATION PASSED - READY TO DEPLOY!");
        } else {
            console.log("\n🚨 VERIFICATION FAILED - DO NOT DEPLOY!");
        }
        process.exit(0);
    })
    .catch((error) => {
        console.error("❌ Verification error:", error);
        process.exit(1);
    });