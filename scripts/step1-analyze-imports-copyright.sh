#!/bin/bash

echo "🔍 STEP 1: ANALISI IMPORTS E COPYRIGHT"
echo "========================================"

CONTRACTS=(
    "VotoGratis_Entertainment.sol"
    "IVOTE_NFT.sol" 
    "IVOTE_V2_WithRefund.sol"
)

for contract in "${CONTRACTS[@]}"; do
    echo ""
    echo "📄 CONTRATTO: $contract"
    echo "────────────────────────────────────"
    
    # Verifica esistenza file - PATH CORRETTO
    if [ ! -f "contracts/governance_consensus/$contract" ]; then
        echo "❌ FILE NON TROVATO: contracts/governance_consensus/$contract"
        continue
    fi
    
    # 1. VERIFICA COPYRIGHT
    echo "📝 COPYRIGHT:"
    if grep -q "Copyright.*Marcello Stanca" "contracts/governance_consensus/$contract"; then
        echo "   ✅ Copyright Marcello Stanca presente"
    else
        echo "   ⚠️  Copyright non trovato"
    fi
    
    # 2. VERIFICA IMPORTS OPENZEPPELIN
    echo "📦 IMPORTS OPENZEPPELIN:"
    grep -n "import.*openzeppelin" "contracts/governance_consensus/$contract" | while read line; do
        if [[ $line == *"/security/"* ]]; then
            echo "   ❌ OBSOLETO: $line"
        elif [[ $line == *"/utils/"* ]]; then
            echo "   ✅ CORRETTO: $line"
        else
            echo "   📍 STANDARD: $line"
        fi
    done
    
    # 3. CONTA IMPORTS TOTALI
    import_count=$(grep -c "import" "contracts/governance_consensus/$contract")
    echo "   📊 Totale imports: $import_count"
done

echo ""
echo "✅ ANALISI COMPLETATA - Controlla i risultati sopra"
