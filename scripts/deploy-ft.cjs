const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  // Parametri iniziali
  const initialSupply = ethers.parseUnits("1000000", 18); // 1M token
  const treasury = deployer.address;

  // Deploy upgradeable FT
  const FT = await ethers.getContractFactory("CosmixProtocolToken");
  const ft = await upgrades.deployProxy(
    FT,
    [deployer.address, initialSupply, treasury],
    { initializer: "initialize", kind: "uups" }
  );
  await ft.waitForDeployment();
  const ftAddress = await ft.getAddress();
  console.log("✅ FT deployed at:", ftAddress);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
