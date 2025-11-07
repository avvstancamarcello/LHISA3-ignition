const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  const sponsorVaultAddress = "0xB19Ee3A16554d339111028fe3a76fEE5AE45E8A3";
  
  // Indirizzo di Caritas Internationalis (da fornire)
  const caritasAddress = process.env.CARITAS_ADDRESS || "0x0000000000000000000000000000000000000000";
  
  if (caritasAddress === "0x0000000000000000000000000000000000000000") {
    console.log("❌ Errore: Fornire l'indirizzo di Caritas tramite CARITAS_ADDRESS");
    console.log("Esempio: CARITAS_ADDRESS=0x... npx hardhat run scripts/transfer-to-caritas.cjs --network polygon");
    process.exit(1);
  }
  
  console.log("🏛️ Trasferimento controllo SolidarySponsorVault a Caritas");
  console.log("=" * 60);
  console.log("📍 Contract:", sponsorVaultAddress);
  console.log("👤 Current Admin:", deployer.address);
  console.log("🏛️ Caritas Address:", caritasAddress);
  console.log("=" * 60);
  
  try {
    // Get contract instance
    const sponsorVault = await ethers.getContractAt("SolidarySponsorVault", sponsorVaultAddress);
    
    const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";
    const SPONSOR_ROLE = await sponsorVault.SPONSOR_ROLE();
    
    console.log("🔍 Verifica stato attuale...");
    
    // Check current roles
    const currentAdminHasRole = await sponsorVault.hasRole(DEFAULT_ADMIN_ROLE, deployer.address);
    const currentSponsorHasRole = await sponsorVault.hasRole(SPONSOR_ROLE, deployer.address);
    const caritasHasAdmin = await sponsorVault.hasRole(DEFAULT_ADMIN_ROLE, caritasAddress);
    const caritasHasSponsor = await sponsorVault.hasRole(SPONSOR_ROLE, caritasAddress);
    
    console.log("  Current Admin has ADMIN role:", currentAdminHasRole);
    console.log("  Current Admin has SPONSOR role:", currentSponsorHasRole);
    console.log("  Caritas has ADMIN role:", caritasHasAdmin);
    console.log("  Caritas has SPONSOR role:", caritasHasSponsor);
    
    if (!currentAdminHasRole) {
      console.log("❌ Errore: L'account corrente non ha privilegi ADMIN");
      process.exit(1);
    }
    
    console.log("\n🚀 Iniziando trasferimento...");
    
    let txCount = 0;
    
    // Step 1: Grant ADMIN role to Caritas if not already granted
    if (!caritasHasAdmin) {
      console.log("1️⃣ Assegnando ruolo ADMIN a Caritas...");
      const tx1 = await sponsorVault.grantRole(DEFAULT_ADMIN_ROLE, caritasAddress);
      await tx1.wait();
      console.log("  ✅ TX:", tx1.hash);
      txCount++;
    } else {
      console.log("1️⃣ Caritas ha già il ruolo ADMIN");
    }
    
    // Step 2: Grant SPONSOR role to Caritas if not already granted
    if (!caritasHasSponsor) {
      console.log("2️⃣ Assegnando ruolo SPONSOR a Caritas...");
      const tx2 = await sponsorVault.grantRole(SPONSOR_ROLE, caritasAddress);
      await tx2.wait();
      console.log("  ✅ TX:", tx2.hash);
      txCount++;
    } else {
      console.log("2️⃣ Caritas ha già il ruolo SPONSOR");
    }
    
    // Step 3: Verify Caritas has both roles before revoking
    const finalCaritasAdmin = await sponsorVault.hasRole(DEFAULT_ADMIN_ROLE, caritasAddress);
    const finalCaritasSponsor = await sponsorVault.hasRole(SPONSOR_ROLE, caritasAddress);
    
    if (!finalCaritasAdmin || !finalCaritasSponsor) {
      console.log("❌ Errore: Caritas non ha ricevuto tutti i ruoli necessari");
      process.exit(1);
    }
    
    console.log("3️⃣ Verifica completata: Caritas ha tutti i ruoli necessari");
    
    // Optional: Revoke roles from current admin (uncomment if desired)
    const shouldRevokeOwnRoles = process.env.REVOKE_OWN_ROLES === "true";
    
    if (shouldRevokeOwnRoles) {
      console.log("4️⃣ Revocando i propri ruoli...");
      
      // Revoke SPONSOR role first
      const tx3 = await sponsorVault.revokeRole(SPONSOR_ROLE, deployer.address);
      await tx3.wait();
      console.log("  ✅ Revocato SPONSOR role - TX:", tx3.hash);
      txCount++;
      
      // Revoke ADMIN role last (this will remove our ability to manage the contract)
      const tx4 = await sponsorVault.revokeRole(DEFAULT_ADMIN_ROLE, deployer.address);
      await tx4.wait();
      console.log("  ✅ Revocato ADMIN role - TX:", tx4.hash);
      console.log("  ⚠️  Non hai più controllo sul contratto!");
      txCount++;
    } else {
      console.log("4️⃣ Mantenendo i propri ruoli (per sicurezza)");
      console.log("  💡 Per revocare: REVOKE_OWN_ROLES=true npx hardhat run...");
    }
    
    console.log("\n" + "=" * 60);
    console.log("🎉 TRASFERIMENTO COMPLETATO!");
    console.log("📊 Transazioni eseguite:", txCount);
    console.log("🏛️ Caritas Internationalis ora ha il controllo del SponsorVault");
    console.log("=" * 60);
    
    // Final verification
    console.log("\n🔍 Verifica finale dei ruoli:");
    const finalCurrentAdmin = await sponsorVault.hasRole(DEFAULT_ADMIN_ROLE, deployer.address);
    const finalCurrentSponsor = await sponsorVault.hasRole(SPONSOR_ROLE, deployer.address);
    const finalCaritasAdminCheck = await sponsorVault.hasRole(DEFAULT_ADMIN_ROLE, caritasAddress);
    const finalCaritasSponsorCheck = await sponsorVault.hasRole(SPONSOR_ROLE, caritasAddress);
    
    console.log("  Current Admin ADMIN role:", finalCurrentAdmin);
    console.log("  Current Admin SPONSOR role:", finalCurrentSponsor);
    console.log("  Caritas ADMIN role:", finalCaritasAdminCheck);
    console.log("  Caritas SPONSOR role:", finalCaritasSponsorCheck);
    
  } catch (error) {
    console.error("❌ Errore durante il trasferimento:", error.message);
    if (error.transaction) {
      console.error("TX Hash:", error.transaction.hash);
    }
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });