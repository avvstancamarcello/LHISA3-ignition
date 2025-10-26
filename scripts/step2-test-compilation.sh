#!/bin/bash

echo "🔧 STEP 2: TEST COMPILAZIONE SELETTIVA"
echo "======================================"

# Crea directory temporanea per compilazione selettiva
mkdir -p contracts_temp
mkdir -p artifacts_temp
mkdir -p cache_temp

# Copia SOLO i 3 contratti selezionati
echo "📁 Copia contratti selezionati..."
cp contracts/governance_consensus/VotoGratis_Entertainment.sol contracts_temp/
cp contracts/governance_consensus/IVOTE_NFT.sol contracts_temp/
cp contracts/governance_consensus/IVOTE_V2_WithRefund.sol contracts_temp/

# Crea hardhat.config.js temporaneo
cat > hardhat.config.temp.js << 'CONFIG'
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.29",
  paths: {
    sources: "./contracts_temp",
    artifacts: "./artifacts_temp",
    cache: "./cache_temp"
  }
};
CONFIG

echo "🛠️  Tentativo di compilazione..."
npx hardhat compile --config hardhat.config.temp.js

# Pulizia
rm -rf contracts_temp artifacts_temp cache_temp hardhat.config.temp.js

echo ""
echo "✅ TEST COMPILAZIONE COMPLETATO"
