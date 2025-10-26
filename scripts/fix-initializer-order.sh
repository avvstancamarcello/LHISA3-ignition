#!/bin/bash

echo "🔧 Correzione ordine initializer..."

# Crea backup
cp contracts/creative_cultural/SolidaryComix.sol contracts/creative_cultural/SolidaryComix.sol.backup-initializer

# Correggi la funzione initialize
sed -i '/__RefundManager_init(_creatorWallet, _solidaryWallet, _refundDeadline, _initialThreshold);/i\    __ERC1155_init(""); // ✅ Inizializza ERC1155 prima di RefundManager' contracts/creative_cultural/SolidaryComix.sol

echo "✅ Initializer corretto!"
echo "📋 Verifica:"
grep -A 5 -B 2 "__ERC1155_init" contracts/creative_cultural/SolidaryComix.sol
