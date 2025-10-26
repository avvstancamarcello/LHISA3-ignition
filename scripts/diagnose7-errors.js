const { readFileSync, existsSync } = require('fs');

console.log('🔍 DIAGNOSTICA ERRORI CORRENTI:\n');

// EnhancedModuleRouter - diagnostica dettagliata
const enhancedPath = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
if (existsSync(enhancedPath)) {
    console.log('📖 EnhancedModuleRouter.sol - ANALISI RIGA 215:');
    const content = readFileSync(enhancedPath, 'utf8');
    const lines = content.split('\n');
    
    console.log('Riga 213-217:');
    for (let i = 212; i < 218 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Cerca encodeWithSignature
    let encodeLine = -1;
    for (let i = 0; i < lines.length; i++) {
        if (lines[i].includes('encodeWithSignature')) {
            encodeLine = i;
            console.log(`\nencodeWithSignature trovato alla riga ${i + 1}: "${lines[i]}"`);
        }
    }
    
    // Controlla se encodeWithSignature è chiuso
    if (encodeLine !== -1) {
        let parenCount = 0;
        let closed = false;
        for (let i = encodeLine; i < Math.min(encodeLine + 10, lines.length); i++) {
            if (lines[i].includes('(')) parenCount++;
            if (lines[i].includes(')')) parenCount--;
            if (parenCount === 0 && i > encodeLine) {
                closed = true;
                console.log(`encodeWithSignature chiuso alla riga ${i + 1}`);
                break;
            }
        }
        if (!closed) {
            console.log('❌ encodeWithSignature NON chiuso!');
        }
    }
}

// LunaComicsFT - diagnostica dettagliata
const lunaPath = 'contracts/satellites/LunaComicsFT.sol';
if (existsSync(lunaPath)) {
    console.log('\n📖 LunaComicsFT.sol - ANALISI RIGA 177:');
    const content = readFileSync(lunaPath, 'utf8');
    const lines = content.split('\n');
    
    console.log('Riga 175-180:');
    for (let i = 174; i < 181 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Cerca la funzione problematica
    for (let i = 0; i < lines.length; i++) {
        if (lines[i].includes('userFarmsArray.pop()')) {
            console.log(`\nuserFarmsArray.pop() trovato alla riga ${i + 1}: "${lines[i]}"`);
        }
    }
    
    // Conta parentesi
    let openBraces = 0;
    let closeBraces = 0;
    for (let i = 0; i < lines.length; i++) {
        openBraces += (lines[i].match(/{/g) || []).length;
        closeBraces += (lines[i].match(/}/g) || []).length;
    }
    console.log(`\nParentesi totali: {=${openBraces} }=${closeBraces}`);
}

console.log('\n💡 BASATO SU QUESTA DIAGNOSTICA, CREERO\' LO SCRIPT CORRETTO');
