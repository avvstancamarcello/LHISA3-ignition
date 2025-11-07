const { ethers } = require("hardhat");

async function main() {
  const solidaryHubAddress = "0xec8b6066b99D4ED3dF0626bab463264354274b49";

  const SolidaryHub = await ethers.getContractAt("SolidarySystemHub", solidaryHubAddress);

  try {
    const adminRole = ethers.ZeroHash; // DEFAULT_ADMIN_ROLE
    const owner = await SolidaryHub.getRoleMember(adminRole, 0);
    console.log("Admin (owner):", owner);
  } catch (error) {
    console.log("Error calling getRoleMember:", error.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });