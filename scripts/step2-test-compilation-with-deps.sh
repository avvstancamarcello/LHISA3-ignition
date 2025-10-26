#!/bin/bash

echo "🔧 STEP 2: TEST COMPILAZIONE CON DIPENDENZE"
echo "============================================"

# Crea directory temporanea
mkdir -p contracts_temp
mkdir -p artifacts_temp
mkdir -p cache_temp

echo "📁 Copia contratti e dipendenze..."

# 1. Copia i 3 contratti principali
cp contracts/governance_consensus/VotoGratis_Entertainment.sol contracts_temp/
cp contracts/governance_consensus/IVOTE_NFT.sol contracts_temp/
cp contracts/governance_consensus/IVOTE_V2_WithRefund.sol contracts_temp/

# 2. Copia le dipendenze (RefundManager e altre)
if [ -f "contracts/core_justice/RefundManager.sol" ]; then
    cp contracts/core_justice/RefundManager.sol contracts_temp/
    echo "✅ Copiato: RefundManager.sol"
else
    echo "❌ RefundManager.sol non trovato!"
fi

# 3. Crea hardhat.config.js temporaneo
cat > hardhat.config.temp.js << 'CONFIG'
require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");

module.exports = {
  solidity: {
    version: "0.8.29",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  paths: {
    sources: "./contracts_temp",
    artifacts: "./artifacts_temp", 
    cache: "./cache_temp"
  },
  networks: {
    local: {
      url: "http://127.0.0.1:8545"
    }
  }
};
CONFIG

echo "🛠️  Tentativo di compilazione..."
if npx hardhat compile --config hardhat.config.temp.js; then
    echo "🎉 COMPILAZIONE SUCCESSO!"
    echo ""
    echo "📊 CONTRATTI COMPILATI:"
    find artifacts_temp -name "*.json" | grep -E "(VotoGratis|IVOTE)" | while read file; do
        contract_name=$(basename "$file" .json)
        echo "   ✅ $contract_name"
    done
else
    echo "❌ COMPILAZIONE FALLITA - Controlla errori sopra"
fi

# Pulizia
rm -rf contracts_temp artifacts_temp cache_temp hardhat.config.temp.js

echo ""
echo "✅ TEST COMPILAZIONE COMPLETATO"
