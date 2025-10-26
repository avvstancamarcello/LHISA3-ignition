// 🚀 SCRIPT DEPLOY SEMPLIFICATO - EVITA CONFLITTI ETHERS
const deployKeys = require("../deploy-keys.temp.js");

// Imposta variabili d'ambiente
process.env.PRIVATE_KEY = deployKeys.PRIVATE_KEY;

console.log("🚀 DEPLOY SEMPLIFICATO SU POLYGON");
console.log("=================================");

async function main() {
    // ✅ USA ETHERS DIRETTAMENTE invece di Hardhat
    const { ethers } = require("ethers");
    
    const provider = new ethers.providers.JsonRpcProvider("https://aged-tiniest-frost.matic.quiknode.pro/b50bb4625032afb94b57bf5efd608270059e0da8m");
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
    
    console.log("👛 Deployer:", wallet.address);
    console.log("💰 Balance:", ethers.utils.formatEther(await provider.getBalance(wallet.address)), "MATIC");
    
    // 1. DEPLOY SOLIDARY METRICS
    console.log("\n📊 Deploying SolidaryMetrics...");
    const SolidaryMetrics = await ethers.getContractFactory("SolidaryMetrics", wallet);
    const metrics = await SolidaryMetrics.deploy();
    await metrics.deployed();
    console.log("✅ SolidaryMetrics:", metrics.address);
    
    // 2. DEPLOY MAREA MANGA NFT
    console.log("\n🌍 Deploying MareaMangaNFT...");
    const MareaMangaNFT = await ethers.getContractFactory("MareaMangaNFT", wallet);
    const mareaManga = await MareaMangaNFT.deploy();
    await mareaManga.deployed();
    console.log("✅ MareaMangaNFT:", mareaManga.address);
    
    // 3. DEPLOY LUNA COMICS FT
    console.log("\n🌙 Deploying LunaComicsFT...");
    const LunaComicsFT = await ethers.getContractFactory("LunaComicsFT", wallet);
    const lunaComics = await LunaComicsFT.deploy();
    await lunaComics.deployed();
    console.log("✅ LunaComicsFT:", lunaComics.address);
    
    console.log("\n🎉 DEPLOYMENT COMPLETATO!");
    console.log("========================");
    console.log("📊 SolidaryMetrics:", metrics.address);
    console.log("🌍 MareaMangaNFT:", mareaManga.address);
    console.log("🌙 LunaComicsFT:", lunaComics.address);
    
    // Salva deployment
    const fs = require("fs");
    fs.writeFileSync("deployment-polygon-simple.json", JSON.stringify({
        network: "Polygon",
        timestamp: new Date().toISOString(),
        contracts: {
            SolidaryMetrics: metrics.address,
            MareaMangaNFT: mareaManga.address,
            LunaComicsFT: lunaComics.address
        }
    }, null, 2));
}

main().catch(console.error);
