const { readFileSync, existsSync } = require('fs');

console.log('🔍 DIAGNOSTICA NUOVI ERRORI:\n');

// EnhancedModuleRouter - diagnostica riga 277
const enhancedPath = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
if (existsSync(enhancedPath)) {
    console.log('📖 EnhancedModuleRouter.sol - RIGA 277:');
    const content = readFileSync(enhancedPath, 'utf8');
    const lines = content.split('\n');
    
    console.log('Contesto riga 277 (274-280):');
    for (let i = 273; i < 281 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Cosa c'è PRIMA della riga 277?
    console.log('\nPrima di riga 277 (270-277):');
    for (let i = 269; i < 277 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
}

// LunaComicsFT - diagnostica riga 251 (stesso problema persistente)
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
    let braceCount = 0;
    for (let i = 0; i < 251; i++) {
        if (lines[i].includes('{')) braceCount++;
        if (lines[i].includes('}')) braceCount--;
    }
    console.log(`\nParentesi fino a riga 251: ${braceCount > 0 ? 'APERTE' : 'CHIUSE'}`);
}

console.log('\n💡 BASATO SU QUESTA DIAGNOSTICA, CREERO\' LO SCRIPT CORRETTO');
