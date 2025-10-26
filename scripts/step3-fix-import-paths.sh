#!/bin/bash

echo "🔧 STEP 3: CORREZIONE IMPORTS PATH"
echo "=================================="

CONTRACTS=(
    "VotoGratis_Entertainment.sol"
    "IVOTE_NFT.sol" 
    "IVOTE_V2_WithRefund.sol"
)

for contract in "${CONTRACTS[@]}"; do
    echo ""
    echo "📄 Contratto: $contract"
    
    # Crea copia di lavoro
    cp "contracts/governance_consensus/$contract" "contracts/governance_consensus/${contract}.backup"
    
    # Correggi gli import path
    sed -i 's|import "\.\./core_justice/|import "../core_justice/|g' "contracts/governance_consensus/$contract"
    sed -i 's|import "\.\./core_infrastructure/|import "../core_infrastructure/|g' "contracts/governance_consensus/$contract"
    
    echo "   ✅ Backup creato e paths verificati"
    
    # Mostra imports corretti
    echo "   📋 Imports dopo correzione:"
    grep -n "import.*\.\." "contracts/governance_consensus/$contract" | head -3
done

echo ""
echo "🎯 Ora testiamo la compilazione con la struttura corretta..."
echo ""

# Crea struttura directory temporanea corretta
mkdir -p contracts_temp/governance_consensus
mkdir -p contracts_temp/core_justice
mkdir -p artifacts_temp
mkdir -p cache_temp

# Copia contratti con struttura directory
cp contracts/governance_consensus/*.sol contracts_temp/governance_consensus/
cp contracts/core_justice/RefundManager.sol contracts_temp/core_justice/

# Crea hardhat.config con paths corretti
cat > hardhat.config.temp.js << 'CONFIG'
require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");

module.exports = {
  solidity: "0.8.29",
  paths: {
    sources: "./contracts_temp",
    artifacts: "./artifacts_temp",
    cache: "./cache_temp"
  }
};
CONFIG

echo "🛠️  Tentativo di compilazione con struttura corretta..."
if npx hardhat compile --config hardhat.config.temp.js; then
    echo ""
    echo "🎉 COMPILAZIONE SUCCESSO!"
    echo ""
    echo "📊 CONTRATTI COMPILATI:"
    find artifacts_temp -name "*.json" | grep -E "(VotoGratis|IVOTE)" | while read file; do
        contract_name=$(basename "$file" .json)
        echo "   ✅ $contract_name"
    done
else
    echo ""
    echo "❌ COMPILAZIONE FALLITA"
    echo "   Controlla se mancano altre dipendenze"
fi

# Pulizia
rm -rf contracts_temp artifacts_temp cache_temp hardhat.config.temp.js

echo ""
echo "✅ STEP 3 COMPLETATO"
