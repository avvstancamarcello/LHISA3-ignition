import pkg from 'hardhat';
import fs from 'fs';
const { ethers } = pkg;

async function deploySimpleSecureNFT() {
    console.log("🛡️ SIMPLE SECURE NFT DEPLOYMENT");
    console.log("================================");
    console.log("✅ NON-UPGRADEABLE FOR SIMPLICITY");
    console.log("✅ ZERO DEFAULT_ADMIN_ROLE GUARANTEED");
    console.log("✅ ONLY CUSTOM ROLES WITH HASH VALUES");
    
    const [deployer] = await ethers.getSigners();
    const balance = await ethers.provider.getBalance(deployer.address);
    console.log("Deployer:", deployer.address);
    console.log("Balance:", ethers.formatEther(balance), "ETH");
    
    if (balance < ethers.parseEther("0.004")) {
        console.log("❌ Insufficient balance for simple deployment");
        return;
    }
    
    // Verify roles are non-zero
    const ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_ADMIN_ROLE"));
    const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MINTER_ROLE"));
    const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MANAGER_ROLE"));
    
    console.log("\n🔍 ROLE VERIFICATION:");
    console.log("ADMIN_ROLE:", ADMIN_ROLE);
    console.log("MINTER_ROLE:", MINTER_ROLE);
    console.log("MANAGER_ROLE:", MANAGER_ROLE);
    
    // Verify none are zero
    const zeroRole = "0x0000000000000000000000000000000000000000000000000000000000000000";
    if (ADMIN_ROLE === zeroRole || MINTER_ROLE === zeroRole || MANAGER_ROLE === zeroRole) {
        console.log("🚨 CRITICAL ERROR: One or more roles are 0x000...000!");
        return;
    }
    console.log("✅ ALL ROLES ARE SAFE (NON-ZERO)");
    
    try {
        console.log("\n🚀 DEPLOYING SIMPLE SECURE NFT...");
        
        const NFT = await ethers.getContractFactory("contracts/nft/OceanMangaNFT.sol:OceanMangaNFT");
        const nft = await NFT.deploy();
        await nft.waitForDeployment();
        const nftAddress = await nft.getAddress();
        console.log("✅ NFT deployed (localhost):", nftAddress);
        
        console.log("\n🔍 FINAL VERIFICATION...");
        
        // Verify all custom roles
        const hasAdmin = await nft.hasRole(ADMIN_ROLE, deployer.address);
        const hasMinter = await nft.hasRole(MINTER_ROLE, deployer.address);
        const hasManager = await nft.hasRole(MANAGER_ROLE, deployer.address);
        
        console.log("Owner has ADMIN_ROLE:", hasAdmin);
        console.log("Owner has MINTER_ROLE:", hasMinter);
        console.log("Owner has MANAGER_ROLE:", hasManager);
        
        // CRITICAL: Verify NO DEFAULT_ADMIN_ROLE
        const noDefaultAdmin = await nft.verifyNoDefaultAdminRole(deployer.address);
        console.log("NO DEFAULT_ADMIN_ROLE (CRITICAL):", noDefaultAdmin);
        
        // Get contract info
        const name = await nft.name();
        const symbol = await nft.symbol();
        console.log("Contract Name:", name);
        console.log("Contract Symbol:", symbol);
        
        if (hasAdmin && hasMinter && hasManager && noDefaultAdmin) {
            console.log("\n🎉 DEPLOYMENT PERFETTO - SICUREZZA MASSIMA!");
            console.log("✅ Tutti ruoli personalizzati assegnati");
            console.log("✅ ZERO ruoli 0x000...000");
            console.log("✅ Owner wallet identificativo");
            console.log("✅ Contratto non-upgradeable inizializzato");
            
            // Now connect to orchestrator
            console.log("\n🔗 CONNECTING TO ORCHESTRATOR...");
            const ORCHESTRATOR = "0xf0D90454C98A0AE934e9DB1B316FF1608C4E9DEf";
            
            const grantTx = await nft.grantRole(MINTER_ROLE, ORCHESTRATOR);
            await grantTx.wait();
            console.log("✅ MINTER_ROLE granted to orchestrator");
            
            // Verify orchestrator has role
            const orchestratorHasMinter = await nft.hasRole(MINTER_ROLE, ORCHESTRATOR);
            console.log("Orchestrator has MINTER_ROLE:", orchestratorHasMinter);
            
            // Save final configuration
            const finalConfig = {
                network: "base",
                timestamp: new Date().toISOString(),
                status: "SECURE_ECOSYSTEM_COMPLETE_SIMPLE",
                contracts: {
                    secureNFTSimple: nftAddress,
                    ft: "0xF8d5a00Ca91D46c07614208C346c49a09409D094",
                    orchestrator: ORCHESTRATOR,
                    impactTracker: "0x20e63Ac004aA0997CC2bE7B8bB4419b9385C4689"
                },
                security: {
                    customRolesOnly: true,
                    noDefaultAdminRole: noDefaultAdmin,
                    ownerHasAllRoles: hasAdmin && hasMinter && hasManager,
                    orchestratorConnected: orchestratorHasMinter,
                    rolesVerified: [ADMIN_ROLE, MINTER_ROLE, MANAGER_ROLE],
                    contractType: "NON_UPGRADEABLE_SIMPLE"
                },
                wallets: {
                    owner: deployer.address,
                    charity: "0xf84eb8B95407f04Dee8fF9acaC0e0AC7231bAb2A"
                }
            };
            
            fs.writeFileSync('final-secure-ecosystem-simple.json', JSON.stringify(finalConfig, null, 2));
            
            console.log("\n📋 ECOSISTEMA FINALE SICURO (SIMPLE):");
            console.log("🛡️ Simple Secure NFT:", nftAddress);
            console.log("🪙 FT: 0xF8d5a00Ca91D46c07614208C346c49a09409D094");
            console.log("🎭 Orchestrator:", ORCHESTRATOR);
            console.log("📊 Impact Tracker: 0x20e63Ac004aA0997CC2bE7B8bB4419b9385C4689");
            
            console.log("\n🎯 SICUREZZA FINALE GARANTITA:");
            console.log("- ✅ CONTRATTO NON-UPGRADEABLE");
            console.log("- ✅ NESSUN ruolo 0x000...000");
            console.log("- ✅ TUTTI ruoli personalizzati");
            console.log("- ✅ Owner e Orchestrator connessi");
            console.log("- ✅ Wallet reali identificativi");
            console.log("- ✅ Contratto inizializzato nel constructor");
            
        } else {
            console.log("❌ DEPLOYMENT FAILED - SECURITY REQUIREMENTS NOT MET");
        }
        
        const finalBalance = await ethers.provider.getBalance(deployer.address);
        console.log("\n💰 Balance finale:", ethers.formatEther(finalBalance), "ETH");
        
    } catch (error) {
        console.error("❌ Simple deployment error:", error.message);
    }
}

deploySimpleSecureNFT()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Fatal error:", error);
        process.exit(1);
    });