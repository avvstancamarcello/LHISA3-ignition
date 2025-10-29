// SPDX-License-Identifier: MIT
// Script di deploy per librerie e contratto principale
const { ethers, upgrades } = require("hardhat");

async function main() {
  // Deploy librerie
  const SolidaryModuleUtilsLib = await ethers.deployContract("SolidaryModuleUtils");
  await SolidaryModuleUtilsLib.waitForDeployment();
  console.log("SolidaryModuleUtils deployed at:", await SolidaryModuleUtilsLib.getAddress());

  const SolidaryTokenRouterLib = await ethers.deployContract("SolidaryTokenRouter");
  await SolidaryTokenRouterLib.waitForDeployment();
  console.log("SolidaryTokenRouter deployed at:", await SolidaryTokenRouterLib.getAddress());

  // Link librerie nel deploy del contratto principale
  const libraries = {
    "contracts/libraries/SolidaryModuleUtils.sol:SolidaryModuleUtils": await SolidaryModuleUtilsLib.getAddress(),
    "contracts/libraries/SolidaryTokenRouter.sol:SolidaryTokenRouter": await SolidaryTokenRouterLib.getAddress(),
  };

  const SolidarySystemHubFactory = await ethers.getContractFactory("SolidarySystemHub", { libraries });
  const systemHub = await upgrades.deployProxy(SolidarySystemHubFactory, ["0x514EFc732Cc787fb19C90d01eDaf5a79d7E2385D"], { kind: "uups" });
  await systemHub.waitForDeployment();
  console.log("SolidarySystemHub deployed at:", await systemHub.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
