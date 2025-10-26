#!/bin/bash

echo "🔍 ANALISI FILE App.js vs app.js"
echo "================================"

APP_JS_PATH="$HOME/MyHardhatProjects/LHISA3-ignition/LuccaComixMobile/LuccaComixSolidary/App.js"
APP_JS_LOWERCASE_PATH="$HOME/MyHardhatProjects/LHISA3-ignition/LuccaComixMobile/LuccaComixSolidary/app.js"

# Colori
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "📁 STATO FILE:"
echo "-------------"

if [ -f "$APP_JS_PATH" ]; then
    echo -e "${GREEN}✅ App.js ESISTE${NC}"
    echo -e "   Dimensione: $(wc -c < "$APP_JS_PATH") bytes"
    echo -e "   Linee: $(wc -l < "$APP_JS_PATH")"
else
    echo -e "${RED}❌ App.js NON ESISTE${NC}"
fi

if [ -f "$APP_JS_LOWERCASE_PATH" ]; then
    echo -e "${YELLOW}⚠️  app.js (minuscolo) ESISTE${NC}"
    echo -e "   Dimensione: $(wc -c < "$APP_JS_LOWERCASE_PATH") bytes"
    echo -e "   Linee: $(wc -l < "$APP_JS_LOWERCASE_PATH")"
else
    echo -e "${GREEN}✅ app.js (minuscolo) NON ESISTE${NC}"
fi

echo ""
echo "📄 CONTENUTO App.js (prime 20 linee):"
echo "-----------------------------------"
if [ -f "$APP_JS_PATH" ]; then
    head -20 "$APP_JS_PATH"
else
    echo -e "${RED}File non trovato${NC}"
fi

echo ""
echo "📄 CONTENUTO app.js (prime 20 linee):"
echo "-----------------------------------"
if [ -f "$APP_JS_LOWERCASE_PATH" ]; then
    head -20 "$APP_JS_LOWERCASE_PATH"
else
    echo -e "${GREEN}File non trovato${NC}"
fi

echo ""
echo "🔧 CONSIGLIO INTEGRAZIONE:"
echo "-------------------------"

if [ -f "$APP_JS_PATH" ] && [ ! -f "$APP_JS_LOWERCASE_PATH" ]; then
    echo -e "${GREEN}✅ USA App.js (maiuscolo) per l'integrazione${NC}"
elif [ ! -f "$APP_JS_PATH" ] && [ -f "$APP_JS_LOWERCASE_PATH" ]; then
    echo -e "${YELLOW}⚠️  RINOMINA app.js in App.js${NC}"
    echo "   mv \"$APP_JS_LOWERCASE_PATH\" \"$APP_JS_PATH\""
elif [ -f "$APP_JS_PATH" ] && [ -f "$APP_JS_LOWERCASE_PATH" ]; then
    echo -e "${RED}❌ CONFLITTO: Entrambi i file esistono${NC}"
    echo "   Decidi quale mantenere:"
    echo "   - App.js: $(wc -l < "$APP_JS_PATH") linee"
    echo "   - app.js: $(wc -l < "$APP_JS_LOWERCASE_PATH") linee"
else
    echo -e "${RED}❌ NESSUN FILE TROVATO - Crea App.js${NC}"
fi

