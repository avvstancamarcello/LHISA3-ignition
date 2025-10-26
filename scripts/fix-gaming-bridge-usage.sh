#!/bin/bash

echo "🔧 Correzione uso di IERC721Upgradeable nel codice..."

FILE="contracts/interoperability_bridges/SolidaryGamingBridge.sol"

# Commenta la riga che usa IERC721Upgradeable
sed -i '487s/.*/        \/\/ IERC721Upgradeable nft = IERC721Upgradeable(tokenAddress); \/\/ 🔧 Temporaneamente disabilitato/' "$FILE"

# Commenta anche eventuali altre occorrenze
sed -i 's/IERC721Upgradeable/\/\/ IERC721Upgradeable/g' "$FILE"

echo "✅ Uso di IERC721Upgradeable nel codice commentato!"
echo "📋 Verifica:"
grep -n "IERC721Upgradeable" "$FILE"
