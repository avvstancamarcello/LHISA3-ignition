#!/bin/bash

echo "🔧 Correzione warnings EthereumPolygonMultiTokenBridge.sol..."

FILE="contracts/interoperability_bridges/EthereumPolygonMultiTokenBridge.sol"

# 1. Correggi parametri non utilizzati (riga 395)
sed -i '395s/address sourceToken, address targetToken,/address /* sourceToken */, address /* targetToken */,/' "$FILE"

# 2. Correggi parametro non utilizzato (riga 412)
sed -i '412s/string memory category, uint256 originalAmount,/string memory category, uint256 /* originalAmount */,/' "$FILE"

# 3. Correggi variabile locale non utilizzata (riga 413)
sed -i '413s/(bool success, ) = impactLogger/(/* bool success, */ ) = impactLogger/' "$FILE"

# 4. Aggiungi pure alla funzione (riga 395)
sed -i '395s/function _calculateSwapAmount(/function _calculateSwapAmount(/' "$FILE"
# Dobbiamo aggiungere 'pure' dopo i parametri
sed -i '/function _calculateSwapAmount.*amount)/a\    ) internal pure returns (uint256) {' "$FILE"

echo "✅ Warnings corretti!"
echo "📋 Verifica:"
grep -n -A 2 -B 2 "function _calculateSwapAmount" "$FILE"
