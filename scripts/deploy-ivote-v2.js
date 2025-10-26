const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("💰 Deploying IVOTE V2 With Refund...");
  
  const IVOTEV2 = await ethers.getContractFactory("IVOTE_V2_WithRefund");
  
  const ivoteV2 = await upgrades.deployProxy(IVOTEV2, [
    "0x514efc732cc787fb19c90d01edaf5a79d7e2385d", // admin
    "0x514efc732cc787fb19c90d01edaf5a79d7e2385d", // caritas wallet
    Math.floor(Date.now() / 1000) + (180 * 86400), // 180 days
    ethers.parseEther("100000"), // threshold
    "0x514efc732cc787fb19c90d01edaf5a79d7e2385d", // draw owner
    "0x514efc732cc787fb19c90d01edaf5a79d7e2385d"  // sponsor
  ], {
    kind: 'uups',
    timeout: 120000
  });
  
  await ivoteV2.waitForDeployment();
  const address = await ivoteV2.getAddress();
  
  console.log("✅ IVOTE V2 deployed to:", address);
  console.log("🔗 Explorer: https://basescan.org/address/" + address);
  
  return address;
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
