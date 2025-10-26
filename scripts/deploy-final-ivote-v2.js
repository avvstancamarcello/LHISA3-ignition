const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("💰 UPGRADE IVOTE V2 - VERSIONE FINALE");
  
  const IVOTE_EXISTING_ADDRESS = "0x4e54515e72ed03a3d05b116fa333ad3430b78ca1";
  
  try {
    console.log("🔍 Caricando contratto: IVOTE_V2_WithRefund");
    const IVOTEV2 = await ethers.getContractFactory("IVOTE_V2_WithRefund");
    
    console.log("📍 Tentativo upgrade di:", IVOTE_EXISTING_ADDRESS);
    const ivoteV2 = await upgrades.upgradeProxy(IVOTE_EXISTING_ADDRESS, IVOTEV2);
    
    await ivoteV2.waitForDeployment();
    const address = await ivoteV2.getAddress();
    
    console.log("🎉 UPGRADE COMPLETATO!");
    console.log("✅ IVOTE V2 deployed to:", address);
    console.log("🔗 Explorer: https://basescan.org/address/" + address);
    
    return address;
    
  } catch (error) {
    console.log("❌ UPGRADE FALLITO:", error.message);
    console.log("💡 Il contratto esistente potrebbe non essere upgradeable");
    console.log("🎯 Procederemo con deploy di contratti separati");
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
