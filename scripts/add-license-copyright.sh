#!/bin/bash

# Script per aggiungere copyright a tutti i file .sol nella struttura attuale
# Mantiene SPDX alla riga 1, pragma alla riga 2, e aggiunge copyright alla riga 4

echo "🔧 Adding copyright to all .sol files in contracts folder..."

# Trova tutti i file .sol nella struttura attuale
find ./contracts -name "*.sol" -type f | while read -r file; do
    echo "Processing: $file"
    
    # Crea un file temporaneo
    temp_file=$(mktemp)
    
    # Leggi il contenuto del file
    if [[ -f "$file" ]]; then
        # Controlla se il copyright è già presente nelle prime 5 righe
        if head -5 "$file" | grep -q "Copyright.*Marcello Stanca"; then
            echo "  ✅ Copyright already present in $file"
            continue
        fi
        
        # Leggi il file riga per riga
        line_number=1
        spdx_line=""
        pragma_line=""
        other_lines=()
        
        while IFS= read -r line; do
            if [[ $line_number -eq 1 ]]; then
                if [[ $line == *"SPDX-License-Identifier"* ]]; then
                    spdx_line="$line"
                else
                    spdx_line="// SPDX-License-Identifier: UNLICENSED"
                    other_lines+=("$line")
                fi
            elif [[ $line_number -eq 2 ]]; then
                if [[ $line == *"pragma solidity"* ]]; then
                    pragma_line="$line"
                else
                    pragma_line="pragma solidity ^0.8.29;"
                    other_lines+=("$line")
                fi
            else
                other_lines+=("$line")
            fi
            ((line_number++))
        done < "$file"
        
        # Scrivi il nuovo contenuto
        {
            echo "$spdx_line"
            echo "$pragma_line"
            echo ""
            echo "// © Copyright Marcello Stanca - Italy - Florence. Author and owner of the Solidary.it ecosystem and this smart contract. The ecosystem and its logical components (.sol files and scripts) are protected by copyright."
            echo ""
            
            # Aggiungi le altre righe
            for other_line in "${other_lines[@]}"; do
                echo "$other_line"
            done
        } > "$temp_file"
        
        # Sostituisci il file originale
        mv "$temp_file" "$file"
        echo "  ✅ Copyright added to $file"
    fi
    
    echo "-----------------------------"
done

echo "🎉 Copyright insertion completed for all .sol files!"
echo "📋 Summary:"
echo "   - SPDX-License-Identifier: UNLICENSED (line 1)"
echo "   - pragma solidity ^0.8.29; (line 2)"
echo "   - Empty line (line 3)"
echo "   - Copyright notice (line 4)"
echo "   - Empty line (line 5)"
echo "   - Original content follows..."
