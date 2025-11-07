const { ethers } = require("hardhat");

async function main() {
  const solidaryHubAddress = "0xec8b6066b99D4ED3dF0626bab463264354274b49";

  const SolidaryHub = await ethers.getContractAt("SolidarySystemHub", solidaryHubAddress);

  try {
    const stats = await SolidaryHub.getEcosystemStatistics();
    console.log("Ecosystem Statistics:", stats);
    console.log("Ecosystem appears initialized");
  } catch (error) {
    console.log("Error calling getEcosystemStatistics:", error.message);
    console.log("Ecosystem may not be initialized");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });