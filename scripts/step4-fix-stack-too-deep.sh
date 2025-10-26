#!/bin/bash

echo "🔧 STEP 4: CORREZIONE STACK TOO DEEP"
echo "===================================="

# Crea struttura directory temporanea
mkdir -p contracts_temp/governance_consensus
mkdir -p contracts_temp/core_justice
mkdir -p artifacts_temp
mkdir -p cache_temp

# Copia contratti
cp contracts/governance_consensus/*.sol contracts_temp/governance_consensus/
cp contracts/core_justice/RefundManager.sol contracts_temp/core_justice/

# Crea hardhat.config con OTTIMIZZAZIONE e viaIR
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
      },
      viaIR: true  // 🔥 SOLUZIONE PER STACK TOO DEEP
    }
  },
  paths: {
    sources: "./contracts_temp",
    artifacts: "./artifacts_temp",
    cache: "./cache_temp"
  }
};
CONFIG

echo "🛠️  Compilazione con viaIR abilitato..."
if npx hardhat compile --config hardhat.config.temp.js; then
    echo ""
    echo "🎉 COMPILAZIONE SUCCESSO!"
    echo ""
    echo "📊 CONTRATTI COMPILATI:"
    find artifacts_temp -name "*.json" | grep -E "(VotoGratis|IVOTE)" | while read file; do
        contract_name=$(basename "$file" .json)
        size=$(jq -r '.deployedBytecode | length' "$file")
        echo "   ✅ $contract_name ($((size/2)) bytes)"
    done
    
    # Verifica ABI
    echo ""
    echo "📋 FUNZIONI DISPONIBILI:"
    for contract in "VotoGratis_Entertainment" "IVOTEVoterNFT" "IVOTE_V2_WithRefund"; do
        if [ -f "artifacts_temp/contracts_temp/governance_consensus/${contract}.sol/${contract}.json" ]; then
            functions=$(jq -r '.abi[] | select(.type == "function") | .name' "artifacts_temp/contracts_temp/governance_consensus/${contract}.sol/${contract}.json" 2>/dev/null | head -5)
            count=$(echo "$functions" | grep -c .) || count=0
            echo "   🔸 $contract: $count funzioni"
            if [ "$count" -gt 0 ]; then
                echo "      📝 ${functions//$'\n'/, }"
            fi
        fi
    done
else
    echo ""
    echo "❌ COMPILAZIONE FALLITA ANCORA"
    echo "   Prova soluzione alternativa..."
fi

# Pulizia
rm -rf contracts_temp artifacts_temp cache_temp hardhat.config.temp.js

echo ""
echo "✅ STEP 4 COMPLETATO"
