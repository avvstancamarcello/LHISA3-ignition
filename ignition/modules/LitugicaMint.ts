import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import fs from "fs";
import path from "path";

const LiturgicalMint = buildModule("LiturgicalMint", (m) => {
  const liturgicalNFT = m.contract("SolidaryAidNFT", []);

  // Percorso assoluto del file JSON
  const metadataPath = path.resolve(__dirname, "../../metadata/liturgical_nft_registry.json");
  const metadata = JSON.parse(fs.readFileSync(metadataPath, "utf8"));

  const mintCalls = metadata.liturgicalNFTs.map((nft) =>
    m.call(liturgicalNFT, "mintAidNFT", [
      m.getAccount(0),
      nft.audio // Usa il campo audio come URI simbolico
    ])
  );

  return {
    liturgicalNFT,
    ...mintCalls.reduce((acc, call, i) => {
      acc[`mint_${metadata.liturgicalNFTs[i].name.replace(/\s+/g, "_")}`] = call;
      return acc;
    }, {})
  };
});

export default LiturgicalMint;
