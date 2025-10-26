const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("🚀 Deploying LuccaComixNFT...");
  
  const LuccaComixNFT = await ethers.getContractFactory("LuccaComixNFT");
  const nft = await upgrades.deployProxy(LuccaComixNFT, [], {
    initializer: "initialize"
  });
  
  await nft.waitForDeployment();
  const address = await nft.getAddress();
  
  console.log("✅ LuccaComixNFT deployed to:", address);
  
  // Verifica
  const name = await nft.name();
  const symbol = await nft.symbol();
  const owner = await nft.owner();
  
  console.log("🎉 VERIFICATION:");
  console.log("Name:", name);
  console.log("Symbol:", symbol);
  console.log("Owner:", owner);
  console.log("🔗 BaseScan: https://basescan.org/address/" + address);
  
  const fs = require('fs');
  fs.writeFileSync('NFT_ADDRESS.txt', address);
}

main().catch(console.error);
