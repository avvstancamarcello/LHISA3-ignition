#!/bin/bash

# 🌌 Header orbitale
SPDX='// SPDX-License-Identifier: MIT'
PRAGMA='pragma solidity ^0.8.26;'
COPYRIGHT='// © Copyright Marcello Stanca, lawyer in Florence, Italy'

# 🌠 Scansiona tutti i file .sol nella directory contracts/
find contracts/ -name "*.sol" | while read file; do
  echo "🔍 Controllo: $file"

  # Leggi le prime 5 righe
  R1=$(sed -n '1p' "$file")
  R2=$(sed -n '2p' "$file")
  R4=$(sed -n '4p' "$file")

  # Verifica presenza
  HAS_SPDX=$(echo "$R1" | grep -c "SPDX-License-Identifier")
  HAS_PRAGMA=$(echo "$R2" | grep -c "pragma solidity")
  HAS_COPYRIGHT=$(echo "$R4" | grep -c "Marcello Stanca")

  # Se almeno uno manca, ricostruisci il file
  if [ "$HAS_SPDX" -eq 0 ] || [ "$HAS_PRAGMA" -eq 0 ] || [ "$HAS_COPYRIGHT" -eq 0 ]; then
    echo "🛠️ Aggiungo header orbitale a: $file"

    # Costruisci header mancante
    HEADER=""
    [ "$HAS_SPDX" -eq 0 ] && HEADER+="$SPDX"$'\n'
    [ "$HAS_PRAGMA" -eq 0 ] && HEADER+="$PRAGMA"$'\n'
    [ "$HAS_COPYRIGHT" -eq 0 ] && HEADER+="$COPYRIGHT"$'\n'

    # Inserisci header sopra il contenuto esistente
    echo "$HEADER" | cat - "$file" > temp && mv temp "$file"
  else
    echo "✅ Header già presente in: $file"
  fi
done

echo "🌟 Tutti i file sono stati sincronizzati con l'intestazione orbitale."
