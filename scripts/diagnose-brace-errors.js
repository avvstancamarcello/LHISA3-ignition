const { readFileSync, existsSync } = require('fs');

console.log('🔍 DIAGNOSTICA PARENTESI EXTRA:\n');

// EnhancedModuleRouter - diagnostica fine file
const enhancedPath = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
if (existsSync(enhancedPath)) {
    console.log('📖 EnhancedModuleRouter.sol - FINE FILE:');
    const content = readFileSync(enhancedPath, 'utf8');
    const lines = content.split('\n');
    
    console.log('Ultime 10 righe:');
    const start = Math.max(0, lines.length - 10);
    for (let i = start; i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Conta parentesi totali
    let openBraces = 0;
    let closeBraces = 0;
    for (let i = 0; i < lines.length; i++) {
        openBraces += (lines[i].match(/{/g) || []).length;
        closeBraces += (lines[i].match(/}/g) || []).length;
    }
    console.log(`\nParentesi totali: {=${openBraces} }=${closeBraces}`);
    
    // Trova l'ultima parentesi
    let lastBraceIndex = -1;
    for (let i = lines.length - 1; i >= 0; i--) {
        if (lines[i].trim() === '}') {
            lastBraceIndex = i;
            console.log(`\nUltima parentesi } alla riga: ${lastBraceIndex + 1}`);
            break;
        }
    }
}

// LunaComicsFT - diagnostica fine file
const lunaPath = 'contracts/satellites/LunaComicsFT.sol';
if (existsSync(lunaPath)) {
    console.log('\n📖 LunaComicsFT.sol - FINE FILE:');
    const content = readFileSync(lunaPath, 'utf8');
    const lines = content.split('\n');
    
    console.log('Ultime 10 righe:');
    const start = Math.max(0, lines.length - 10);
    for (let i = start; i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Conta parentesi totali
    let openBraces = 0;
    let closeBraces = 0;
    for (let i = 0; i < lines.length; i++) {
        openBraces += (lines[i].match(/{/g) || []).length;
        closeBraces += (lines[i].match(/}/g) || []).length;
    }
    console.log(`\nParentesi totali: {=${openBraces} }=${closeBraces}`);
    
    // Trova l'ultima parentesi
    let lastBraceIndex = -1;
    for (let i = lines.length - 1; i >= 0; i--) {
        if (lines[i].trim() === '}') {
            lastBraceIndex = i;
            console.log(`\nUltima parentesi } alla riga: ${lastBraceIndex + 1}`);
            break;
        }
    }
}

console.log('\n💡 BASATO SU QUESTA DIAGNOSTICA, RIMUOVERO\' LE PARENTESI EXTRA');
