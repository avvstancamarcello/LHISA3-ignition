// scripts/deploy-solidary-comix-final.ts
import { ethers, upgrades } from "hardhat";

async function main() {
    console.log("🚀 DEPLOY FINALE SOLIDARYCOMIX PER LUCCA COMIX 2025");
    console.log("🎯 Transistor Logico-Psicologico - ATTIVAZIONE!");
    
    const admin = "0x514efc732cc787fb19c90d01edaf5a79d7e2385d";
    const charityWallet = "0x514efc732cc787fb19c90d01edaf5a79d7e2385d";

    try {
        console.log("\n📦 Step 1: Caricamento SolidaryComix...");
        const SolidaryComix = await ethers.getContractFactory("SolidaryComix_StellaDoppia");
        console.log("✅ Contratto caricato!");

        console.log("\n🚀 Step 2: Deploy UUPS Proxy...");
        const solidaryComix = await upgrades.deployProxy(
            SolidaryComix,
            [
                admin,           // initialOwner (commentato nel codice)
                charityWallet,   // _charityWallet
                5,               // _feePercent (5%)
                admin,           // _creatorWallet (diventa owner via RefundManager)
                charityWallet,   // _solidaryWallet
                Math.floor(Date.now() / 1000) + 86400 * 180, // 180 giorni
                ethers.parseEther("1000") // 1000 ETH threshold
            ],
            {
                kind: 'uups',
                initializer: 'initialize',
                timeout: 120000
            }
        );

        console.log("⏳ Attendendo conferme blockchain...");
        await solidaryComix.waitForDeployment();
        
        const proxyAddress = await solidaryComix.getAddress();
        const implementationAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
        
        console.log("\n🎉 DEPLOY RIUSCITO!");
        console.log("📊 Dettagli contratto:");
        console.log(`   🔷 Proxy Address: ${proxyAddress}`);
        console.log(`   🔷 Implementation: ${implementationAddress}`);
        console.log(`   👑 Owner: ${admin}`);
        console.log(`   💰 Threshold: 1000 ETH`);
        console.log(`   ⏰ Refund Deadline: 180 giorni`);
        
        // VERIFICA
        console.log("\n🔍 Verifica funzionalità...");
        const owner = await solidaryComix.owner();
        const threshold = await solidaryComix.globalSuccessThreshold();
        const charity = await solidaryComix.charityWallet();
        
        console.log(`   ✅ Owner: ${owner}`);
        console.log(`   ✅ Threshold: ${ethers.formatEther(threshold)} ETH`);
        console.log(`   ✅ Charity: ${charity}`);
        
        console.log("\n✨ SOLIDARYCOMIX OPERATIVO!");
        console.log("🎨 Pronto per Lucca Comix 2025!");
        console.log("💫 From Arctic to Japan - SOLIDARY COMIX LIVE!");
        
        return proxyAddress;
        
    } catch (error: any) {
        console.log(`❌ ERRORE DEPLOY: ${error.message}`);
        throw error;
    }
}

main().catch((error) => {
    console.error("💥 DEPLOY FALLITO:", error.message);
    process.exit(1);
});
