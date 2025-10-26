// scripts/check-upgradeability-simple.cjs
const { ethers } = require("hardhat");

async function main() {
  console.log("🔍 VERIFICA SEMPLICE CONTRATTI...");
  
  const addresses = {
    token: "0x4879570a9268a94BCcb8731ecb95E39bdb5EBC0C",
    nft: "0xa0DA23b54D9D435acD1c7dD01E36CA2f1eAc4F8A", 
    solidary: "0xC3b8B00a45F66821b885a1372434D1072D6b6B77"
  };

  // Verifica solo che i contratti esistano
  for (const [name, address] of Object.entries(addresses)) {
    try {
      const code = await ethers.provider.getCode(address);
      if (code && code !== "0x") {
        console.log(`✅ ${name}: Contratto esistente (${code.length} bytes)`);
        
        // Verifica se è un proxy (controllo semplificato)
        if (code.includes("0x363d3d373d3d3d363d73") || code.length < 1000) {
          console.log(`   📦 ${name}: Potrebbe essere un proxy UUPS`);
        } else {
          console.log(`   ⚠️  ${name}: Potrebbe NON essere upgradeable`);
        }
      } else {
        console.log(`❌ ${name}: Non è un contratto`);
      }
    } catch (error) {
      console.log(`❌ ${name}: Errore nella verifica - ${error.message}`);
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
