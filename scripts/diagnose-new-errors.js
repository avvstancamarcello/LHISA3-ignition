const { readFileSync, existsSync } = require('fs');

console.log('🔍 DIAGNOSTICA NUOVI ERRORI:\n');

// EnhancedModuleRouter - diagnostica riga 221
const enhancedPath = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
if (existsSync(enhancedPath)) {
    console.log('📖 EnhancedModuleRouter.sol - ANALISI RIGA 221:');
    const content = readFileSync(enhancedPath, 'utf8');
    const lines = content.split('\n');
    
    console.log('Riga 218-224:');
    for (let i = 217; i < 225 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Controlla il contesto prima della funzione
    console.log('\nContesto prima (riga 215-220):');
    for (let i = 214; i < 221 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
}

// LunaComicsFT - diagnostica riga 177 (dopo correzione)
const lunaPath = 'contracts/satellites/LunaComicsFT.sol';
if (existsSync(lunaPath)) {
    console.log('\n📖 LunaComicsFT.sol - ANALISI RIGA 177 (DOPO CORREZIONE):');
    const content = readFileSync(lunaPath, 'utf8');
    const lines = content.split('\n');
    
    console.log('Riga 174-180:');
    for (let i = 173; i < 181 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Controlla parentesi
    let openBraces = 0;
    let closeBraces = 0;
    for (let i = 0; i < lines.length; i++) {
        openBraces += (lines[i].match(/{/g) || []).length;
        closeBraces += (lines[i].match(/}/g) || []).length;
    }
    console.log(`\nParentesi totali: {=${openBraces} }=${closeBraces}`);
    
    // Cerca codice problematica prima della funzione
    console.log('\nCodice prima di riga 177:');
    for (let i = 170; i < 177 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
}

console.log('\n💡 BASATO SU QUESTA DIAGNOSTICA, CREERO\' LO SCRIPT CORRETTO');
