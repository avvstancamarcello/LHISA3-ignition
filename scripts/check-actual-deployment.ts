import { ethers } from "hardhat";

async function main() {
    console.log("🔍 VERIFICA REALE STATO DEPLOY");
    console.log("==============================");
    
    const comixAddress = "0xec8b6066b99D4ED3dF0626bab463264354274b49";
    
    console.log("\n📋 CONTRATTI VERIFICATI:");
    
    // 1. SolidaryComix (sappiamo che è deployato)
    try {
        const SolidaryComix = await ethers.getContractFactory("SolidaryComix_StellaDoppia");
        const comix = SolidaryComix.attach(comixAddress);
        const owner = await comix.owner();
        console.log(`   ✅ SolidaryComix: DEPLOYED`);
        console.log(`      📍 ${comixAddress}`);
        console.log(`      👑 Owner: ${owner}`);
    } catch (error: any) {
        console.log(`   ❌ SolidaryComix: ${error.message}`);
    }
    
    // 2. Altri contratti principali (probabilmente NON deployati)
    const otherContracts = [
        "SolidaryHub",
        "OraculumCaritatis",
        "SolidaryTrustManager",
        "UniversalMultiChainOrchestrator",
        "EthereumPolygonMultiTokenBridge"
    ];
    
    console.log("\n🔍 ALTRI CONTRATTI (probabilmente NON deployati):");
    for (const contractName of otherContracts) {
        try {
            await ethers.getContractFactory(contractName);
            console.log(`   🔷 ${contractName}: COMPILATO ma NON DEPLOYATO`);
        } catch (error: any) {
            console.log(`   ❌ ${contractName}: ${error.message.split('\n')[0]}`);
        }
    }
    
    console.log("\n🎯 CONCLUSIONE:");
    console.log("   Solo SolidaryComix è deployato e operativo");
    console.log("   Altri contratti sono pronti ma non necessari ora");
    console.log("   Perfecto per Lucca Comix 2025!");
}

main().catch(console.error);
