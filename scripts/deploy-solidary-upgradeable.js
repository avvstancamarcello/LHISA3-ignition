const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("🚀 Deploying LuccaComixSolidary (UPGRADEABLE)...");
  
  const LuccaComixSolidary = await ethers.getContractFactory("LuccaComixSolidary");
  const solidary = await upgrades.deployProxy(LuccaComixSolidary, [], {
    initializer: "initialize",
    kind: "uups"
  });
  
  await solidary.waitForDeployment();
  const address = await solidary.getAddress();
  
  console.log("✅ LuccaComixSolidary deployed to:", address);
  console.log("🔍 Proxy: https://basescan.org/address/" + address);
  
  return address;
}

main().catch(console.error);
