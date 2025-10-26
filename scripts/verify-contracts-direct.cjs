// scripts/verify-contracts-direct.cjs
const { ethers } = require("ethers");

async function main() {
  console.log("🔍 VERIFICA DIRETTA CONTRATTI SU BASE...");
  
  // Provider per Base Mainnet
  const provider = new ethers.providers.JsonRpcProvider("https://mainnet.base.org");
  
  const addresses = {
    token: "0x4879570a9268a94BCcb8731ecb95E39bdb5EBC0C",
    nft: "0xa0DA23b54D9D435acD1c7dD01E36CA2f1eAc4F8A", 
    solidary: "0xC3b8B00a45F66821b885a1372434D1072D6b6B77"
  };

  for (const [name, address] of Object.entries(addresses)) {
    try {
      console.log(`\n📋 Verifica ${name}...`);
      
      // 1. Verifica che il contratto esista
      const code = await provider.getCode(address);
      if (code === "0x") {
        console.log(`   ❌ ${name}: Indirizzo non è un contratto`);
        continue;
      }
      
      console.log(`   ✅ ${name}: Contratto esistente (${code.length} bytes)`);
      
      // 2. Analisi semplificata per proxy
      if (code.length < 1000) {
        console.log(`   📦 ${name}: Probabile PROXY UUPS (codice breve)`);
        
        // Tentativo di leggere implementation slot
        try {
          const implementationSlot = "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc";
          const implementation = await provider.getStorageAt(address, implementationSlot);
          if (implementation !== "0x0000000000000000000000000000000000000000000000000000000000000000") {
            const implAddress = "0x" + implementation.slice(26);
            console.log(`   🏗️  ${name}: Implementation address: ${implAddress}`);
          }
        } catch (e) {
          console.log(`   ⚠️  ${name}: Impossibile leggere implementation slot`);
        }
      } else {
        console.log(`   ⚠️  ${name}: Probabile contratto DIRECT (codice lungo)`);
      }
      
    } catch (error) {
      console.log(`   ❌ ${name}: Errore - ${error.message}`);
    }
  }
}

main().catch(console.error);
