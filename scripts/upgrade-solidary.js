const { ethers, upgrades } = require("hardhat");

async function main() {
  const solidaryAddress = "0xC3b8B00a45F66821b885a1372434D1072D6b6B77";
  
  console.log("🔄 Upgrading LuccaComixSolidary with new functions...");
  
  const LuccaComixSolidaryV2 = await ethers.getContractFactory("LuccaComixSolidary");
  const upgraded = await upgrades.upgradeProxy(solidaryAddress, LuccaComixSolidaryV2);
  
  console.log("✅ Contract upgraded successfully!");
  console.log("📊 New functions added for BaseScan visibility");
}

main().catch(console.error);
