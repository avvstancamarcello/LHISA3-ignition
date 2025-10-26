const { readFileSync, existsSync } = require('fs');

console.log('🔍 DIAGNOSTICA ERRORI SPOSTATI:\n');

// EnhancedModuleRouter - diagnostica riga 289
const enhancedPath = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
if (existsSync(enhancedPath)) {
    console.log('📖 EnhancedModuleRouter.sol - RIGA 289:');
    const content = readFileSync(enhancedPath, 'utf8');
    const lines = content.split('\n');
    
    console.log('Contesto riga 289 (286-292):');
    for (let i = 285; i < 293 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Cosa c'è PRIMA?
    console.log('\nPrima di riga 289 (283-289):');
    for (let i = 282; i < 289 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
}

// LunaComicsFT - diagnostica riga 251 (stesso problema)
const lunaPath = 'contracts/satellites/LunaComicsFT.sol';
if (existsSync(lunaPath)) {
    console.log('\n📖 LunaComicsFT.sol - RIGA 251 (PERSISTENTE):');
    const content = readFileSync(lunaPath, 'utf8');
    const lines = content.split('\n');
    
    console.log('Contesto riga 251 (248-254):');
    for (let i = 247; i < 255 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Verifica parentesi specifiche
    console.log('\nParentesi specifiche attorno a riga 251:');
    for (let i = 245; i < 255; i++) {
        if (lines[i] && (lines[i].includes('{') || lines[i].includes('}'))) {
            console.log(`  ${i + 1}: "${lines[i]}"`);
        }
    }
}

console.log('\n💡 BASATO SU QUESTA DIAGNOSTICA, CREERO\' LO SCRIPT CORRETTO');

