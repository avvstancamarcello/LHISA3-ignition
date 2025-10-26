#!/bin/bash

echo "🔍 VERIFICA INTEGRAZIONE APP MOBILE"
echo "===================================="

# Colori per output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funzione di verifica
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅ OK${NC}: $1"
        return 0
    else
        echo -e "${RED}❌ MISSING${NC}: $1"
        return 1
    fi
}

# Funzione verifica contenuto
check_content() {
    if [ -f "$1" ] && grep -q "$2" "$1"; then
        echo -e "${GREEN}✅ CONTENT OK${NC}: $2 in $1"
        return 0
    else
        echo -e "${RED}❌ CONTENT MISSING${NC}: $2 in $1"
        return 1
    fi
}

echo ""
echo "📁 VERIFICA FILE CREATI:"
echo "------------------------"

# File da verificare
BASE_PATH="$HOME/MyHardhatProjects/LHISA3-ignition/LuccaComixMobile/LuccaComixSolidary"

files=(
    "$BASE_PATH/constants/contracts.js"
    "$BASE_PATH/utils/web3Service.js" 
    "$BASE_PATH/hooks/useWeb3.js"
    "$BASE_PATH/components/WalletConnect.js"
)

all_ok=true
for file in "${files[@]}"; do
    if ! check_file "$file"; then
        all_ok=false
    fi
done

echo ""
echo "🔧 VERIFICA CONTENUTI:"
echo "---------------------"

# Verifica contenuti chiave
if check_file "$BASE_PATH/constants/contracts.js"; then
    check_content "$BASE_PATH/constants/contracts.js" "0x4879570a9268a94BCcb8731ecb95E39bdb5EBC0C"
    check_content "$BASE_PATH/constants/contracts.js" "BASE_MAINNET"
fi

if check_file "$BASE_PATH/utils/web3Service.js"; then
    check_content "$BASE_PATH/utils/web3Service.js" "connectWallet"
    check_content "$BASE_PATH/utils/web3Service.js" "mintPhotoNFT"
fi

if check_file "$BASE_PATH/hooks/useWeb3.js"; then
    check_content "$BASE_PATH/hooks/useWeb3.js" "useWeb3"
    check_content "$BASE_PATH/hooks/useWeb3.js" "useEffect"
fi

if check_file "$BASE_PATH/components/WalletConnect.js"; then
    check_content "$BASE_PATH/components/WalletConnect.js" "WalletConnect"
    check_content "$BASE_PATH/components/WalletConnect.js" "formatAddress"
fi

echo ""
echo "📊 STATISTICHE FILE:"
echo "-------------------"

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        size=$(wc -c < "$file")
        lines=$(wc -l < "$file")
        echo -e "${YELLOW}📄 $(basename $file)${NC}: ${lines} linee, ${size} bytes"
    fi
done

echo ""
if [ "$all_ok" = true ]; then
    echo -e "${GREEN}🎉 TUTTI I FILE SONO STATI CREATI CORRETTAMENTE!${NC}"
    echo "🚀 L'integrazione è pronta per il testing!"
else
    echo -e "${RED}⚠️  ALcuni file mancano. Controlla i path e riesegui i comandi.${NC}"
fi

echo ""
echo "📍 PER TESTARE:"
echo "1. Aggiungi WalletConnect al tuo App.js"
echo "2. Avvia l'app: cd $BASE_PATH && npm start"
echo "3. Testa la connessione wallet su mobile"

