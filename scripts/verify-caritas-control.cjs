const { ethers } = require("hardhat");

async function main() {
  const sponsorVaultAddress = "0xB19Ee3A16554d339111028fe3a76fEE5AE45E8A3";
  const caritasAddress = process.env.CARITAS_ADDRESS || "0x0000000000000000000000000000000000000000";
  
  console.log("🔍 Verifica Controllo SolidarySponsorVault");
  console.log("=" * 50);
  console.log("📍 Contract:", sponsorVaultAddress);
  console.log("🏛️ Caritas:", caritasAddress);
  console.log("=" * 50);
  
  try {
    const sponsorVault = await ethers.getContractAt("SolidarySponsorVault", sponsorVaultAddress);
    const [deployer] = await ethers.getSigners();
    
    const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";
    const SPONSOR_ROLE = await sponsorVault.SPONSOR_ROLE();
    
    console.log("🔑 Analisi Ruoli:");
    
    // Check all relevant addresses
    const addresses = [
      { name: "Deployer", address: deployer.address },
    ];
    
    if (caritasAddress !== "0x0000000000000000000000000000000000000000") {
      addresses.push({ name: "Caritas", address: caritasAddress });
    }
    
    for (const addr of addresses) {
      const hasAdmin = await sponsorVault.hasRole(DEFAULT_ADMIN_ROLE, addr.address);
      const hasSponsor = await sponsorVault.hasRole(SPONSOR_ROLE, addr.address);
      
      console.log(`\n  👤 ${addr.name} (${addr.address}):`);
      console.log(`    ADMIN role: ${hasAdmin ? '✅' : '❌'}`);
      console.log(`    SPONSOR role: ${hasSponsor ? '✅' : '❌'}`);
    }
    
    // Check contract balance
    const provider = deployer.provider;
    const balance = await provider.getBalance(sponsorVaultAddress);
    console.log(`\n💰 Contract Balance: ${ethers.formatEther(balance)} MATIC`);
    
    // Test functionality (if we have SPONSOR role)
    const canSponsor = await sponsorVault.hasRole(SPONSOR_ROLE, deployer.address);
    if (canSponsor) {
      console.log("\n🧪 Test Functionality:");
      console.log("  ✅ Puoi ancora chiamare mintSponsorToken()");
    } else {
      console.log("\n🧪 Test Functionality:");
      console.log("  ❌ Non puoi più chiamare mintSponsorToken()");
    }
    
    console.log("\n" + "=" * 50);
    
  } catch (error) {
    console.error("❌ Errore durante la verifica:", error.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });