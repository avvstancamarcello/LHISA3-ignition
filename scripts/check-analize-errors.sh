#!/bin/bash
# analyze-errors.sh - Analisi precisa degli errori

echo "🔍 ANALISI PRECISA ERRORI..."

echo "=== EnhancedModuleRouter.sol (linea 394) ==="
sed -n '390,400p' contracts/core_infrastructure/EnhancedModuleRouter.sol
echo "--- Contenuto linea 394: ---"
sed -n '394p' contracts/core_infrastructure/EnhancedModuleRouter.sol

echo "=== MareaMangaNFT.sol (linea 155 e contesto) ==="
sed -n '150,160p' contracts/planetary/MareaMangaNFT.sol

echo "=== LunaComicsFT.sol (linea 232 e contesto) ==="  
sed -n '228,235p' contracts/satellites/LunaComicsFT.sol

echo "✅ ANALISI COMPLETATA"
