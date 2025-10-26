const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("🚀 Deploying LuccaComixSolidary (ORCHESTRATOR)...");
  
  const LuccaComixSolidary = await ethers.getContractFactory("LuccaComixSolidary");
  const solidary = await upgrades.deployProxy(LuccaComixSolidary, [], {
    initializer: "initialize",
    kind: "uups"
  });
  
  await solidary.waitForDeployment();
  const address = await solidary.getAddress();
  
  console.log("✅ LuccaComixSolidary deployed to:", address);
  
  // Verifica
  const owner = await solidary.owner();
  
  console.log("🎉 VERIFICATION:");
  console.log("Owner:", owner);
  console.log("🔗 BaseScan: https://basescan.org/address/" + address);
  
  const fs = require('fs');
  fs.writeFileSync('SOLIDARY_ADDRESS.txt', address);
  console.log("💾 Ecosystem addresses saved!");
  console.log("🎪 TOKEN: 0x4879570a9268a94BCcb8731ecb95E39bdb5EBC0C");
  console.log("🖼️  NFT: 0xa0DA23b54D9D435acD1c7dD01E36CA2f1eAc4F8A");
  console.log("⚡ SOLIDARY: " + address);
}

main().catch(console.error);
