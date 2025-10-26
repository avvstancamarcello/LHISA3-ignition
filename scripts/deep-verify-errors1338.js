const { readFileSync, existsSync } = require('fs');

console.log('🔍 VERIFICA DETTAGLIATA ERRORI PERSISTENTI:\n');

// EnhancedModuleRouter - verifica completa del contesto
const enhancedPath = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
if (existsSync(enhancedPath)) {
    console.log('📖 EnhancedModuleRouter.sol - CONTESTO COMPLETO RIGA 295:');
    const content = readFileSync(enhancedPath, 'utf8');
    const lines = content.split('\n');
    
    // Trova la funzione che contiene la riga 295
    let functionStart = -1;
    for (let i = 280; i < 295; i++) {
        if (lines[i] && lines[i].includes('function ')) {
            functionStart = i;
            break;
        }
    }
    
    if (functionStart !== -1) {
        console.log(`Funzione trovata alla riga ${functionStart + 1}:`);
        console.log(`  "${lines[functionStart]}"`);
        
        // Mostra il contenuto completo della funzione
        console.log('\nContenuto completo della funzione:');
        let braceCount = 0;
        for (let i = functionStart; i < Math.min(functionStart + 20, lines.length); i++) {
            console.log(`  ${i + 1}: "${lines[i]}"`);
            if (lines[i].includes('{')) braceCount++;
            if (lines[i].includes('}')) braceCount--;
            if (braceCount === 0 && i > functionStart) break;
        }
    }
    
    // Verifica specifica cosa c'è alla riga 294 (prima della 295)
    console.log('\n🔍 ANALISI RIGA 294 (prima del problema):');
    console.log(`  294: "${lines[293]}"`);
    console.log(`  295: "${lines[294]}"`);
    console.log(`  296: "${lines[295]}"`);
}

// LunaComicsFT - verifica completa del contesto
const lunaPath = 'contracts/satellites/LunaComicsFT.sol';
if (existsSync(lunaPath)) {
    console.log('\n📖 LunaComicsFT.sol - CONTESTO COMPLETO RIGA 251:');
    const content = readFileSync(lunaPath, 'utf8');
    const lines = content.split('\n');
    
    // Verifica cosa c'è IMMEDIATAMENTE prima della riga 251
    console.log('Contesto immediatamente prima (righe 245-251):');
    for (let i = 244; i < 251 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Controlla parentesi specifiche
    let localOpen = 0;
    let localClose = 0;
    for (let i = 240; i < 251; i++) {
        if (lines[i]) {
            localOpen += (lines[i].match(/{/g) || []).length;
            localClose += (lines[i].match(/}/g) || []).length;
        }
    }
    console.log(`\nParentesi locali (righe 241-251): {=${localOpen} }=${localClose}`);
    
    // Verifica se la funzione è dentro il contratto
    let contractBraces = 0;
    for (let i = 0; i < 251; i++) {
        if (lines[i] && lines[i].includes('contract ') && contractBraces === 0) {
            contractBraces++;
        } else if (contractBraces > 0) {
            if (lines[i].includes('{')) contractBraces++;
            if (lines[i].includes('}')) contractBraces--;
        }
    }
    console.log(`Contratto aperto alla riga 251: ${contractBraces > 0 ? 'SI' : 'NO'}`);
}

console.log('\n💡 ORA CREERO\' LO SCRIPT CORRETTO BASATO SU QUESTA VERIFICA');
