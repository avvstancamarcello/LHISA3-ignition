// 🚀 DEPLOY CONTRATTI MANCANTI SU POLYGON
const { ethers } = require("ethers");

const PRIVATE_KEY = "8f2a46c1eb83a1fcec604207c4c0e34c2b46b2d045883311509cb592b282dfb1";
const POLYGON_RPC = "https://aged-tiniest-frost.matic.quiknode.pro/b50bb4625032afb94b57bf5efd608270059e0da8";
const NFT_STORAGE_API_KEY="d36ca24b490aae57a698"

// ✅ ORCHESTRATOR già deployato
const EXISTING_ORCHESTRATOR = "0x55A419ad18AB7333cA12f6fF6144aF7B9d7fB1AB";

async function main() {
    console.log("🚀 DEPLOY CONTRATTI MANCANTI SU POLYGON");
    console.log("=======================================");
    
    const provider = new ethers.providers.JsonRpcProvider(POLYGON_RPC);
    const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
    
    console.log("👛 Deployer:", wallet.address);
    console.log("💰 Balance:", ethers.utils.formatEther(await provider.getBalance(wallet.address)), "POL");
    
    // ✅ GAS PRICE ALTO
    const gasPrice = ethers.utils.parseUnits("50", "gwei");
    console.log("⛽ Gas Price:", ethers.utils.formatUnits(gasPrice, "gwei"), "gwei");
    
    const deployOptions = {
        gasPrice: gasPrice,
        gasLimit: 5000000
    };
    
    // 1. 📊 DEPLOY SOLIDARY METRICS
    console.log("\n📊 Deploying SolidaryMetrics...");
    const metricsArtifact = require("../artifacts/contracts/stellar/SolidaryMetrics.sol/SolidaryMetrics.json");
    const MetricsFactory = new ethers.ContractFactory(metricsArtifact.abi, metricsArtifact.bytecode, wallet);
    const metrics = await MetricsFactory.deploy(deployOptions);
    await metrics.deployed();
    const metricsAddress = metrics.address;
    console.log("✅ SolidaryMetrics:", metricsAddress);
    
    // 2. 🌍 DEPLOY MAREA MANGA NFT
    console.log("\n🌍 Deploying MareaMangaNFT...");
    const mareaMangaArtifact = require("../artifacts/contracts/planetary/MareaMangaNFT.sol/MareaMangaNFT.json");
    const MareaMangaFactory = new ethers.ContractFactory(mareaMangaArtifact.abi, mareaMangaArtifact.bytecode, wallet);
    const mareaManga = await MareaMangaFactory.deploy(deployOptions);
    await mareaManga.deployed();
    const mareaMangaAddress = mareaManga.address;
    console.log("✅ MareaMangaNFT:", mareaMangaAddress);
    
    // 3. 🌙 DEPLOY LUNA COMICS FT
    console.log("\n🌙 Deploying LunaComicsFT...");
    const lunaComicsArtifact = require("../artifacts/contracts/satellites/LunaComicsFT.sol/LunaComicsFT.json");
    const LunaComicsFactory = new ethers.ContractFactory(lunaComicsArtifact.abi, lunaComicsArtifact.bytecode, wallet);
    const lunaComics = await LunaComicsFactory.deploy(deployOptions);
    await lunaComics.deployed();
    const lunaComicsAddress = lunaComics.address;
    console.log("✅ LunaComicsFT:", lunaComicsAddress);
    
    console.log("\n🎉 TUTTI I CONTRATTI DEPLOYATI!");
    console.log("==============================");
    console.log("👑 SolidaryOrchestrator:", EXISTING_ORCHESTRATOR);
    console.log("📊 SolidaryMetrics:", metricsAddress);
    console.log("🌍 MareaMangaNFT:", mareaMangaAddress);
    console.log("🌙 LunaComicsFT:", lunaComicsAddress);
    console.log("==============================");
    
    // 🔗 COLLEGA L'ECOSISTEMA
    console.log("\n🔗 Collegamento ecosistema...");
    try {
        // Inizializza Metrics con Orchestrator
        await metrics.initialize(EXISTING_ORCHESTRATOR, mareaMangaAddress, lunaComicsAddress);
        console.log("✅ Metrics initialized with Orchestrator");
        
        // Inizializza NFT
        await mareaManga.initialize();
        console.log("✅ MareaMangaNFT initialized");
        
        // Inizializza FT
        await lunaComics.initialize();
        console.log("✅ LunaComicsFT initialized");
        
    } catch (error) {
        console.log("⚠️ Initialization note:", error.message);
    }
    
    // 💾 Salva nuovi indirizzi
    const fs = require("fs");
    const ecosystemUpdate = {
        network: "Polygon Mainnet",
        timestamp: new Date().toISOString(),
        contracts: {
            orchestrator: EXISTING_ORCHESTRATOR,
            metrics: metricsAddress,
            nftPlanet: mareaMangaAddress,
            ftSatellite: lunaComicsAddress
        },
        note: "Updated with missing contracts deployment"
    };
    
    fs.writeFileSync("polygon-ecosystem-complete-updated.json", JSON.stringify(ecosystemUpdate, null, 2));
    console.log("\n💾 Ecosystem updated: polygon-ecosystem-complete-updated.json");
}

main().catch(console.error);
