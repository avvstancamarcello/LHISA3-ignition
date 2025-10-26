const { ethers } = require("hardhat");

async function main() {
  console.log("🎨 DEPLOY IVOTE NFT - VERSIONE FINALE");
  
  try {
    console.log("🔍 Caricando contratto: IVOTEVoterNFT");
    const IVOTENFT = await ethers.getContractFactory("IVOTEVoterNFT");
    
    const IVOTE_EXISTING_ADDRESS = "0x4e54515e72ed03a3d05b116fa333ad3430b78ca1";
    
    console.log("🚀 Avvio deploy...");
    const ivoteNFT = await IVOTENFT.deploy(
      IVOTE_EXISTING_ADDRESS,
      "0x514EFc732Cc787fb19C90d01eDaf5a79d7E2385D",
      ethers.parseEther("0.001")
    );
    
    await ivoteNFT.waitForDeployment();
    const address = await ivoteNFT.getAddress();
    
    console.log("🎉 DEPLOY COMPLETATO!");
    console.log("✅ IVOTE NFT deployed to:", address);
    console.log("🔗 Explorer: https://basescan.org/address/" + address);
    console.log("📎 Collegato a IVOTE esistente:", IVOTE_EXISTING_ADDRESS);
    
    return address;
    
  } catch (error) {
    console.log("❌ ERRORE:", error.message);
    throw error;
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
