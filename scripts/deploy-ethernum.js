require("dotenv").config();

async function main() {
  const { ethers } = require("hardhat");
  const owner = "0x8495B3f7493263685fFcDA2602fFfF349d4eD3B8";
  const charity = "0xf84eb8B95407f04Dee8fF9acaC0e0AC7231bAb2A";
  const creator = "0x514efc732cc787fb19c90d01edaf5a79d7e2385d";
  const ftSupply = ethers.utils.parseUnits("10000000", 18); // 10.000.000
  const NFT_STORAGE_API_KEY = process.env.NFT_STORAGE_API_KEY;

  // Deploy CosmixProtocolToken (FT)
  const CosmixProtocolToken = await ethers.getContractFactory("CosmixProtocolToken");
  const ft = await CosmixProtocolToken.deploy(ftSupply, owner, charity, creator);
  await ft.deployed();
  console.log("CosmixProtocolToken deployed:", ft.address);

  // Deploy OceanMangaNFT (NFT)
  const OceanMangaNFT = await ethers.getContractFactory("OceanMangaNFT");
  const nft = await OceanMangaNFT.deploy(owner, charity, creator, NFT_STORAGE_API_KEY || "");
  await nft.deployed();
  console.log("OceanMangaNFT deployed:", nft.address);

  // Deploy SolidarySystemReputationManager3
  const ReputationManager = await ethers.getContractFactory("SolidarySystemReputationManager3");
  const rep = await ReputationManager.deploy();
  await rep.deployed();
  console.log("SolidarySystemReputationManager3 deployed:", rep.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
