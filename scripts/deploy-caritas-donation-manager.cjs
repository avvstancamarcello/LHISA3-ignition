const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  // Indirizzi necessari
  const sponsorVaultAddress = "0xB19Ee3A16554d339111028fe3a76fEE5AE45E8A3";
  const caritasWallet = process.env.CARITAS_ADDRESS || "0x0000000000000000000000000000000000000000";
  
  if (caritasWallet === "0x0000000000000000000000000000000000000000") {
    console.log("❌ Errore: Fornire l'indirizzo di Caritas tramite CARITAS_ADDRESS");
    console.log("Esempio: CARITAS_ADDRESS=0x... npx hardhat run scripts/deploy-caritas-donation-manager.cjs --network polygon");
    process.exit(1);
  }
  
  console.log("🚀 Deploy CaritasDonationManager");
  console.log("=" * 50);
  console.log("📍 SponsorVault:", sponsorVaultAddress);
  console.log("🏛️ Caritas Wallet:", caritasWallet);
  console.log("👤 Deployer:", deployer.address);
  console.log("=" * 50);
  
  try {
    // Deploy the contract
    console.log("📦 Deploying CaritasDonationManager...");
    
    const CaritasDonationManager = await ethers.getContractFactory("CaritasDonationManager");
    
    const donationManager = await CaritasDonationManager.deploy(
      sponsorVaultAddress,  // _sponsorVault
      caritasWallet,        // _caritasWallet
      deployer.address      // _admin (initially the deployer)
    );
    
    await donationManager.waitForDeployment();
    const address = await donationManager.getAddress();
    
    console.log("✅ CaritasDonationManager deployed to:", address);
    
    // Verify deployment
    console.log("\n🔍 Verifying deployment...");
    
    const deployedSponsorVault = await donationManager.sponsorVault();
    const deployedCaritasWallet = await donationManager.caritasWallet();
    const totalDonations = await donationManager.totalDonations();
    const totalDonors = await donationManager.totalDonors();
    
    console.log("  SponsorVault address:", deployedSponsorVault);
    console.log("  Caritas wallet:", deployedCaritasWallet);
    console.log("  Total donations:", ethers.formatEther(totalDonations), "MATIC");
    console.log("  Total donors:", totalDonors.toString());
    
    // Check roles
    const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";
    const DONATION_MANAGER_ROLE = await donationManager.DONATION_MANAGER_ROLE();
    
    const deployerHasAdmin = await donationManager.hasRole(DEFAULT_ADMIN_ROLE, deployer.address);
    const deployerHasManager = await donationManager.hasRole(DONATION_MANAGER_ROLE, deployer.address);
    
    console.log("  Deployer has ADMIN role:", deployerHasAdmin);
    console.log("  Deployer has DONATION_MANAGER role:", deployerHasManager);
    
    console.log("\n" + "=" * 50);
    console.log("🎉 DEPLOYMENT COMPLETATO!");
    console.log("📍 Contract Address:", address);
    console.log("=" * 50);
    
    console.log("\n📋 Prossimi Step:");
    console.log("1. Verifica il contratto su PolygonScan");
    console.log("2. (Opzionale) Trasferisci ruoli ADMIN a Caritas:");
    console.log(`   CARITAS_ADDRESS=${caritasWallet} CONTRACT_ADDRESS=${address} npx hardhat run scripts/transfer-donation-manager-to-caritas.cjs --network polygon`);
    console.log("3. Testa una donazione di prova");
    console.log("4. Integra nell'app React per donazioni");
    
  } catch (error) {
    console.error("❌ Errore durante il deploy:", error.message);
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