#!/bin/bash

echo "🔧 CORREZIONE COMPLETA IMPORT OPENZEPPELIN v5.4.0..."

# Correggi tutti i percorsi problematici
echo "📁 Correzione ReentrancyGuard..."
find contracts/interoperability_bridges -name "*.sol" -exec sed -i 's/security\/ReentrancyGuardUpgradeable/utils\/ReentrancyGuardUpgradeable/g' {} \;

echo "📁 Correzione IERC721Upgradeable..."
find contracts/interoperability_bridges -name "*.sol" -exec sed -i 's/token\/ERC721\/IERC721Upgradeable/token\/ERC721\/IERC721Upgradeable/g' {} \;

echo "📁 Correzione IERC20Upgradeable..."
find contracts/interoperability_bridges -name "*.sol" -exec sed -i 's/token\/ERC20\/IERC20Upgradeable/token\/ERC20\/IERC20Upgradeable/g' {} \;

echo "📁 Correzione IERC20 (non-upgradeable)..."
find contracts/interoperability_bridges -name "*.sol" -exec sed -i 's/token\/ERC20\/IERC20/token\/ERC20\/IERC20/g' {} \;

echo "📁 Correzione SafeERC20..."
find contracts/interoperability_bridges -name "*.sol" -exec sed -i 's/token\/ERC20\/utils\/SafeERC20/token\/ERC20\/utils\/SafeERC20/g' {} \;

echo "✅ Tutti gli import corretti!"
echo "🔍 Verifica:"
grep -r "import.*openzeppelin" contracts/interoperability_bridges/ | head -10
