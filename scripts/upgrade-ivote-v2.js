const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("🔄 Upgrade IVOTE a V2 With Refund...");
  
  const IVOTE_EXISTING_ADDRESS = "0x4e54515e72ed03a3d05b116fa333ad3430b78ca1";
  const IVOTEV2 = await ethers.getContractFactory("IVOTE_V2_WithRefund");
  
  console.log("📍 Upgrading IVOTE at:", IVOTE_EXISTING_ADDRESS);
  
  try {
    const ivoteV2 = await upgrades.upgradeProxy(IVOTE_EXISTING_ADDRESS, IVOTEV2);
    await ivoteV2.waitForDeployment();
    
    const address = await ivoteV2.getAddress();
    console.log("✅ IVOTE upgraded to V2 at:", address);
    console.log("🔗 Explorer: https://basescan.org/address/" + address);
    
    // Verifica che l'upgrade sia andato a buon fine
    const name = await ivoteV2.name();
    console.log("📛 Nome dopo upgrade:", name);
    
    return address;
  } catch (error) {
    console.log("❌ Upgrade failed:", error.message);
    console.log("💡 Il contratto esistente potrebbe non essere upgradeable");
    console.log("🎯 Procediamo con deploy separato dei nuovi contratti");
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
