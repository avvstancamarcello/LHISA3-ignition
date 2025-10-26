#!/bin/bash

echo "🛡️  DEPLOY ULTRA-SICURO V2 - HARDHAT COMPATIBLE"
echo "================================================"

if [ -z "$1" ]; then
    echo "❌ USAGE: $0 <private_key_senza_0x>"
    exit 1
fi

if [ ${#1} -ne 64 ]; then
    echo "❌ ERRORE: Private key deve essere 64 caratteri (senza 0x)"
    exit 1
fi

echo "✅ Private key validato"

# Crea hardhat.config temporaneo
TEMP_CONFIG=$(mktemp)
chmod 600 "$TEMP_CONFIG"

cat > "$TEMP_CONFIG" << 'CONFIG'
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
      url: "https://mainnet.base.org",
      accounts: ["0x__PRIVATE_KEY__"],
      gas: 10000000,
      gasPrice: 2000000000,
    }
  },
  etherscan: {
    apiKey: {
      base: "YOUR_API_KEY"
    }
  }
};
CONFIG

# Sostituisci il placeholder con il vero private key
sed -i "s/0x__PRIVATE_KEY__/0x$1/g" "$TEMP_CONFIG"

echo "📁 Config temporanea creata: $TEMP_CONFIG"

cleanup() {
    echo "🧹 Pulizia sicura..."
    if [ -f "$TEMP_CONFIG" ]; then
        shred -u "$TEMP_CONFIG" 2>/dev/null || rm -f "$TEMP_CONFIG"
        echo "✅ Config temporanea distrutta"
    fi
}

trap cleanup EXIT

echo ""
echo "🚀 INIZIO DEPLOY SU BASE NETWORK..."

# 1. DEPLOY VotoGratis Entertainment
echo "🎪 1/3 - Deploy VotoGratis Entertainment..."
if npx hardhat run scripts/deploy-entertainment.js --network base --config "$TEMP_CONFIG"; then
    echo "   ✅ SUCCESSO"
else
    echo "   ❌ FALLITO - Continuo..."
fi

echo ""

# 2. DEPLOY IVOTE NFT
echo "🎨 2/3 - Deploy IVOTE NFT..."
if npx hardhat run scripts/deploy-ivote-nft.js --network base --config "$TEMP_CONFIG"; then
    echo "   ✅ SUCCESSO"
else
    echo "   ❌ FALLITO - Continuo..."
fi

echo ""

# 3. DEPLOY IVOTE V2 With Refund
echo "💰 3/3 - Deploy IVOTE V2 With Refund..."
if npx hardhat run scripts/deploy-ivote-v2.js --network base --config "$TEMP_CONFIG"; then
    echo "   ✅ SUCCESSO"
else
    echo "   ❌ FALLITO"
fi

echo ""
echo "🎯 DEPLOY COMPLETATO!"

