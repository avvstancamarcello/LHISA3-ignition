#!/bin/bash

echo "🛡️  DEPLOY ULTRA-SICURO - FILE TEMPORANEO AUTODISTRUGGENTE"
echo "=========================================================="

# Verifica che sia stato passato il private key
if [ -z "$1" ]; then
    echo "❌ USAGE: $0 <private_key_senza_0x>"
    echo "   Esempio: $0 abc123def456..."
    exit 1
fi

# Verifica lunghezza private key (64 caratteri per private key senza 0x)
if [ ${#1} -ne 64 ]; then
    echo "❌ ERRORE: Private key deve essere 64 caratteri (senza 0x)"
    echo "   Lunghezza attuale: ${#1} caratteri"
    exit 1
fi

echo "✅ Private key validato (64 caratteri)"

# Crea file temporaneo con permessi ristretti
TEMP_ENV=$(mktemp)
chmod 600 "$TEMP_ENV"  # Solo owner può leggere/scrivere

# Scrivi le variabili nel file temporaneo
echo "PRIVATE_KEY=$1" > "$TEMP_ENV"
echo "BASE_RPC_URL=https://mainnet.base.org" >> "$TEMP_ENV"
echo "BASESCAN_API_KEY=YOUR_API_KEY" >> "$TEMP_ENV"

echo "📁 File temporaneo creato: $TEMP_ENV"
echo "🔐 Permessi ristretti applicati"

# Funzione di pulizia che si assicura di eliminare il file
cleanup() {
    echo ""
    echo "🧹 Pulizia sicura in corso..."
    if [ -f "$TEMP_ENV" ]; then
        shred -u "$TEMP_ENV" 2>/dev/null || rm -f "$TEMP_ENV"
        echo "✅ File temporaneo distrutto"
    else
        echo "✅ File già distrutto"
    fi
}

# Registra la funzione di pulizia per esecuzione anche su errori
trap cleanup EXIT

echo ""
echo "🚀 INIZIO DEPLOY SU BASE NETWORK..."
echo "   📍 Network: Base Mainnet"
echo "   🔗 RPC: https://mainnet.base.org"
echo "   💰 Assicurati di avere fondi per gas!"
echo ""

# 1. DEPLOY VotoGratis Entertainment
echo "🎪 1/3 - Deploy VotoGratis Entertainment..."
if npx hardhat run scripts/deploy-entertainment.js --network base --env-file "$TEMP_ENV"; then
    echo "   ✅ SUCCESSO"
else
    echo "   ❌ FALLITO - Continuo con i prossimi..."
fi

echo ""

# 2. DEPLOY IVOTE NFT
echo "🎨 2/3 - Deploy IVOTE NFT..."
if npx hardhat run scripts/deploy-ivote-nft.js --network base --env-file "$TEMP_ENV"; then
    echo "   ✅ SUCCESSO"
else
    echo "   ❌ FALLITO - Continuo con i prossimi..."
fi

echo ""

# 3. DEPLOY IVOTE V2 With Refund
echo "💰 3/3 - Deploy IVOTE V2 With Refund..."
if npx hardhat run scripts/deploy-ivote-v2.js --network base --env-file "$TEMP_ENV"; then
    echo "   ✅ SUCCESSO"
else
    echo "   ❌ FALLITO"
fi

echo ""
echo "🎯 DEPLOY COMPLETATO!"
echo "   I file temporanei sono stati automaticamente distrutti"

