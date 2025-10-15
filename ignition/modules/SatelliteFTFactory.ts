import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("SatelliteFTFactory", (m) => {
  // 🌌 Parametri orbitale
  const moduleName = m.getParameter("moduleName");
  const tokenName = `${moduleName}FT`;
  const tokenSymbol = `${moduleName.slice(0, 3).toUpperCase()}FT`;
  const initialSupply = m.getParameter("initialSupply");

  // 🪙 Deploy ERC20 satellite
  const satelliteFT = m.contract("ERC20", [tokenName, tokenSymbol]);

  // 🛠️ Mint iniziale
  m.call(satelliteFT, "mint", [m.getAccount(0), initialSupply]);

  return { satelliteFT };
});
