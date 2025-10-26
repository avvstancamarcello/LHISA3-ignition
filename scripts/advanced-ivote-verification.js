const { ethers } = require("ethers"); // Usa ethers direttamente, non hardhat

async function main() {
  console.log("🔍 VERIFICA TECNICA AVANZATA CONTRATTO IVOTE");
  console.log("============================================");
  
  const IVOTE_ADDRESS = "0x4e54515e72ed03a3d05b116fa333ad3430b78ca1";
  
  // ABI semplificata per verifica
  const SIMPLE_ABI = [
    // Funzioni ERC-20 standard
    "function name() view returns (string)",
    "function symbol() view returns (string)",
    "function decimals() view returns (uint8)",
    "function totalSupply() view returns (uint256)",
    "function balanceOf(address) view returns (uint256)",
    
    // Funzioni comuni
    "function owner() view returns (address)"
  ];

  try {
    console.log("📡 Connessione a Base Network...");
    
    // Provider pubblico - nessuna autenticazione needed
    const provider = new ethers.JsonRpcProvider("https://mainnet.base.org");
    
    // Test connessione
    const network = await provider.getNetwork();
    const blockNumber = await provider.getBlockNumber();
    console.log(`   ✅ Connesso a: ${network.name} (ChainId: ${network.chainId})`);
    console.log(`   📦 Block number: ${blockNumber}`);
    
    console.log("\n🎯 Interrogazione contratto IVOTE...");
    const contract = new ethers.Contract(IVOTE_ADDRESS, SIMPLE_ABI, provider);
    
    // 1. VERIFICA ESISTENZA CONTRATTO
    console.log("\n📊 VERIFICA BASE CONTRATTO:");
    const code = await provider.getCode(IVOTE_ADDRESS);
    if (code === '0x') {
      console.log("   ❌ CONTRATTO NON TROVATO - Address vuoto o self-destructed");
      return;
    }
    
    const codeLength = (code.length - 2) / 2;
    console.log(`   ✅ Contratto trovato: ${codeLength} bytes di bytecode`);
    
    // 2. INFO BASE
    try {
      const name = await contract.name();
      const symbol = await contract.symbol();
      console.log(`   📛 Nome: ${name}`);
      console.log(`   🔤 Symbol: ${symbol}`);
    } catch (e) {
      console.log("   ❌ Non è un token ERC-20 standard");
    }
    
    try {
      const decimals = await contract.decimals();
      const totalSupply = await contract.totalSupply();
      console.log(`   🔢 Decimals: ${decimals}`);
      console.log(`   💰 Total Supply: ${ethers.formatUnits(totalSupply, decimals)}`);
    } catch (e) {
      console.log("   📝 Info supply non disponibili");
    }
    
    // 3. VERIFICA PROPRIETARIO
    try {
      const owner = await contract.owner();
      console.log(`   👑 Owner: ${owner}`);
    } catch (e) {
      console.log("   📝 Owner non disponibile");
    }
    
    // 4. ANALISI BYTECODE
    console.log("\n🔐 ANALISI BYTECODE DETTAGLIATA:");
    const codeHash = ethers.keccak256(code);
    console.log(`   🔐 Hash bytecode: ${codeHash}`);
    console.log(`   📏 Bytecode length: ${codeLength} bytes`);
    
    // Cerca signature di funzioni comuni nel bytecode
    const commonSignatures = {
      'a9059cbb': 'transfer(address,uint256)',
      '23b872dd': 'transferFrom(address,address,uint256)',
      '095ea7b3': 'approve(address,uint256)',
      '70a08231': 'balanceOf(address)',
      '18160ddd': 'totalSupply()'
    };
    
    console.log("   🔍 Funzioni rilevate nel bytecode:");
    for (const [sig, funcName] of Object.entries(commonSignatures)) {
      if (code.includes(sig)) {
        console.log(`      ✅ ${funcName}`);
      }
    }
    
    // 5. VERIFICA ULTERIORE CON ABI ESPLORATIVE
    console.log("\n🎫 TENTATIVO DI VERIFICA FUNZIONI AVANZATE:");
    
    // Prova con ABI più estesa
    const EXTENDED_ABI_ATTEMPT = [
      "function purchaseVoterNFTAndVote(bytes32, address) payable",
      "function createElection(string, string, uint256, uint256) returns (bytes32)",
      "function getElectionResults(bytes32) view returns (tuple(address[],uint256[],uint256[],bool))"
    ];
    
    const extendedContract = new ethers.Contract(IVOTE_ADDRESS, EXTENDED_ABI_ATTEMPT, provider);
    
    const testFunctions = ['createElection', 'getElectionResults', 'purchaseVoterNFTAndVote'];
    for (const func of testFunctions) {
      try {
        // Prova a vedere se la funzione esiste
        await extendedContract[func].staticCallResult;
        console.log(`   🔍 ${func}: PRESENTE nell'ABI`);
      } catch (e) {
        if (e.message.includes("missing revert data")) {
          console.log(`   ✅ ${func}: FUNZIONE ESISTE (revert vuoto = funzione presente)`);
        } else {
          console.log(`   ❌ ${func}: NON DISPONIBILE`);
        }
      }
    }
    
    console.log("\n✅ VERIFICA COMPLETATA!");
    console.log("\n🎯 RISULTATO FINALE:");
    console.log(`   📍 Address: ${IVOTE_ADDRESS}`);
    console.log(`   🔗 BaseScan: https://basescan.org/address/${IVOTE_ADDRESS}`);
    console.log(`   📊 Bytecode: ${codeLength} bytes`);
    console.log(`   🔐 Hash: ${codeHash.substring(0, 20)}...`);
    
    console.log("\n📝 PROSSIMI PASSI:");
    console.log("   1. Visita BaseScan per verificare il codice sorgente");
    console.log("   2. Confronta nome/symbol con i contratti locali");
    console.log("   3. Verifica corrispondenza funzioni di voting");
    
  } catch (error) {
    console.log("❌ ERRORE nella verifica:");
    console.log(`   💥 ${error.message}`);
  }
}

main().catch(console.error);
