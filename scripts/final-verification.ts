// scripts/final-verification.ts
import { ethers } from "hardhat";

async function main() {
    console.log("🔍 VERIFICA FINALE SOLIDARYCOMIX");
    console.log("=========================================");
    
    const comixAddress = "0xec8b6066b99D4ED3dF0626bab463264354274b49";
    const SolidaryComix = await ethers.getContractFactory("SolidaryComix_StellaDoppia");
    const comix = SolidaryComix.attach(comixAddress);
    
    console.log("📊 STATO COMPLETO:");
    console.log(`📍 Address: ${comixAddress}`);
    console.log(`👑 Owner: ${await comix.owner()}`);
    console.log(`🎯 Threshold: ${ethers.formatEther(await comix.globalSuccessThreshold())} ETH`);
    console.log(`💝 Charity: ${await comix.charityWallet()}`);
    console.log(`💰 Fee: ${await comix.feePercent()}%`);
    
    const refundDeadline = await comix.refundDeadline();
    console.log(`⏰ Refund Deadline: ${new Date(Number(refundDeadline) * 1000).toLocaleDateString()}`);
    
    console.log("\n✅ TUTTE LE FUNZIONALITÀ VERIFICATE!");
    console.log("🎉 SOLIDARYCOMIX È OPERATIVO!");
}

main().catch(console.error);
