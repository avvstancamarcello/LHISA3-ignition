#!/bin/bash
# fix-compilation-errors.sh - Script per correggere automaticamente gli errori di compilazione

echo "🔧 AVVIO FIX AUTOMATICO ERRORI DI COMPILAZIONE..."

# ═══════════════════════════════════════════════════════════════════════════════
# 1. FIX EnhancedImpactLogger.sol - 'event' è parola riservata
# ═══════════════════════════════════════════════════════════════════════════════

echo "📝 Fixing EnhancedImpactLogger.sol..."
sed -i 's/ReputationEvent memory event/ReputationEvent memory repEvent/g' contracts/core_infrastructure/EnhancedImpactLogger.sol
sed -i 's/ImpactEvent memory event/ImpactEvent memory impactEvent/g' contracts/core_infrastructure/EnhancedImpactLogger.sol

# ═══════════════════════════════════════════════════════════════════════════════
# 2. FIX EnhancedModuleRouter.sol - Stringa non chiusa
# ═══════════════════════════════════════════════════════════════════════════════

echo "📝 Fixing EnhancedModuleRouter.sol..."
sed -i 's/if (_i == 0) return "0/if (_i == 0) return "0"/g' contracts/core_infrastructure/EnhancedModuleRouter.sol

# ═══════════════════════════════════════════════════════════════════════════════
# 3. FIX EnhancedReputationManager.sol - 'event' è parola riservata
# ═══════════════════════════════════════════════════════════════════════════════

echo "📝 Fixing EnhancedReputationManager.sol..."
sed -i 's/ReputationEvent memory event/ReputationEvent memory repEvent/g' contracts/core_infrastructure/EnhancedReputationManager.sol

# ═══════════════════════════════════════════════════════════════════════════════
# 4. FIX MareaMangaNFT.sol - Verifica sintassi variabili
# ═══════════════════════════════════════════════════════════════════════════════

echo "📝 Fixing MareaMangaNFT.sol..."
# Assicuriamoci che la dichiarazione sia corretta
sed -i 's/string public ipfsBaseURI/string public ipfsBaseURI;/g' contracts/planetary/MareaMangaNFT.sol

# Controlla se manca il punto e virgola prima
sed -i '/string public ipfsBaseURI[^;]*$/s/$/;/' contracts/planetary/MareaMangaNFT.sol

# ═══════════════════════════════════════════════════════════════════════════════
# 5. FIX LunaComicsFT.sol - Verifica sintassi variabili
# ═══════════════════════════════════════════════════════════════════════════════

echo "📝 Fixing LunaComicsFT.sol..."
# Assicuriamoci che la dichiarazione sia corretta
sed -i 's/string public pinataJWT/string public pinataJWT;/g' contracts/satellites/LunaComicsFT.sol

# Controlla se manca il punto e virgola prima
sed -i '/string public pinataJWT[^;]*$/s/$/;/' contracts/satellites/LunaComicsFT.sol

# ═══════════════════════════════════════════════════════════════════════════════
# 6. FIX COMUNI - Altri potenziali errori
# ═══════════════════════════════════════════════════════════════════════════════

echo "📝 Applicando fix comuni..."

# Fix per 'event' in altri contratti
find contracts/ -name "*.sol" -type f -exec sed -i 's/ memory event/ memory evt/g' {} \;

# Fix per stringhe non chiuse (pattern comune)
find contracts/ -name "*.sol" -type f -exec sed -i 's/return "0$/return "0"/g' {} \;

# Fix per punti e virgola mancanti nelle dichiarazioni
find contracts/ -name "*.sol" -type f -exec sed -i '/^[[:space:]]*string[[:space:]]\+public[[:space:]]\+[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*$/s/$/;/' {} \;

# ═══════════════════════════════════════════════════════════════════════════════
# 7. VERIFICA DEI FIX APPLICATI
# ═══════════════════════════════════════════════════════════════════════════════

echo "🔍 Verifica dei fix applicati..."
echo "--- EnhancedImpactLogger.sol (linee modificate) ---"
grep -n "repEvent\|impactEvent" contracts/core_infrastructure/EnhancedImpactLogger.sol | head -5

echo "--- EnhancedModuleRouter.sol (linee modificate) ---" 
grep -n 'return "0"' contracts/core_infrastructure/EnhancedModuleRouter.sol | head -5

echo "--- EnhancedReputationManager.sol (linee modificate) ---"
grep -n "repEvent" contracts/core_infrastructure/EnhancedReputationManager.sol | head -5

echo "--- MareaMangaNFT.sol (dichiarazioni) ---"
grep -n "ipfsBaseURI" contracts/planetary/MareaMangaNFT.sol

echo "--- LunaComicsFT.sol (dichiarazioni) ---"
grep -n "pinataJWT" contracts/satellites/LunaComicsFT.sol

echo "✅ FIX AUTOMATICO COMPLETATO!"

# ═══════════════════════════════════════════════════════════════════════════════
# 8. PROVA DI COMPILAZIONE
# ═══════════════════════════════════════════════════════════════════════════════

echo "🚀 Avvio compilazione di test..."
npx hardhat compile --config hardhat.config.dev.cjs

if [ $? -eq 0 ]; then
    echo "🎉 COMPILAZIONE SUCCESSO! Tutti gli errori sono stati fixati."
else
    echo "⚠️  Ci sono ancora errori. Controlla l'output sopra."
    echo "💡 Suggerimento: Esegui nuovamente lo script o fixa manualmente gli errori rimanenti."
fi
