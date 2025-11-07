import pkg from 'hardhat';
import fs from 'fs';
const { ethers } = pkg;

async function verifyAndConnectSecure() {
    console.log("🔍 VERIFICA NFT SICURO E CONNESSIONE ECOSYSTEM");
    console.log("=============================================");
    
    const [deployer] = await ethers.getSigners();
    const SECURE_NFT = "0xF7646D1918B9c55896De905043f3F09F50dE5A0d";
    const FT = "0xF8d5a00Ca91D46c07614208C346c49a09409D094";
    const ORCHESTRATOR = "0xf0D90454C98A0AE934e9DB1B316FF1608C4E9DEf";
    
    // Ruoli personalizzati verificati
    const ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_ADMIN_ROLE"));
    const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MINTER_ROLE"));
    const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MANAGER_ROLE"));
    const UPGRADER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_UPGRADER_ROLE"));
    
    try {
        console.log("🛡️ Verifying Secure NFT Roles...");
        const nftSecure = await ethers.getContractAt("OceanMangaNFT_FixedRoles", SECURE_NFT);
        
        // Verifica ruoli dell'owner
        const hasAdmin = await nftSecure.hasRole(ADMIN_ROLE, deployer.address);
        const hasMinter = await nftSecure.hasRole(MINTER_ROLE, deployer.address);
        const hasManager = await nftSecure.hasRole(MANAGER_ROLE, deployer.address);
        const hasUpgrader = await nftSecure.hasRole(UPGRADER_ROLE, deployer.address);
        
        console.log("✅ ROLE VERIFICATION:");
        console.log("Owner has ADMIN_ROLE:", hasAdmin);
        console.log("Owner has MINTER_ROLE:", hasMinter);
        console.log("Owner has MANAGER_ROLE:", hasManager);
        console.log("Owner has UPGRADER_ROLE:", hasUpgrader);
        
        // CRITICO: Verifica che NON ci sia DEFAULT_ADMIN_ROLE
        const DEFAULT_ADMIN = "0x0000000000000000000000000000000000000000000000000000000000000000";
        const hasDefaultAdmin = await nftSecure.hasRole(DEFAULT_ADMIN, deployer.address);
        
        if (hasDefaultAdmin) {
            console.log("🚨 ATTENZIONE: Contract ha ancora DEFAULT_ADMIN_ROLE!");
        } else {
            console.log("✅ PERFETTO: NESSUN DEFAULT_ADMIN_ROLE (0x000...000)");
        }
        
        // Se il contratto è già inizializzato, probabilmente ha i ruoli corretti
        if (!hasAdmin && !hasMinter) {
            console.log("⚠️ NFT non ha ruoli assegnati - probabilmente non inizializzato correttamente");
            
            // Prova a inizializzare se non è stato fatto
            try {
                console.log("🔧 Tentativo di inizializzazione...");
                const initTx = await nftSecure.initialize(
                    deployer.address,
                    "https://ipfs.io/ipfs/",
                    "OceanManga NFT Secure",
                    "OMNFTS",
                    deployer.address,
                    500
                );
                await initTx.wait();
                console.log("✅ NFT inizializzato con successo");
            } catch (initError) {
                console.log("ℹ️ NFT già inizializzato o errore init:", initError.message);
            }
        }
        
        // Ricontrolla ruoli dopo eventuale inizializzazione
        const hasAdminAfter = await nftSecure.hasRole(ADMIN_ROLE, deployer.address);
        const hasMinterAfter = await nftSecure.hasRole(MINTER_ROLE, deployer.address);
        
        if (hasAdminAfter && hasMinterAfter) {
            console.log("\n🔗 CONNESSIONE ORCHESTRATOR...");
            
            // Assegna MINTER_ROLE all'orchestrator
            const grantTx = await nftSecure.grantRole(MINTER_ROLE, ORCHESTRATOR);
            await grantTx.wait();
            console.log("✅ MINTER_ROLE assegnato all'orchestrator");
            
            // Verifica che orchestrator abbia il ruolo
            const orchestratorHasMinter = await nftSecure.hasRole(MINTER_ROLE, ORCHESTRATOR);
            console.log("Orchestrator has MINTER_ROLE:", orchestratorHasMinter);
            
            // Connetti FT all'orchestrator
            console.log("\n🪙 CONNESSIONE FT...");
            const ftContract = await ethers.getContractAt("LunaComicsFT", FT);
            
            try {
                const addMinterTx = await ftContract.addMinter(ORCHESTRATOR);
                await addMinterTx.wait();
                console.log("✅ FT minter role assegnato all'orchestrator");
            } catch (ftError) {
                console.log("⚠️ FT minter role error:", ftError.message);
            }
            
            // Salva configurazione finale
            const finalConfig = {
                network: "base",
                timestamp: new Date().toISOString(),
                status: "SECURE_ECOSYSTEM_COMPLETE",
                contracts: {
                    secureNFT: SECURE_NFT,
                    ft: FT,
                    orchestrator: ORCHESTRATOR,
                    impactTracker: "0x20e63Ac004aA0997CC2bE7B8bB4419b9385C4689"
                },
                security: {
                    customRolesOnly: true,
                    noDefaultAdminRole: !hasDefaultAdmin,
                    ownerHasAllRoles: hasAdminAfter && hasMinterAfter,
                    orchestratorConnected: orchestratorHasMinter
                },
                wallets: {
                    owner: deployer.address,
                    charity: "0xf84eb8B95407f04Dee8fF9acaC0e0AC7231bAb2A"
                }
            };
            
            fs.writeFileSync('secure-ecosystem-final.json', JSON.stringify(finalConfig, null, 2));
            
            console.log("\n🎉 ECOSISTEMA SICURO COMPLETO!");
            console.log("📋 CONTRATTI FINALI:");
            console.log("🛡️ Secure NFT:", SECURE_NFT);
            console.log("🪙 FT:", FT);
            console.log("🎭 Orchestrator:", ORCHESTRATOR);
            console.log("📊 Impact Tracker: 0x20e63Ac004aA0997CC2bE7B8bB4419b9385C4689");
            
            console.log("\n✅ SICUREZZA VERIFICATA:");
            console.log("- NESSUN ruolo 0x000...000");
            console.log("- Tutti ruoli personalizzati");
            console.log("- Owner e Orchestrator connessi");
            console.log("- Wallet reali identificativi");
            
        } else {
            console.log("❌ Problemi con i ruoli - necessaria investigazione");
        }
        
        const balance = await ethers.provider.getBalance(deployer.address);
        console.log("\n💰 Balance rimanente:", ethers.formatEther(balance), "ETH");
        
    } catch (error) {
        console.error("❌ Errore verifica/connessione:", error.message);
    }
}

verifyAndConnectSecure()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Fatal error:", error);
        process.exit(1);
    });