#!/bin/bash

echo "🔧 Correzione FINALE warnings SPDX e pragma..."

FILE="contracts/interoperability_bridges/EthereumPolygonMultiTokenBridge.sol"

# Verifica lo stato attuale del file
echo "📋 Stato attuale del file:"
head -5 "$FILE"

# Correggi aggiungendo SPDX e pragma se mancanti
if ! grep -q "SPDX-License-Identifier" "$FILE"; then
    echo "📝 Aggiungendo SPDX license..."
    # Crea file temporaneo con header corretto
    cat > /tmp/fixed_header.sol << 'HEADER'
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

// Copyright © 2025 Avv. Marcello Stanca - Firenze, Italia. All Rights Reserved.
// Hoc contractum, pars Systematis Solidarii, ab Auctore Marcello Stanca 
// Caritati Internationalis (MCMLXXVI) gratis conceditur.
// (This smart contract, part of the Solidary System, is granted for free use 
// to Caritas Internationalis (1976) by the author, Marcello Stanca.)

HEADER
    # Aggiungi il resto del file
    cat "$FILE" >> /tmp/fixed_header.sol
    mv /tmp/fixed_header.sol "$FILE"
    echo "✅ SPDX e pragma aggiunti!"
else
    echo "✅ SPDX già presente!"
fi

# Verifica finale
echo ""
echo "📋 Verifica finale:"
head -8 "$FILE"
