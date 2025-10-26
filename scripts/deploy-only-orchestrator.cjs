// 🚀 DEPLOY SOLO ORCHESTRATOR
const { ethers } = require("ethers");

const PRIVATE_KEY = "8f2a46c1eb83a1fcec604207c4c0e34c2b46b2d045883311509cb592b282dfb1";
const POLYGON_RPC = "https://aged-tiniest-frost.matic.quiknode.pro/b50bb4625032afb94b57bf5efd608270059e0da8";
const NFT_STORAGE_API_KEY = "d36ca24b490aae57a698"

// ✅ INDIRIZZI GIA' DEPLOYATI
const EXISTING_ADDRESSES = {
    SolidaryMetrics: "0x1f0bF59Bb46a308031fb05Bda23805B58df5F157",
    MareaMangaNFT: "0x5d8c88173EB32b9D6BE729DDFcD282a45464D025", 
    LunaComicsFT: "0x3F9123cA250725b37D5a040fce82F059AbD1ff74"
};

async function main() {
    console.log("🚀 DEPLOY SOLO ORCHESTRATOR SU POLYGON");
    console.log("======================================");
    
    const provider = new ethers.providers.JsonRpcProvider(POLYGON_RPC);
    const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
    
    console.log("👛 Deployer:", wallet.address);
    console.log("💰 Balance:", ethers.utils.formatEther(await provider.getBalance(wallet.address)), "POL");
    
    // ✅ GAS PRICE
    const gasPrice = ethers.utils.parseUnits("50", "gwei");
    console.log("⛽ Gas Price:", ethers.utils.formatUnits(gasPrice, "gwei"), "gwei");
    
    const deployOptions = {
        gasPrice: gasPrice,
        gasLimit: 5000000
    };
    
    // 🎯 DEPLOY SOLO ORCHESTRATOR
    console.log("\n👑 Deploying SolidaryOrchestrator...");
    const orchestratorArtifact = require("../artifacts/contracts/stellar/SolidaryOrchestrator.sol/SolidaryOrchestrator.json");
    const OrchestratorFactory = new ethers.ContractFactory(orchestratorArtifact.abi, orchestratorArtifact.bytecode, wallet);
    const orchestrator = await OrchestratorFactory.deploy(deployOptions);
    await orchestrator.deployed();
    console.log("✅ SolidaryOrchestrator:", orchestrator.address);
    
    // 🔗 COLLEGA L'ORCHESTRATOR AI CONTRATTI ESISTENTI
    console.log("\n🔗 Connecting Orchestrator to existing contracts...");
    try {
        await orchestrator.initialize();
        console.log("✅ SolidaryOrchestrator initialized");
        
        // Se hai funzioni per collegare gli altri contratti, usale qui
        // es: await orchestrator.setMetricsAddress(EXISTING_ADDRESSES.SolidaryMetrics);
        
    } catch (error) {
        console.log("ℹ️ Initialization note:", error.message);
    }
    
    console.log("\n🎉 ORCHESTRATOR DEPLOYED!");
    console.log("========================");
    console.log("👑 SolidaryOrchestrator:", orchestrator.address);
    console.log("\n📋 Existing Contracts:");
    console.log("📊 SolidaryMetrics:", EXISTING_ADDRESSES.SolidaryMetrics);
    console.log("🌍 MareaMangaNFT:", EXISTING_ADDRESSES.MareaMangaNFT);
    console.log("🌙 LunaComicsFT:", EXISTING_ADDRESSES.LunaComicsFT);
    console.log("========================");
    
    // Salva info aggiornate
    const fs = require("fs");
    const ecosystemInfo = {
        network: "Polygon Mainnet",
        timestamp: new Date().toISOString(),
        orchestrator: orchestrator.address,
        contracts: EXISTING_ADDRESSES,
        explorer: "https://polygonscan.com"
    };
    
    fs.writeFileSync("polygon-ecosystem-complete.json", JSON.stringify(ecosystemInfo, null, 2));
    console.log("\n💾 Ecosystem info saved to: polygon-ecosystem-complete.json");
}

main().catch(console.error);
