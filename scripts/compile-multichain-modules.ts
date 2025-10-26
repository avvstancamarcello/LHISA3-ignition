import { ethers } from "hardhat";

async function main() {
    console.log("🔍 Compilazione graduale moduli multi-chain...");
    
    const modules = [
        "UniversalMultiChainOrchestrator",
        "SolidaryGamingBridge", 
        "EthereumPolygonMultiTokenBridge"
    ];

    let allSuccess = true;

    for (const module of modules) {
        console.log(`\n📦 Tentativo compilazione: ${module}`);
        try {
            const factory = await ethers.getContractFactory(module);
            console.log(`   ✅ ${module}: COMPILATO`);
        } catch (error: any) {
            console.log(`   ❌ ${module}: ${error.message}`);
            allSuccess = false;
            
            // Analisi errori specifici
            if (error.message.includes("IERC721Upgradeable")) {
                console.log("   🔧 Soluzione: Import IERC721Upgradeable da correggere");
            }
            if (error.message.includes("IERC20Upgradeable")) {
                console.log("   🔧 Soluzione: Import IERC20Upgradeable da correggere");
            }
            if (error.message.includes("not found")) {
                console.log("   🔧 Soluzione: Percorso import OpenZeppelin errato");
            }
        }
    }

    if (allSuccess) {
        console.log("\n🎉 TUTTI I MODULI MULTI-CHAIN COMPILATI!");
        console.log("🚀 Pronti per l'integrazione con SolidaryComix!");
    } else {
        console.log("\n⚠️  Alcuni moduli hanno problemi di compilazione");
        console.log("💡 Possiamo correggere gli import o deployare senza di essi");
    }
}

main().catch(console.error);
