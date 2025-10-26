#!/bin/bash

# Directory di origine e destinazione
SOURCE_DIR="./contracts"
DEST_DIR="./contracts_attive"
LOG_FILE="log.txt"

# Crea la directory di destinazione se non esiste
mkdir -p "$DEST_DIR"

# Pulisce il log precedente
> "$LOG_FILE"

# Trova e copia i file .sol modificati nelle ultime 24 ore
find "$SOURCE_DIR" -type f -name "*.sol" -mtime -1 | while read -r file; do
    # Costruisce il percorso di destinazione mantenendo la struttura
    rel_path="${file#$SOURCE_DIR/}"
    dest_path="$DEST_DIR/$rel_path"
    mkdir -p "$(dirname "$dest_path")"
    cp -v "$file" "$dest_path" | tee -a "$LOG_FILE"
done

echo -e "\n✅ Copia completata. File registrati in $LOG_FILE"
