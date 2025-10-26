// deploy_core_ecosystem_final.cjs

// USARE SOLO L'IMPORT MINIMO NECESSARIO
const hre = require("hardhat");
// Non definire const { upgrades } = hre; qui.

// Funzione di utilità per logging con separatore
function logSeparator(message) {
    console.log(`\n======================================================`);
    console.log(`[DEPLOY LOG] ${message}`);
    console.log(`======================================================`);
}

// Funzione di utilità per forzare un ritardo asincrono (sleep)
function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
    // Definizione delle variabili locali essenziali direttamente dall'ambiente Hardhat
    const ethers = hre.ethers;
    const network = hre.network;
    const upgrades = hre.upgrades; // ⬅️ L'UNICA CHIAMATA VALIDA PER GLI UPGRADES

    logSeparator(`🚀 Inizio Deployment Modulare su rete: ${network.name}`);
    console.log(`⏳ Attesa forzata di 5 secondi per caricamento plugin (Soluzione Latenza)...`);
    await sleep(5000);
    console.log(`✅ Plugin caricato. Deploy in corso.`);

    const [deployer] = await ethers.getSigners();
    console.log(`Indirizzo del Deployer: ${deployer.address}`);

    // =========================================================================================
    // FASE 1: Foundational Infrastructure (I Pilastri - Deployment UUPS)
    // =========================================================================================
    logSeparator(`FASE 1: Deploy dei Pilastri (Utilities & Managers)`);

    // 1. EnhancedImpactLogger
    console.log(`[01/11] Deploying EnhancedImpactLogger...`);
    const ImpactLoggerFactory = await ethers.getContractFactory("EnhancedImpactLogger");
    const impactLogger = await upgrades.deployProxy(ImpactLoggerFactory, [], { initializer: 'initialize', timeout: 300000 });
    await impactLogger.waitForDeployment();
    const impactLoggerAddress = await impactLogger.getAddress();
    console.log(`✅ 1. EnhancedImpactLogger deployato a: ${impactLoggerAddress}`);

    // 2. EnhancedReputationManager
    console.log(`[02/11] Deploying EnhancedReputationManager...`);
    const ReputationManagerFactory = await ethers.getContractFactory("EnhancedReputationManager");
    const reputationManager = await upgrades.deployProxy(ReputationManagerFactory, [], { initializer: 'initialize', timeout: 300000 });
    await reputationManager.waitForDeployment();
    const reputationManagerAddress = await reputationManager.getAddress();
    console.log(`✅ 2. EnhancedReputationManager deployato a: ${reputationManagerAddress}`);

    // 3. EnhancedSolidaryTrustManager
    console.log(`[03/11] Deploying EnhancedSolidaryTrustManager...`);
    const TrustManagerFactory = await ethers.getContractFactory("EnhancedSolidaryTrustManager");
    // Nota: Ho lasciato i placeholder per i ruoli iniziali come nella tua bozza
    const trustManager = await upgrades.deployProxy(TrustManagerFactory, [deployer.address, deployer.address, deployer.address], { initializer: 'initialize', timeout: 300000 });
    await trustManager.waitForDeployment();
    const trustManagerAddress = await trustManager.getAddress();
    console.log(`✅ 3. EnhancedSolidaryTrustManager deployato a: ${trustManagerAddress}`);

    // 4. SolidaryMetrics
    console.log(`[04/11] Deploying SolidaryMetrics...`);
    const MetricsFactory = await ethers.getContractFactory("SolidaryMetrics");
    const metrics = await upgrades.deployProxy(MetricsFactory, [], { initializer: 'initialize', timeout: 300000 });
    await metrics.waitForDeployment();
    const metricsAddress = await metrics.getAddress();
    console.log(`✅ 4. SolidaryMetrics deployato a: ${metricsAddress}`);

    // 5. EnhancedModuleRouter
    console.log(`[05/11] Deploying EnhancedModuleRouter...`);
    const ModuleRouterFactory = await ethers.getContractFactory("EnhancedModuleRouter");
    const moduleRouter = await upgrades.deployProxy(ModuleRouterFactory, [deployer.address], { initializer: 'initialize', timeout: 300000 });
    await moduleRouter.waitForDeployment();
    const moduleRouterAddress = await moduleRouter.getAddress();
    console.log(`✅ 5. EnhancedModuleRouter deployato a: ${moduleRouterAddress}`);

    // 6. UniversalMultiChainOrchestratorV2 (ALTO RISCHIO BYTECODE)
    console.log(`[06/11] Deploying UniversalMultiChainOrchestratorV2 (RISCHIO BYTECODE)...`);
    const OrchestratorFactory = await ethers.getContractFactory("UniversalMultiChainOrchestratorV2");
    const orchestrator = await upgrades.deployProxy(OrchestratorFactory, [deployer.address], { initializer: 'initialize', timeout: 300000 });
    await orchestrator.waitForDeployment();
    const orchestratorAddress = await orchestrator.getAddress();
    console.log(`✅ 6. UniversalMultiChainOrchestratorV2 deployato a: ${orchestratorAddress}`);


    // =========================================================================================
    // FASE 2: Core Hub (Il Cervello - Deployment & Inizializzazione)
    // =========================================================================================
    logSeparator(`FASE 2: Deploy del Core Hub (HUB)`);

    // 7. EnhancedSolidaryHub (ALTO RISCHIO BYTECODE)
    console.log(`[07/11] Deploying EnhancedSolidaryHub (RISCHIO BYTECODE)...`);
    const HubFactory = await ethers.getContractFactory("EnhancedSolidaryHub");
    const hub = await upgrades.deployProxy(HubFactory, [deployer.address], { initializer: 'initialize', timeout: 300000 });
    await hub.waitForDeployment();
    const hubAddress = await hub.getAddress();
    console.log(`✅ 7. EnhancedSolidaryHub deployato a: ${hubAddress}`);

    // 8. Inizializzazione Core Ecosystem (Registra i moduli di FASE 1 e 2 nel Hub)
    console.log(`   - Chiamata initializeEcosystem (Registrazione di 6 Moduli Core)...`);

    const txInit = await hub.initializeEcosystem(
        hubAddress,
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        metricsAddress,
        reputationManagerAddress,
        impactLoggerAddress,
        moduleRouterAddress,
        orchestratorAddress
    );
    await txInit.wait();
    console.log(`   ✅ Hub Inizializzato. Moduli Core Registrati.`);


    // =========================================================================================
    // FASE 3: High-Level Modules & Tokens (Body - Deployment & Registration)
    // =========================================================================================
    logSeparator(`FASE 3: Deploy di Token e Governance`);

    // 9. OceanMangaNFT (Pianeta)
    console.log(`[08/11] Deploying OceanMangaNFT (Pianeta)...`);
    const NFTFactory = await ethers.getContractFactory("OceanMangaNFT");
    const nft = await upgrades.deployProxy(NFTFactory, [hubAddress, deployer.address, "OceanManga", "OMNFT", "ipfs://base/uri/"], { initializer: 'initialize', timeout: 300000 });
    await nft.waitForDeployment();
    const nftAddress = await nft.getAddress();
    console.log(`✅ 9. OceanMangaNFT (Pianeta) deployato a: ${nftAddress}`);

    // 10. LunaComicsFT (Satellite)
    console.log(`[09/11] Deploying LunaComicsFT (Satellite)...`);
    const FTFactory = await ethers.getContractFactory("LunaComicsFT");
    const ft = await upgrades.deployProxy(FTFactory, [deployer.address, "LunaComics", "LUNA", ethers.parseEther("1000000"), deployer.address], { initializer: 'initialize', timeout: 300000 });
    await ft.waitForDeployment();
    const ftAddress = await ft.getAddress();
    console.log(`✅ 10. LunaComicsFT (Satellite) deployato a: ${ftAddress}`);

    // 11. EnhancedOraculumCaritatis (Giustizia/Oracolo)
    console.log(`[10/11] Deploying EnhancedOraculumCaritatis (Oracolo)...`);
    const OraculumFactory = await ethers.getContractFactory("EnhancedOraculumCaritatis");
    const oraculum = await upgrades.deployProxy(OraculumFactory, [deployer.address, hubAddress], { initializer: 'initialize', timeout: 300000 });
    await oraculum.waitForDeployment();
    const oraculumAddress = await oraculum.getAddress();
    console.log(`✅ 11. EnhancedOraculumCaritatis deployato a: ${oraculumAddress}`);

    // =========================================================================================
    // FASE 4: Finalizzazione e Registrazione Moduli di FASE 3
    // =========================================================================================
    logSeparator(`FASE 4: Finalizzazione e Registrazione (3 Moduli)`);

    // Aggiorna Hub con i riferimenti a NFT e FT
    const txUpdateNFT = await hub.setModuleAddress("OceanMangaNFT", nftAddress);
    await txUpdateNFT.wait();
    console.log(`   - Aggiornato riferimento NFT nel Hub.`);

    const txUpdateFT = await hub.setModuleAddress("LunaComicsFT", ftAddress);
    await txUpdateFT.wait();
    console.log(`   - Aggiornato riferimento FT nel Hub.`);

    // Registrazione Completa degli ultimi moduli
    const metadataNFT = "Initial NFT metadata CID";
    const metadataFT = "Initial FT metadata CID";
    const metadataOraculum = "Initial Oraculum metadata CID";

    // Tipo 2: Token NFT, Tipo 3: Token FT, Tipo 4: Governance/Oracolo
    await hub.registerEnhancedModule(nftAddress, "OceanMangaNFT", 2, "nft", [], metadataNFT);
    await hub.registerEnhancedModule(ftAddress, "LunaComicsFT", 3, "ft", [], metadataFT);
    await hub.registerEnhancedModule(oraculumAddress, "EnhancedOraculumCaritatis", 4, "governance", [], metadataOraculum);
    console.log(`   ✅ Registrazione finale dei Token e Oraculum completata.`);

    logSeparator(`🎉 SUCCESSO TOTALE: Ecosistema Base Solidary DEPLOYATO`);
    console.log(`HUB Address: ${hubAddress}`);
    console.log(`NFT Address: ${nftAddress}`);
    console.log(`FT Address: ${ftAddress}`);
    console.log(`------------------------------------------------------`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
