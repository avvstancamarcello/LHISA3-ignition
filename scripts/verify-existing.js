// scripts/verify-existing.js
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("🔍 Verifying existing contracts...");
  
  // Inserisci qui gli indirizzi dai transaction receipts
  const contractAddresses = [
    "0x02377434f577ea8A4bb41107D07c52f986B5e03f", // Sostituisci con il primo address
    "0x8AeE9ef3996Ff4C4BA72393E8a88DB6Fef27dD42", // Secondo address  
    "0xD00610F39281dbe80031d9FB05EE86031742F56E"  // Terzo address
  ];
  
  for (const address of contractAddresses) {
    try {
      const contract = await ethers.getContractAt("SolidaryTrustManager", address);
      const owner = await contract.owner();
      console.log(`✅ Contract ${address}: Owner = ${owner}`);
    } catch (error) {
      console.log(`❌ Contract ${address}: ${error.message}`);
    }
  }
}

main().catch(console.error);
