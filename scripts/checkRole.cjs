const { ethers } = require("hardhat");

async function main() {
  const hubAddress = "0xA740d24fcF5Ca9282fC4DB0b97c0A92b06AC7778";
  const role = "0xa49b0dc1e696db729b090931047acb0b49e21c13be3be601c57eb24eaf8760c0"; // DEFAULT_ADMIN_ROLE
  const zeroRole = "0x0000000000000000000000000000000000000000000000000000000000000000"; // per grantRole

  const hub = await ethers.getContractAt("SolidarySystemHub", hubAddress);

  console.log("Checking if signer has DEFAULT_ADMIN_ROLE:");
  const [signer] = await ethers.getSigners();
  const signerAddr = await signer.getAddress();
  console.log("Signer:", signerAddr);
  const has = await hub.hasRole(role, signerAddr);
  console.log("hasRole DEFAULT_ADMIN_ROLE:", has);

  console.log("\nChecking if signer has zero role (for grantRole):");
  const hasZero = await hub.hasRole(zeroRole, signerAddr);
  console.log("hasRole (zero):", hasZero);
}

main().catch(console.error);
