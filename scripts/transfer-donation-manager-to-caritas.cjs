const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  const donationManagerAddress = process.env.CONTRACT_ADDRESS || "0x0000000000000000000000000000000000000000";
  const caritasAddress = process.env.CARITAS_ADDRESS || "0x0000000000000000000000000000000000000000";
  
  if (donationManagerAddress === "0x0000000000000000000000000000000000000000") {
    console.log("❌ Errore: Fornire l'indirizzo del contratto tramite CONTRACT_ADDRESS");
    process.exit(1);
  }
  
  if (caritasAddress === "0x0000000000000000000000000000000000000000") {
    console.log("❌ Errore: Fornire l'indirizzo di Caritas tramite CARITAS_ADDRESS");
    process.exit(1);
  }
  
  console.log("🏛️ Trasferimento controllo CaritasDonationManager a Caritas");
  console.log("=" * 60);
  console.log("📍 Contract:", donationManagerAddress);
  console.log("👤 Current Admin:", deployer.address);
  console.log("🏛️ Caritas Address:", caritasAddress);
  console.log("=" * 60);
  
  try {
    const donationManager = await ethers.getContractAt("CaritasDonationManager", donationManagerAddress);
    
    const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";
    const DONATION_MANAGER_ROLE = await donationManager.DONATION_MANAGER_ROLE();
    
    console.log("🔍 Verifica stato attuale...");
    
    const currentAdminHasRole = await donationManager.hasRole(DEFAULT_ADMIN_ROLE, deployer.address);
    const currentManagerHasRole = await donationManager.hasRole(DONATION_MANAGER_ROLE, deployer.address);
    const caritasHasAdmin = await donationManager.hasRole(DEFAULT_ADMIN_ROLE, caritasAddress);
    const caritasHasManager = await donationManager.hasRole(DONATION_MANAGER_ROLE, caritasAddress);
    
    console.log("  Current Admin has ADMIN role:", currentAdminHasRole);
    console.log("  Current Admin has DONATION_MANAGER role:", currentManagerHasRole);
    console.log("  Caritas has ADMIN role:", caritasHasAdmin);
    console.log("  Caritas has DONATION_MANAGER role:", caritasHasManager);
    
    if (!currentAdminHasRole) {
      console.log("❌ Errore: L'account corrente non ha privilegi ADMIN");
      process.exit(1);
    }
    
    console.log("\n🚀 Iniziando trasferimento...");
    
    let txCount = 0;
    
    // Grant ADMIN role to Caritas
    if (!caritasHasAdmin) {
      console.log("1️⃣ Assegnando ruolo ADMIN a Caritas...");
      const tx1 = await donationManager.grantRole(DEFAULT_ADMIN_ROLE, caritasAddress);
      await tx1.wait();
      console.log("  ✅ TX:", tx1.hash);
      txCount++;
    }
    
    // Grant DONATION_MANAGER role to Caritas
    if (!caritasHasManager) {
      console.log("2️⃣ Assegnando ruolo DONATION_MANAGER a Caritas...");
      const tx2 = await donationManager.grantRole(DONATION_MANAGER_ROLE, caritasAddress);
      await tx2.wait();
      console.log("  ✅ TX:", tx2.hash);
      txCount++;
    }
    
    // Verify Caritas has both roles
    const finalCaritasAdmin = await donationManager.hasRole(DEFAULT_ADMIN_ROLE, caritasAddress);
    const finalCaritasManager = await donationManager.hasRole(DONATION_MANAGER_ROLE, caritasAddress);
    
    if (!finalCaritasAdmin || !finalCaritasManager) {
      console.log("❌ Errore: Caritas non ha ricevuto tutti i ruoli necessari");
      process.exit(1);
    }
    
    console.log("3️⃣ Verifica completata: Caritas ha tutti i ruoli necessari");
    
    // Optional: Revoke own roles
    const shouldRevokeOwnRoles = process.env.REVOKE_OWN_ROLES === "true";
    
    if (shouldRevokeOwnRoles) {
      console.log("4️⃣ Revocando i propri ruoli...");
      
      // Revoke DONATION_MANAGER role first
      const tx3 = await donationManager.revokeRole(DONATION_MANAGER_ROLE, deployer.address);
      await tx3.wait();
      console.log("  ✅ Revocato DONATION_MANAGER role - TX:", tx3.hash);
      txCount++;
      
      // Revoke ADMIN role last
      const tx4 = await donationManager.revokeRole(DEFAULT_ADMIN_ROLE, deployer.address);
      await tx4.wait();
      console.log("  ✅ Revocato ADMIN role - TX:", tx4.hash);
      console.log("  ⚠️  Non hai più controllo sul contratto!");
      txCount++;
    } else {
      console.log("4️⃣ Mantenendo i propri ruoli (per sicurezza)");
      console.log("  💡 Per revocare: REVOKE_OWN_ROLES=true");
    }
    
    console.log("\n" + "=" * 60);
    console.log("🎉 TRASFERIMENTO DONATION MANAGER COMPLETATO!");
    console.log("📊 Transazioni eseguite:", txCount);
    console.log("🏛️ Caritas ora controlla il DonationManager");
    console.log("=" * 60);
    
  } catch (error) {
    console.error("❌ Errore durante il trasferimento:", error.message);
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });