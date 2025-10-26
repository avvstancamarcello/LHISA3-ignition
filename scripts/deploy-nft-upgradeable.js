const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("🚀 Deploying LuccaComixNFT (UPGRADEABLE)...");
  
  const LuccaComixNFT = await ethers.getContractFactory("LuccaComixNFT");
  const nft = await upgrades.deployProxy(LuccaComixNFT, [], {
    initializer: "initialize"
  });
  
  await nft.waitForDeployment();
  const address = await nft.getAddress();
  
  console.log("✅ LuccaComixNFT deployed to:", address);
  console.log("🔍 Proxy: https://basescan.org/address/" + address);
  
  return address;
}

main().catch(console.error);
