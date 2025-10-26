const { ethers } = require("hardhat");

async function main() {
  const solidaryAddress = "0xC3b8B00a45F66821b885a1372434D1072D6b6B77";
  const tokenAddress = "0x4879570a9268a94BCcb8731ecb95E39bdb5EBC0C";
  const nftAddress = "0xa0DA23b54D9D435acD1c7dD01E36CA2f1eAc4F8A";

  console.log("🔗 Configuring Lucca Comix Ecosystem...");

  const LuccaComixSolidary = await ethers.getContractFactory("LuccaComixSolidary");
  const solidary = LuccaComixSolidary.attach(solidaryAddress);

  try {
    // Configura gli indirizzi Token e NFT
    console.log("📝 Setting Token Address...");
    const tx1 = await solidary.setTokenAddress(tokenAddress);
    await tx1.wait();

    console.log("📝 Setting NFT Address...");
    const tx2 = await solidary.setNftAddress(nftAddress);
    await tx2.wait();

    // Aggiungi alcune beneficenze di esempio
    console.log("❤️  Adding sample charities...");

    // Telethon
    const tx3 = await solidary.addCharity(
      "Telethon - Ricerca Malattie Genetiche",
      "Finanzia la ricerca sulle malattie genetiche rare",
      "0x742d35Cc6634C0532925a3b8D4B5e3A3A3D7a7F1"
    );
    await tx3.wait();

    // Emergency
    const tx4 = await solidary.addCharity(
      "Emergency - Cure Mediche Globali",
      "Porta cure mediche gratuite in zone di guerra",
      "0x742d35Cc6634C0532925a3b8D4B5e3A3A3D7a7F2"
    );
    await tx4.wait();

    console.log("✅ Ecosystem configured successfully!");

    // Verifica finale
    const contractInfo = await solidary.getContractInfo();
    console.log("🎉 FINAL CONFIGURATION:");
    console.log("  Token Address:", contractInfo[0]);
    console.log("  NFT Address:", contractInfo[1]);
    console.log("  Charity Count:", contractInfo[3].toString());

  } catch (error) {
    console.log("❌ Configuration failed:", error.message);
  }
}

main().catch(console.error);
