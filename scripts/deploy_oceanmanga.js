const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  const admin = deployer.address;

  const name = "OceanManga";
  const symbol = "OCEAN";
  const baseURI = "";               // es. "ipfs://CID/{id}.json" oppure vuoto
  const royaltyReceiver = admin;    // sostituisci con treasury
  const royaltyBps = 500;           // 5%

  const NFT = await ethers.getContractFactory("OceanMangaNFT");
  const nft = await upgrades.deployProxy(
    NFT,
    [admin, baseURI, name, symbol, royaltyReceiver, royaltyBps],
    { initializer: "initialize" }
  );
  await nft.deployed();

  console.log("OceanMangaNFT deployed to:", nft.address);
}

main().catch((e) => { console.error(e); process.exit(1); });
