const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  const admin = deployer.address;

  const name = "LunaComics";
  const symbol = "LUNA";
  const initialSupply = ethers.utils.parseUnits("0", 18); // cambia se vuoi supply iniziale
  const treasury = admin;

  const FT = await ethers.getContractFactory("LunaComicsFT");
  const ft = await upgrades.deployProxy(
    FT,
    [admin, name, symbol, initialSupply, treasury],
    { initializer: "initialize" }
  );
  await ft.deployed();

  console.log("LunaComicsFT deployed to:", ft.address);
}

main().catch((e) => { console.error(e); process.exit(1); });
