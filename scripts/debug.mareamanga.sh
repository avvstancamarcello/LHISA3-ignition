#!/bin/bash
echo "=== 🔍 DEBUG AUTOMATICO MAREAMANGANFT ==="

echo ""
echo "1. 📋 FUNZIONI pure TROVATE:"
grep -n "function.*pure" contracts/planetary/MareaMangaNFT.sol

echo ""
echo "2. 🎯 _uintToString(block.timestamp) TROVATO:"
grep -n "_uintToString(block.timestamp)" contracts/planetary/MareaMangaNFT.sol

echo ""
echo "3. 🔍 CONTROLLO FUNZIONI pure PER block.timestamp:"
sed -n '/function.*pure/,/^[[:space:]]*}[[:space:]]*$/{
    /block\.timestamp/{
        =;
        p;
    }
}' contracts/planetary/MareaMangaNFT.sol

echo ""
echo "=== ✅ ANALISI COMPLETATA ==="
