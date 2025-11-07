import pkg from 'hardhat';
import fs from 'fs';
const { ethers } = pkg;

async function deployFinalSecureNFT() {
    console.log("🛡️ FINAL SECURE NFT DEPLOYMENT");
    console.log("===============================");
    console.log("✅ ZERO DEFAULT_ADMIN_ROLE GUARANTEED");
    console.log("✅ ONLY CUSTOM ROLES WITH HASH VALUES");
    console.log("✅ AUTO-INITIALIZATION WITH ROLE ASSIGNMENT");
    
    const [deployer] = await ethers.getSigners();
    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Deployer:", deployer.address);
    console.log("Balance:", ethers.formatEther(balance), "ETH");
    
    if (balance < ethers.parseEther("0.006")) {
        console.log("❌ Insufficient balance for final deployment");
        return;
    }
    
    // Verify roles are non-zero
    const ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_ADMIN_ROLE"));
    const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MINTER_ROLE"));
    const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MANAGER_ROLE"));
    const UPGRADER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_UPGRADER_ROLE"));
    
    console.log("\n🔍 ROLE VERIFICATION:");
    console.log("ADMIN_ROLE:", ADMIN_ROLE);
    console.log("MINTER_ROLE:", MINTER_ROLE);
    console.log("MANAGER_ROLE:", MANAGER_ROLE);
    console.log("UPGRADER_ROLE:", UPGRADER_ROLE);
    
    // Verify none are zero
    const zeroRole = "0x0000000000000000000000000000000000000000000000000000000000000000";
    if (ADMIN_ROLE === zeroRole || MINTER_ROLE === zeroRole || MANAGER_ROLE === zeroRole || UPGRADER_ROLE === zeroRole) {
        console.log("🚨 CRITICAL ERROR: One or more roles are 0x000...000!");
        return;
    }
    console.log("✅ ALL ROLES ARE SAFE (NON-ZERO)");
    
    try {
        console.log("\n🚀 DEPLOYING FINAL SECURE NFT...");
        
        const NFTFinal = await ethers.getContractFactory("OceanMangaNFT_SecureFinal");
        const nftFinal = await NFTFinal.deploy({
            gasLimit: 8000000
        });
        
        console.log("⏳ Waiting for deployment...");
        await nftFinal.waitForDeployment();
        
        const nftAddress = await nftFinal.getAddress();
        console.log("✅ FINAL SECURE NFT DEPLOYED:", nftAddress);
        
        console.log("\n🔧 INITIALIZING WITH GUARANTEED SECURE ROLES...");
        const initTx = await nftFinal.initialize(
            deployer.address,              // admin - TUO WALLET REALE
            "https://ipfs.io/ipfs/",      // base URI
            "OceanManga NFT Final",        // name  
            "OMNFTF",                      // symbol
            deployer.address,              // royalty receiver
            500                            // royalty 5%
        );
        
        await initTx.wait();
        console.log("✅ NFT INITIALIZED WITH SECURE ROLES");
        
        console.log("\n🔍 FINAL VERIFICATION...");
        
        // Verify all custom roles
        const hasAdmin = await nftFinal.hasRole(ADMIN_ROLE, deployer.address);
        const hasMinter = await nftFinal.hasRole(MINTER_ROLE, deployer.address);
        const hasManager = await nftFinal.hasRole(MANAGER_ROLE, deployer.address);
        const hasUpgrader = await nftFinal.hasRole(UPGRADER_ROLE, deployer.address);
        
        console.log("Owner has ADMIN_ROLE:", hasAdmin);
        console.log("Owner has MINTER_ROLE:", hasMinter);
        console.log("Owner has MANAGER_ROLE:", hasManager);
        console.log("Owner has UPGRADER_ROLE:", hasUpgrader);
        
        // CRITICAL: Verify NO DEFAULT_ADMIN_ROLE
        const noDefaultAdmin = await nftFinal.verifyNoDefaultAdminRole(deployer.address);
        console.log("NO DEFAULT_ADMIN_ROLE (CRITICAL):", noDefaultAdmin);
        
        // Get contract info
        const name = await nftFinal.name();
        const symbol = await nftFinal.symbol();
        console.log("Contract Name:", name);
        console.log("Contract Symbol:", symbol);
        
        if (hasAdmin && hasMinter && hasManager && hasUpgrader && noDefaultAdmin) {
            console.log("\n🎉 DEPLOYMENT PERFETTO - SICUREZZA MASSIMA!");
            console.log("✅ Tutti ruoli personalizzati assegnati");
            console.log("✅ ZERO ruoli 0x000...000");
            console.log("✅ Owner wallet identificativo");
            console.log("✅ Inizializzazione completata");
            
            // Now connect to orchestrator
            console.log("\n🔗 CONNECTING TO ORCHESTRATOR...");
            const ORCHESTRATOR = "0xf0D90454C98A0AE934e9DB1B316FF1608C4E9DEf";
            
            const grantTx = await nftFinal.grantRole(MINTER_ROLE, ORCHESTRATOR);
            await grantTx.wait();
            console.log("✅ MINTER_ROLE granted to orchestrator");
            
            // Verify orchestrator has role
            const orchestratorHasMinter = await nftFinal.hasRole(MINTER_ROLE, ORCHESTRATOR);
            console.log("Orchestrator has MINTER_ROLE:", orchestratorHasMinter);
            
            // Save final configuration
            const finalConfig = {
                network: "base",
                timestamp: new Date().toISOString(),
                status: "SECURE_ECOSYSTEM_FINAL_COMPLETE",
                contracts: {
                    secureNFTFinal: nftAddress,
                    ft: "0xF8d5a00Ca91D46c07614208C346c49a09409D094",
                    orchestrator: ORCHESTRATOR,
                    impactTracker: "0x20e63Ac004aA0997CC2bE7B8bB4419b9385C4689"
                },
                security: {
                    customRolesOnly: true,
                    noDefaultAdminRole: noDefaultAdmin,
                    ownerHasAllRoles: hasAdmin && hasMinter && hasManager && hasUpgrader,
                    orchestratorConnected: orchestratorHasMinter,
                    rolesVerified: [ADMIN_ROLE, MINTER_ROLE, MANAGER_ROLE, UPGRADER_ROLE]
                },
                wallets: {
                    owner: deployer.address,
                    charity: "0xf84eb8B95407f04Dee8fF9acaC0e0AC7231bAb2A"
                }
            };
            
            fs.writeFileSync('final-secure-ecosystem.json', JSON.stringify(finalConfig, null, 2));
            
            console.log("\n📋 ECOSISTEMA FINALE SICURO:");
            console.log("🛡️ Final Secure NFT:", nftAddress);
            console.log("🪙 FT: 0xF8d5a00Ca91D46c07614208C346c49a09409D094");
            console.log("🎭 Orchestrator:", ORCHESTRATOR);
            console.log("📊 Impact Tracker: 0x20e63Ac004aA0997CC2bE7B8bB4419b9385C4689");
            
            console.log("\n🎯 SICUREZZA FINALE GARANTITA:");
            console.log("- ✅ NESSUN ruolo 0x000...000");
            console.log("- ✅ TUTTI ruoli personalizzati");
            console.log("- ✅ Owner e Orchestrator connessi");
            console.log("- ✅ Wallet reali identificativi");
            console.log("- ✅ Contratto inizializzato correttamente");
            
        } else {
            console.log("❌ DEPLOYMENT FAILED - SECURITY REQUIREMENTS NOT MET");
        }
        
        const finalBalance = await ethers.provider.getBalance(deployer.address);
        console.log("\n💰 Balance finale:", ethers.formatEther(finalBalance), "ETH");
        
    } catch (error) {
        console.error("❌ Final deployment error:", error.message);
    }
}

deployFinalSecureNFT()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Fatal error:", error);
        process.exit(1);
    });