import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const PilgrimNFT = buildModule("PilgrimNFT", (m) => {
  const pilgrimNFT = m.contract("SolidaryAidNFT", []);

  const mintAssisi = m.call(pilgrimNFT, "mintAidNFT", [
    m.getAccount(0),
    "ipfs://QmAssisiNFT"
  ]);

  const mintPadova = m.call(pilgrimNFT, "mintAidNFT", [
    m.getAccount(0),
    "ipfs://QmPadovaNFT"
  ]);

  const mintPompei = m.call(pilgrimNFT, "mintAidNFT", [
    m.getAccount(0),
    "ipfs://QmPompeiNFT"
  ]);

  const mintTorino = m.call(pilgrimNFT, "mintAidNFT", [
    m.getAccount(0),
    "ipfs://QmTorinoNFT"
  ]);

  const mintLeuca = m.call(pilgrimNFT, "mintAidNFT", [
    m.getAccount(0),
    "ipfs://QmSantaMariaLeucaNFT"
  ]);

  return {
    pilgrimNFT,
    mintAssisi,
    mintPadova,
    mintPompei,
    mintTorino,
    mintLeuca
  };
});

export default PilgrimNFT;
