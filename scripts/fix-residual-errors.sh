#!/bin/bash
# fix-residual-errors.sh - Fix per errori residui dopo il primo script

echo "🔧 FIX ERRORI RESIDUI..."

# ═══════════════════════════════════════════════════════════════════════════════
# 1. FIX DOPPI PUNTI E VIRGOLA
# ═══════════════════════════════════════════════════════════════════════════════

echo "📝 Fixing doppi punti e virgola..."
sed -i 's/string public ipfsBaseURI;;;/string public ipfsBaseURI;/g' contracts/planetary/MareaMangaNFT.sol
sed -i 's/string public pinataJWT;;;/string public pinataJWT;/g' contracts/satellites/LunaComicsFT.sol

# ═══════════════════════════════════════════════════════════════════════════════
# 2. FIX STRINGA DOPPIA CHIUSA
# ═══════════════════════════════════════════════════════════════════════════════

echo "📝 Fixing stringa doppia chiusa..."
sed -i 's/return "0""/return "0"/g' contracts/core_infrastructure/EnhancedModuleRouter.sol

# ═══════════════════════════════════════════════════════════════════════════════
# 3. FIX event.timestamp -> repEvent.timestamp e impactEvent.timestamp
# ═══════════════════════════════════════════════════════════════════════════════

echo "📝 Fixing event.timestamp..."
# EnhancedImpactLogger.sol
sed -i 's/_uint2str(event.timestamp)/_uint2str(impactEvent.timestamp)/g' contracts/core_infrastructure/EnhancedImpactLogger.sol

# EnhancedReputationManager.sol  
sed -i 's/_uint2str(event.timestamp)/_uint2str(repEvent.timestamp)/g' contracts/core_infrastructure/EnhancedReputationManager.sol

# ═══════════════════════════════════════════════════════════════════════════════
# 4. FIX TUTTI I event. RIMANENTI
# ═══════════════════════════════════════════════════════════════════════════════

echo "📝 Fixing tutti i reference a event..."
# Cambia event. in impactEvent. per EnhancedImpactLogger
sed -i 's/event\./impactEvent./g' contracts/core_infrastructure/EnhancedImpactLogger.sol

# Cambia event. in repEvent. per EnhancedReputationManager
sed -i 's/event\./repEvent./g' contracts/core_infrastructure/EnhancedReputationManager.sol

# ═══════════════════════════════════════════════════════════════════════════════
# 5. VERIFICA DEI FIX
# ═══════════════════════════════════════════════════════════════════════════════

echo "🔍 Verifica dei fix applicati..."
echo "--- MareaMangaNFT.sol (dichiarazioni fixed) ---"
grep -n "ipfsBaseURI" contracts/planetary/MareaMangaNFT.sol | head -3

echo "--- LunaComicsFT.sol (dichiarazioni fixed) ---"
grep -n "pinataJWT" contracts/satellites/LunaComicsFT.sol | head -3

echo "--- EnhancedModuleRouter.sol (string fixed) ---"
grep -n 'return "0"' contracts/core_infrastructure/EnhancedModuleRouter.sol

echo "--- EnhancedImpactLogger.sol (timestamp fixed) ---"
grep -n "timestamp" contracts/core_infrastructure/EnhancedImpactLogger.sol | head -5

echo "--- EnhancedReputationManager.sol (timestamp fixed) ---"
grep -n "timestamp" contracts/core_infrastructure/EnhancedReputationManager.sol | head -5

echo "✅ FIX ERRORI RESIDUI COMPLETATO!"

# ═══════════════════════════════════════════════════════════════════════════════
# 6. COMPILAZIONE DI TEST
# ═══════════════════════════════════════════════════════════════════════════════

echo "🚀 Test compilazione..."
npx hardhat compile --config hardhat.config.dev.cjs

if [ $? -eq 0 ]; then
    echo "🎉 SUCCESSO! Tutti gli errori sono stati risolti."
else
    echo "⚠️  Ancora errori. Eseguendo fix aggressivo..."
    ./fix-aggressive.sh
fi
