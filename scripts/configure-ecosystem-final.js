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

    console.log("✅ Ecosystem addresses configured successfully!");

    // VERIFICA FINALE
    const contractInfo = await solidary.getContractInfo();
    console.log("🎉 FINAL ECOSYSTEM STATUS:");
    console.log("  Token Address:", contractInfo[0]);
    console.log("  NFT Address:", contractInfo[1]);
    console.log("  Owner:", contractInfo[2]);
    console.log("  Charity Count:", contractInfo[3].toString());
    console.log("  Hourly Prize:", contractInfo[4].toString());

    console.log("🚀 ECOSYSTEM READY FOR LUCCA COMICS 2025!");
    console.log("💰 TOKEN: " + tokenAddress);
    console.log("🖼️  NFT: " + nftAddress);
    console.log("⚡ SOLIDARY: " + solidaryAddress);

  } catch (error) {
    console.log("❌ Configuration failed:", error.message);
  }
}

main().catch(console.error);
