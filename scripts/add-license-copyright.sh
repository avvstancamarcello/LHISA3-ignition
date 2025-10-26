#!/bin/bash

echo "📄 Aggiunta SPDX e Copyright a SolidaryComix.sol..."

# Crea backup
cp contracts/creative_cultural/SolidaryComix.sol contracts/creative_cultural/SolidaryComix.sol.backup

# Aggiungi header con SPDX e Copyright
cat > contracts/creative_cultural/SolidaryComix.sol.new << 'HEADER'
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

// Copyright © 2025 Avv. Marcello Stanca - Firenze, Italia. All Rights Reserved.
// Hoc contractum, pars Systematis Solidarii, ab Auctore Marcello Stanca 
// Caritati Internationalis (MCMLXXVI) gratis conceditur.
// (This smart contract, part of the Solidary System, is granted for free use 
// to Caritas Internationalis (1976) by the author, Marcello Stanca.)

HEADER

# Aggiungi il contenuto originale (escludendo eventuali header esistenti)
tail -n +3 contracts/creative_cultural/SolidaryComix.sol >> contracts/creative_cultural/SolidaryComix.sol.new

# Sostituisci il file originale
mv contracts/creative_cultural/SolidaryComix.sol.new contracts/creative_cultural/SolidaryComix.sol

echo "✅ SPDX e Copyright aggiunti!"
echo "📋 Verifica prime 10 righe:"
head -10 contracts/creative_cultural/SolidaryComix.sol
