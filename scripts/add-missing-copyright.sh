#!/bin/bash

echo "📄 Aggiunta copyright ai contratti mancanti..."

# Lista dei contratti che mancano di copyright
missing_copyright=(
    "contracts/creative_cultural/SolidaryManga.sol"
    "contracts/core_justice/ConcreteRefundManager.sol"
)

for file in "${missing_copyright[@]}"; do
    if [ -f "$file" ]; then
        echo "🔧 Aggiungendo copyright a: $(basename $file)"
        
        # Crea backup
        cp "$file" "$file.backup"
        
        # Crea file con header copyright
        cat > "$file.new" << 'HEADER'
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

// Copyright © 2025 Avv. Marcello Stanca - Firenze, Italia. All Rights Reserved.
// Hoc contractum, pars Systematis Solidarii, ab Auctore Marcello Stanca 
// Caritati Internationalis (MCMLXXVI) gratis conceditur.
// (This smart contract, part of the Solidary System, is granted for free use 
// to Caritas Internationalis (1976) by the author, Marcello Stanca.)

HEADER

        # Aggiungi contenuto originale (escludendo header duplicati)
        grep -v "SPDX-License-Identifier" "$file" | \
        grep -v "pragma solidity" | \
        grep -v "Copyright" | \
        grep -v "Hoc contractum" | \
        grep -v "This smart contract" >> "$file.new"

        # Sostituisci il file originale
        mv "$file.new" "$file"
        
        echo "   ✅ Copyright aggiunto a $(basename $file)"
    else
        echo "   ⚠️  File non trovato: $file"
    fi
done

echo ""
echo "✅ Copyright applicato a tutti i contratti mancanti!"
