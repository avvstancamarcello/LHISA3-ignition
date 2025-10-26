#!/usr/bin/env bash
set -euo pipefail

# cartelle principali
SRC_CONTRACTS="contracts"
ACTIVE_CONTRACTS="contracts_attive"

# crea le cartelle di destinazione se non esistono
mkdir -p "$ACTIVE_CONTRACTS/core_infrastructure" \
         "$ACTIVE_CONTRACTS/core_justice" \
         "$ACTIVE_CONTRACTS/nft" \
         "$ACTIVE_CONTRACTS/satellites" \
         "$ACTIVE_CONTRACTS/interoperability_bridges" \
         "$ACTIVE_CONTRACTS/metrics" \
         "$ACTIVE_CONTRACTS/core"

echo "== Curazione contratti attivi =="

# 1) EnhancedReputationManager.sol  → contracts_attive/core_infrastructure/
if [ -f "$SRC_CONTRACTS/core_infrastructure/EnhancedReputationManager.sol" ]; then
  git mv -f "$SRC_CONTRACTS/core_infrastructure/EnhancedReputationManager.sol" \
            "$ACTIVE_CONTRACTS/core_infrastructure/EnhancedReputationManager.sol"
  echo "✓ Moved EnhancedReputationManager.sol"
elif [ -f "$ACTIVE_CONTRACTS/core_infrastructure/EnhancedReputationManager.sol" ]; then
  echo "• Already present: $ACTIVE_CONTRACTS/core_infrastructure/EnhancedReputationManager.sol"
else
  echo "✗ NON TROVATO: EnhancedReputationManager.sol (salvalo e rilancia lo script)"
fi

# 2) EnhancedImpactLogger.sol → contracts_attive/core_infrastructure/ (opzionale ma consigliato)
if [ -f "$SRC_CONTRACTS/core_infrastructure/EnhancedImpactLogger.sol" ]; then
  git mv -f "$SRC_CONTRACTS/core_infrastructure/EnhancedImpactLogger.sol" \
            "$ACTIVE_CONTRACTS/core_infrastructure/EnhancedImpactLogger.sol"
  echo "✓ Moved EnhancedImpactLogger.sol"
elif [ -f "$ACTIVE_CONTRACTS/core_infrastructure/EnhancedImpactLogger.sol" ]; then
  echo "• Already present: $ACTIVE_CONTRACTS/core_infrastructure/EnhancedImpactLogger.sol"
else
  echo "• (Opzionale) NON trovato EnhancedImpactLogger.sol — puoi aggiungerlo in seguito"
fi

# 3) EnhancedSolidaryTrustManager.sol → contracts_attive/core_infrastructure/
#   Prova percorsi possibili; se trovi la vecchia SolidaryTrustManager.sol, rinominala.
if [ -f "$SRC_CONTRACTS/core_infrastructure/EnhancedSolidaryTrustManager.sol" ]; then
  git mv -f "$SRC_CONTRACTS/core_infrastructure/EnhancedSolidaryTrustManager.sol" \
            "$ACTIVE_CONTRACTS/core_infrastructure/EnhancedSolidaryTrustManager.sol"
  echo "✓ Moved EnhancedSolidaryTrustManager.sol"
elif [ -f "$SRC_CONTRACTS/governance_consensus/EnhancedSolidaryTrustManager.sol" ]; then
  git mv -f "$SRC_CONTRACTS/governance_consensus/EnhancedSolidaryTrustManager.sol" \
            "$ACTIVE_CONTRACTS/core_infrastructure/EnhancedSolidaryTrustManager.sol"
  echo "✓ Moved EnhancedSolidaryTrustManager.sol (from governance_consensus)"
elif [ -f "$SRC_CONTRACTS/governance_consensus/SolidaryTrustManager.sol" ]; then
  # rinomina la versione "non enhanced" a EnhancedSolidaryTrustManager.sol solo se è quella aggiornata che hai salvato lì
  git mv -f "$SRC_CONTRACTS/governance_consensus/SolidaryTrustManager.sol" \
            "$ACTIVE_CONTRACTS/core_infrastructure/EnhancedSolidaryTrustManager.sol"
  echo "✓ Renamed & moved SolidaryTrustManager.sol → EnhancedSolidaryTrustManager.sol (verifica sia la versione 'enhanced')"
elif [ -f "$ACTIVE_CONTRACTS/core_infrastructure/EnhancedSolidaryTrustManager.sol" ]; then
  echo "• Already present: $ACTIVE_CONTRACTS/core_infrastructure/EnhancedSolidaryTrustManager.sol"
else
  echo "✗ NON TROVATO: EnhancedSolidaryTrustManager.sol — salva il file e rilancia lo script"
fi

# 4) Rimuovi file legacy/doppi che non vogliamo compilare
#   a) governance_consensus/EnhancedSolidaryHub.sol (duplicato/legacy)
if [ -f "$SRC_CONTRACTS/governance_consensus/EnhancedSolidaryHub.sol" ]; then
  git rm -f "$SRC_CONTRACTS/governance_consensus/EnhancedSolidaryHub.sol"
  echo "✓ Removed legacy governance_consensus/EnhancedSolidaryHub.sol"
else
  echo "• Nessun EnhancedSolidaryHub.sol legacy in governance_consensus/ (ok)"
fi

#   b) core/Orchestrator.sol (non usato: usiamo UniversalMultiChainOrchestratorV2)
if [ -f "$ACTIVE_CONTRACTS/core/Orchestrator.sol" ]; then
  git rm -f "$ACTIVE_CONTRACTS/core/Orchestrator.sol"
  echo "✓ Removed contracts_attive/core/Orchestrator.sol"
elif [ -f "$SRC_CONTRACTS/core/Orchestrator.sol" ]; then
  git rm -f "$SRC_CONTRACTS/core/Orchestrator.sol"
  echo "✓ Removed contracts/core/Orchestrator.sol"
else
  echo "• Nessun Orchestrator.sol da rimuovere (ok)"
fi

echo
echo "== Riepilogo attivi =="
find "$ACTIVE_CONTRACTS" -type f -name "*.sol" | sort

echo
echo "✅ Pronto. Imposta (se non l’hai già fatto) in hardhat.config.ts:"
echo "    paths: { sources: \"contracts_attive\" }"
