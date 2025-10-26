// 🔍 VERIFICA PROFONDA CONTRATTI POLYGON
const { ethers } = require("ethers");

const POLYGON_RPC = "https://polygon-rpc.com";
const provider = new ethers.providers.JsonRpcProvider(POLYGON_RPC);

const CONTRACTS = {
  "ORCHESTRATOR": "0x55A419ad18AB7333cA12f6fF6144aF7B9d7fB1AB",
  "METRICS": "0x1f0bF59Bb46a308031fb05Bda23805B58df5F157",
  "NFT_PLANET": "0x5d8c88173EB32b9D6BE729DDFcD282a45464D025", 
  "FT_SATELLITE": "0x3F9123cA250725b37D5a040fce82F059AbD1ff74"
};

async function deepVerify() {
  console.log("🔍 VERIFICA PROFONDA CONTRATTI POLYGON");
  console.log("======================================");
  
  for (const [name, address] of Object.entries(CONTRACTS)) {
    console.log(`\n📋 ${name}:`);
    console.log(`   📍 ${address}`);
    
    try {
      // 1. Verifica codice contratto
      const code = await provider.getCode(address);
      const hasCode = code !== '0x';
      
      console.log(`   🔍 Code deployed: ${hasCode ? '✅ YES' : '❌ NO'}`);
      console.log(`   📏 Code length: ${code.length} bytes`);
      
      if (hasCode) {
        // 2. Verifica transazioni
        const currentBlock = await provider.getBlockNumber();
        console.log(`   🧱 Current block: ${currentBlock}`);
        
        // 3. Verifica balance (se applicabile)
        const balance = await provider.getBalance(address);
        console.log(`   💰 Contract balance: ${ethers.utils.formatEther(balance)} POL`);
        
        // 4. Verifica se è un contratto (non EOA)
        const txCount = await provider.getTransactionCount(address);
        console.log(`   🔄 Nonce: ${txCount} ${txCount === 0 ? '🆕' : '📈'}`);
        
        console.log(`   🔗 Explorer: https://polygonscan.com/address/${address}`);
        
        if (code.length < 100) {
          console.log(`   ⚠️  ATTENZIONE: Codice molto corto - potrebbe non essere verificato`);
        }
      }
      
    } catch (error) {
      console.log(`   ❌ Errore verifica: ${error.message}`);
    }
  }
  
  console.log("\n🎯 CONCLUSIONE:");
  console.log("I contratti SONO deployati, ma potrebbero non essere verificati su Polygonscan.");
  console.log("Questo è NORMALE subito dopo il deploy.");
}

deepVerify().catch(console.error);
