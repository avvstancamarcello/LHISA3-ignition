#!/bin/bash

echo "🚀 DEPLOY FINALE CONTRATTI IVOTE ECOSYSTEM"
echo "=========================================="

if [ -z "$1" ]; then
    echo "❌ USAGE: $0 <private_key_senza_0x>"
    exit 1
fi

if [ ${#1} -ne 64 ]; then
    echo "❌ ERRORE: Private key deve essere 64 caratteri"
    exit 1
fi

echo "✅ Private key validato"
echo "📊 Deploy di 3 contratti su Base Mainnet"

# Crea config temporanea
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
  }
};
CONFIG

sed -i "s/0x__PRIVATE_KEY__/0x$1/g" "$TEMP_CONFIG"

cleanup() {
    echo "🧹 Pulizia file temporanei..."
    rm -f "$TEMP_CONFIG"
}
trap cleanup EXIT

echo ""
echo "🎯 INIZIO DEPLOY..."

# 1. VotoGratis Entertainment
echo ""
echo "🎪 1/3 - Deploy VotoGratis Entertainment..."
if npx hardhat run scripts/deploy-entertainment.js --network base --config "$TEMP_CONFIG"; then
    echo "   ✅ SUCCESSO"
else
    echo "   ❌ FALLITO"
fi

# 2. IVOTE NFT (collegato a IVOTE esistente)
echo ""
echo "🎨 2/3 - Deploy IVOTE NFT..."
if npx hardhat run scripts/deploy-ivote-nft.js --network base --config "$TEMP_CONFIG"; then
    echo "   ✅ SUCCESSO"
else
    echo "   ❌ FALLITO"
fi

# 3. IVOTE V2 With Refund (UPGRADE dell'esistente)
echo ""
echo "💰 3/3 - Upgrade IVOTE a V2 With Refund..."
if npx hardhat run scripts/upgrade-ivote-v2.js --network base --config "$TEMP_CONFIG"; then
    echo "   ✅ SUCCESSO"
else
    echo "   ❌ FALLITO - Forse il contratto non è upgradeable?"
fi

echo ""
echo "🎉 DEPLOY COMPLETATO!"
echo "🔗 Verifica su BaseScan i nuovi contratti"
