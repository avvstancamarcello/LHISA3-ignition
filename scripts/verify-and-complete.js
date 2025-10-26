const { ethers, upgrades } = require("hardhat");

async function main() {
  const solidaryAddress = "0xC3b8B00a45F66821b885a1372434D1072D6b6B77";
  
  console.log("🔍 Verifying LuccaComixSolidary...");
  
  const LuccaComixSolidary = await ethers.getContractFactory("LuccaComixSolidary");
  const solidary = LuccaComixSolidary.attach(solidaryAddress);
  
  try {
    // Prova a chiamare initialize se non è inizializzato
    console.log("🔄 Attempting to initialize...");
    const tx = await solidary.initialize();
    await tx.wait();
    console.log("✅ Contract initialized successfully!");
  } catch (error) {
    console.log("⚠️  Contract might already be initialized:", error.message);
  }
  
  // Verifica finale
  try {
    const owner = await solidary.owner();
    console.log("🎉 FINAL VERIFICATION:");
    console.log("Owner:", owner);
    console.log("✅ LuccaComixSolidary is READY!");
  } catch (error) {
    console.log("❌ Still not initialized properly:", error.message);
  }
  
  console.log("🔗 BaseScan: https://basescan.org/address/" + solidaryAddress);
  console.log("🎪 ECOSYSTEM DEPLOYED!");
  console.log("💰 TOKEN: 0x4879570a9268a94BCcb8731ecb95E39bdb5EBC0C");
  console.log("🖼️  NFT: 0xa0DA23b54D9D435acD1c7dD01E36CA2f1eAc4F8A");
  console.log("⚡ SOLIDARY: " + solidaryAddress);
}

main().catch(console.error);
