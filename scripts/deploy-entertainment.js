const { ethers } = require("hardhat");

async function main() {
  console.log("🎪 Deploying VotoGratis Entertainment...");
  
  const VotoGratis = await ethers.getContractFactory("VotoGratis_Entertainment");
  const votoGratis = await VotoGratis.deploy();
  
  await votoGratis.waitForDeployment();
  const address = await votoGratis.getAddress();
  
  console.log("✅ VotoGratis Entertainment deployed to:", address);
  console.log("🔗 Explorer: https://basescan.org/address/" + address);
  
  return address;
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
