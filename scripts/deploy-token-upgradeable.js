const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("🚀 Deploying LuccaComixToken (UPGRADEABLE)...");
  
  const LuccaComixToken = await ethers.getContractFactory("LuccaComixToken");
  const token = await upgrades.deployProxy(LuccaComixToken, [], {
    initializer: "initialize"
  });
  
  await token.waitForDeployment();
  const address = await token.getAddress();
  
  console.log("✅ LuccaComixToken deployed to:", address);
  console.log("🔍 Proxy: https://basescan.org/address/" + address);
  
  return address;
}

main().catch(console.error);
