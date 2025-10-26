const { readFileSync, existsSync } = require('fs');

console.log('🔍 DIAGNOSTICA ERRORI NUOVI:\n');

// EnhancedModuleRouter - diagnostica riga 295
const enhancedPath = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
if (existsSync(enhancedPath)) {
    console.log('📖 EnhancedModuleRouter.sol - RIGA 295:');
    const content = readFileSync(enhancedPath, 'utf8');
    const lines = content.split('\n');
    
    console.log('Contesto riga 295 (292-298):');
    for (let i = 291; i < 299 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Cerca cosa c'è PRIMA per capire il contesto
    console.log('\nPrima di riga 295 (289-295):');
    for (let i = 288; i < 295 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
}

// LunaComicsFT - diagnostica riga 251
const lunaPath = 'contracts/satellites/LunaComicsFT.sol';
if (existsSync(lunaPath)) {
    console.log('\n📖 LunaComicsFT.sol - RIGA 251:');
    const content = readFileSync(lunaPath, 'utf8');
    const lines = content.split('\n');
    
    console.log('Contesto riga 251 (248-254):');
    for (let i = 247; i < 255 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Cosa c'è PRIMA della funzione
    console.log('\nPrima di riga 251 (246-251):');
    for (let i = 245; i < 251 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
}

console.log('\n💡 BASATO SU QUESTA DIAGNOSTICA, CREERO\' LO SCRIPT CORRETTO');
