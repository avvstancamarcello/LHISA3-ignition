const { readFileSync, existsSync } = require('fs');

console.log('🔍 DIAGNOSTICA ULTIMI ERRORI:\n');

// EnhancedModuleRouter - diagnostica riga 240
const enhancedPath = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
if (existsSync(enhancedPath)) {
    console.log('📖 EnhancedModuleRouter.sol - ANALISI RIGA 240:');
    const content = readFileSync(enhancedPath, 'utf8');
    const lines = content.split('\n');
    
    console.log('Riga 237-243:');
    for (let i = 236; i < 244 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Controlla il contesto - probabilmente un operatore ternario malformato
    console.log('\nContesto completo (riga 235-245):');
    for (let i = 234; i < 246 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
}

// LunaComicsFT - diagnostica riga 177 (problema persistente)
const lunaPath = 'contracts/satellites/LunaComicsFT.sol';
if (existsSync(lunaPath)) {
    console.log('\n📖 LunaComicsFT.sol - ANALISI RIGA 177 (PROBLEMA PERSISTENTE):');
    const content = readFileSync(lunaPath, 'utf8');
    const lines = content.split('\n');
    
    console.log('Riga 174-180 (DOPO TUTTE LE CORREZIONI):');
    for (let i = 173; i < 181 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Controlla parentesi specifiche per questa sezione
    let localOpen = 0;
    let localClose = 0;
    for (let i = 170; i < 177; i++) {
        if (lines[i]) {
            localOpen += (lines[i].match(/{/g) || []).length;
            localClose += (lines[i].match(/}/g) || []).length;
        }
    }
    console.log(`\nParentesi locali (righe 171-177): {=${localOpen} }=${localClose}`);
    
    // Cosa c'è IMMEDIATAMENTE prima della riga 177?
    console.log('\nRiga immediatamente prima (176):', lines[175] ? `"${lines[175]}"` : 'NON TROVATA');
}

console.log('\n💡 BASATO SU QUESTA DIAGNOSTICA, CREERO\' LO SCRIPT CORRETTO');

