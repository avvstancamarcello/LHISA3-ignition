const { readFileSync, existsSync } = require('fs');

console.log('🔍 DIAGNOSTICA NUOVI ERRORI:\n');

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
    
    // Cerca cosa c'è PRIMA
    console.log('\nPrima di riga 295 (290-295):');
    for (let i = 289; i < 295 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
}

// LunaComicsFT - diagnostica riga 234
const lunaPath = 'contracts/satellites/LunaComicsFT.sol';
if (existsSync(lunaPath)) {
    console.log('\n📖 LunaComicsFT.sol - RIGA 234:');
    const content = readFileSync(lunaPath, 'utf8');
    const lines = content.split('\n');
    
    console.log('Contesto riga 234 (231-237):');
    for (let i = 230; i < 238 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Cosa c'è PRIMA
    console.log('\nPrima di riga 234 (229-234):');
    for (let i = 228; i < 234 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
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
