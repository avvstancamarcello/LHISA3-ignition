// 🚀 SCRIPT ULTRA-SEMPLICE - GAS PRICE CORRETTO
const { ethers } = require("ethers");

// ✅ PRIVATE KEY DIRETTA
const PRIVATE_KEY = "8f2a46c1eb83a1fcec604207c4c0e34c2b46b2d045883311509cb592b282dfb1";
const POLYGON_RPC = "https://solitary-purple-slug.base-mainnet.quiknode.pro/e5449e4ea283373090b772e7fc87ee7ad5218d72";
const NFT_STORAGE_API_KEY="d36ca24b490aae57a698"

async function main() {
    console.log("🚀 DEPLOY ULTRA-SEMPLICE SU POLYGON");
    console.log("===================================");
    
    const provider = new ethers.providers.JsonRpcProvider(POLYGON_RPC);
    const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
    
    console.log("👛 Deployer:", wallet.address);
    console.log("💰 Balance:", ethers.utils.formatEther(await provider.getBalance(wallet.address)), "POL");
    
    // ✅ OTTIENI GAS PRICE AGGIORNATO
    const feeData = await provider.getFeeData();
    const gasPrice = feeData.gasPrice.mul(2); // ✅ RADDOPPIA PER SICUREZZA
    
    console.log("⛽ Gas Price:", ethers.utils.formatUnits(gasPrice, "gwei"), "gwei");
    
    const deployOptions = {
        gasPrice: gasPrice,
        gasLimit: 5000000
    };
    
    // 1. DEPLOY SOLIDARY METRICS
    console.log("\n📊 Deploying SolidaryMetrics...");
    const metricsArtifact = require("../artifacts/contracts/stellar/SolidaryMetrics.sol/SolidaryMetrics.json");
    const MetricsFactory = new ethers.ContractFactory(metricsArtifact.abi, metricsArtifact.bytecode, wallet);
    const metrics = await MetricsFactory.deploy(deployOptions);
    await metrics.deployed();
    console.log("✅ SolidaryMetrics:", metrics.address);
    
    // 2. DEPLOY MAREA MANGA NFT
    console.log("\n🌍 Deploying MareaMangaNFT...");
    const mareaMangaArtifact = require("../artifacts/contracts/planetary/MareaMangaNFT.sol/MareaMangaNFT.json");
    const MareaMangaFactory = new ethers.ContractFactory(mareaMangaArtifact.abi, mareaMangaArtifact.bytecode, wallet);
    const mareaManga = await MareaMangaFactory.deploy(deployOptions);
    await mareaManga.deployed();
    console.log("✅ MareaMangaNFT:", mareaManga.address);
    
    // 3. DEPLOY LUNA COMICS FT
    console.log("\n🌙 Deploying LunaComicsFT...");
    const lunaComicsArtifact = require("../artifacts/contracts/satellites/LunaComicsFT.sol/LunaComicsFT.json");
    const LunaComicsFactory = new ethers.ContractFactory(lunaComicsArtifact.abi, lunaComicsArtifact.bytecode, wallet);
    const lunaComics = await LunaComicsFactory.deploy(deployOptions);
    await lunaComics.deployed();
    console.log("✅ LunaComicsFT:", lunaComics.address);
    
    console.log("\n🎉 DEPLOYMENT COMPLETATO!");
    console.log("📊 SolidaryMetrics:", metrics.address);
    console.log("🌍 MareaMangaNFT:", mareaManga.address);
    console.log("🌙 LunaComicsFT:", lunaComics.address);
}

main().catch(console.error);

