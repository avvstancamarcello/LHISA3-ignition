# scripts/fix-openzeppelin-imports.sh
#!/bin/bash

echo "🔧 CORREZIONE IMPORT OPENZEPPELIN..."
echo "📁 Aggiornando percorsi security → utils..."

# Correggi in tutti i file .sol
find contracts/interoperability_bridges -name "*.sol" -exec sed -i 's/security\/ReentrancyGuardUpgradeable/utils\/ReentrancyGuardUpgradeable/g' {} \;
find contracts/interoperability_bridges -name "*.sol" -exec sed -i 's/security\/PausableUpgradeable/utils\/PausableUpgradeable/g' {} \;

echo "✅ Import OpenZeppelin corretti!"
echo "🔍 Verifica:"
grep -r "ReentrancyGuardUpgradeable" contracts/interoperability_bridges/
