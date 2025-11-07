const { ethers, upgrades } = require("hardhat");

async function main() {
  const proxyAddress = "0xec8b6066b99D4ED3dF0626bab463264354274b49";
  const implementationAddress = "0xca0ACEdf6A0C7ced610100483e83Ba82E395DCbd";

  console.log("Upgrading proxy at", proxyAddress, "to implementation", implementationAddress);

  // Minimal ABI for UUPS proxy upgradeTo function
  const proxyAbi = [
    "function upgradeTo(address newImplementation) external"
  ];

  const [deployer] = await ethers.getSigners();
  const proxy = new ethers.Contract(proxyAddress, proxyAbi, deployer);

  // Actually, the proxy has the upgradeTo function from UUPSUpgradeable
  // So, we can call upgradeTo

  try {
    await proxy.upgradeTo(implementationAddress);
    console.log("Proxy upgraded successfully");
  } catch (error) {
    console.log("Upgrade failed:", error.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });