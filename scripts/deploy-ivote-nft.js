const { ethers } = require("hardhat");

async function main() {
  console.log("🎨 Deploying IVOTE NFT System...");
  
  const IVOTENFT = await ethers.getContractFactory("IVOTEVoterNFT");
  
  // 🔥 USA L'ADDRESS IVOTE ESISTENTE VERIFICATO!
  const IVOTE_EXISTING_ADDRESS = "0x4e54515e72ed03a3d05b116fa333ad3430b78ca1";
  
  const ivoteNFT = await IVOTENFT.deploy(
    IVOTE_EXISTING_ADDRESS,     // ✅ IVOTE contract ESISTENTE
    "0x514EFc732Cc787fb19C90d01eDaf5a79d7E2385D", // Draw owner (stesso owner IVOTE)
    ethers.parseEther("0.001")  // NFT price
  );
  
  await ivoteNFT.waitForDeployment();
  const address = await ivoteNFT.getAddress();
  
  console.log("✅ IVOTE NFT deployed to:", address);
  console.log("🔗 Explorer: https://basescan.org/address/" + address);
  console.log("📎 Collegato a IVOTE esistente:", IVOTE_EXISTING_ADDRESS);
  
  return address;
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
