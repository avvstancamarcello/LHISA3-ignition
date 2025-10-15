import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const LiturgicalMint = buildModule("LiturgicalMint", (m) => {
  const liturgicalNFT = m.contract("SolidaryAidNFT", []);

  const panisAngelicus = m.call(liturgicalNFT, "mintAidNFT", [
    m.getAccount(0),
    "ipfs://QmPanisAngelicusNFT"
  ]);

  const aveVerumCorpus = m.call(liturgicalNFT, "mintAidNFT", [
    m.getAccount(0),
    "ipfs://QmAveVerumCorpusNFT"
  ]);

  const luxAeterna = m.call(liturgicalNFT, "mintAidNFT", [
    m.getAccount(0),
    "ipfs://QmLuxAeternaNFT"
  ]);

  const adesteFideles = m.call(liturgicalNFT, "mintAidNFT", [
    m.getAccount(0),
    "ipfs://QmAdesteFidelesNFT"
  ]);

  const aveMariaSchubert = m.call(liturgicalNFT, "mintAidNFT", [
    m.getAccount(0),
    "ipfs://QmAveMariaSchubertNFT"
  ]);

  const tuSeiLaMiaVita = m.call(liturgicalNFT, "mintAidNFT", [
    m.getAccount(0),
    "ipfs://QmTuSeiLaMiaVitaNFT"
  ]);

  return {
    liturgicalNFT,
    panisAngelicus,
    aveVerumCorpus,
    luxAeterna,
    adesteFideles,
    aveMariaSchubert,
    tuSeiLaMiaVita
  };
});

export default LiturgicalMint;
