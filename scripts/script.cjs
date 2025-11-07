// scripts/checkRole.cjs
const { ethers } = require("hardhat");
(async () => {
  const hub = await ethers.getContractAt("SolidarySystemHub", "0xA740d24f..."); 
  console.log(await hub.hasRole("0xa49b0d...c0", "0x8495B3f7..."));
})();
