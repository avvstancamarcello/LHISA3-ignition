#!/bin/bash

echo "🔧 Correzione import contratti multi-chain..."

# Correggi tutti i file nella directory interoperability_bridges
for file in contracts/interoperability_bridges/*.sol; do
    if [ -f "$file" ]; then
        echo "📝 Correggendo: $(basename $file)"
        
        # Correggi ReentrancyGuard path
        sed -i 's|@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable|@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable|g' "$file"
        
        # Correggi IERC20Upgradeable (se necessario)
        sed -i 's|token/ERC20/IERC20Upgradeable|token/ERC20/IERC20Upgradeable|g' "$file"
        
        # Correggi IERC721Upgradeable (se necessario)  
        sed -i 's|token/ERC721/IERC721Upgradeable|token/ERC721/IERC721Upgradeable|g' "$file"
        
        echo "   ✅ $(basename $file) corretto"
    fi
done

echo "🎯 Tutti gli import corretti!"
