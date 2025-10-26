#!/bin/bash

echo "🚀 STEP 5: DEPLOY FINALE SU BASE NETWORK"
echo "========================================="

# Verifica che le variabili d'ambiente siano impostate
if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ PRIVATE_KEY non impostata"
    echo "   Esportala con: export PRIVATE_KEY=il_tuo_private_key"
    exit 1
fi

if [ -z "$BASE_RPC_URL" ]; then
    echo "⚠️  BASE_RPC_URL non impostata, uso default..."
    export BASE_RPC_URL="https://mainnet.base.org"
fi

# Crea hardhat.config finale per deploy
cat > hardhat.config.final.js << 'CONFIG'
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
      viaIR: true
    }
  },
  networks: {
    base: {
      url: process.env.BASE_RPC_URL,
      accounts: [process.env.PRIVATE_KEY],
      gas: 10000000,
      gasPrice: 2000000000,
    }
  },
  etherscan: {
    apiKey: {
      base: process.env.BASESCAN_API_KEY || "API_KEY"
    }
  }
};
CONFIG

echo "📦 Preparazione deploy..."
echo "   🔗 Network: Base Mainnet"
echo "   💰 Gas Price: 2 Gwei"
echo "   🛠️  Contratti da deployare: 3"

# Deploy sequenziale
echo ""
echo "1. 🎪 Deploy VotoGratis Entertainment..."
npx hardhat run scripts/deploy-entertainment.js --network base --config hardhat.config.final.js

echo ""
echo "2. 🎨 Deploy IVOTE NFT..."
npx hardhat run scripts/deploy-ivote-nft.js --network base --config hardhat.config.final.js

echo ""
echo "3. 💰 Deploy IVOTE V2 With Refund..."
npx hardhat run scripts/deploy-ivote-v2.js --network base --config hardhat.config.final.js

# Pulizia
rm -f hardhat.config.final.js

echo ""
echo "✅ DEPLOY COMPLETATO SU BASE NETWORK"
