const { readFileSync, existsSync } = require('fs');

console.log('🔍 INVESTIGAZIONE PROFONDA ERRORI PERSISTENTI:\n');

// EnhancedModuleRouter - investiga riga 248 specifica
const enhancedPath = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
if (existsSync(enhancedPath)) {
    console.log('📖 EnhancedModuleRouter.sol - RIGA 248 SPECIFICA:');
    const content = readFileSync(enhancedPath, 'utf8');
    const lines = content.split('\n');
    
    console.log('Contesto riga 248 (245-251):');
    for (let i = 244; i < 252 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Cerca cosa c'è DOPO la riga 248
    console.log('\nDopo riga 248 (249-255):');
    for (let i = 248; i < 256 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Controlla se ci sono parentesi extra alla fine
    console.log('\nUltime 5 righe del file:');
    const start = Math.max(0, lines.length - 5);
    for (let i = start; i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Conta parentesi precise
    let openBraces = 0;
    let closeBraces = 0;
    for (let i = 0; i < lines.length; i++) {
        openBraces += (lines[i].match(/{/g) || []).length;
        closeBraces += (lines[i].match(/}/g) || []).length;
    }
    console.log(`\nParentesi precise: {=${openBraces} }=${closeBraces}`);
}

// LunaComicsFT - investiga riga 225 specifica
const lunaPath = 'contracts/satellites/LunaComicsFT.sol';
if (existsSync(lunaPath)) {
    console.log('\n📖 LunaComicsFT.sol - RIGA 225 SPECIFICA:');
    const content = readFileSync(lunaPath, 'utf8');
    const lines = content.split('\n');
    
    console.log('Contesto riga 225 (222-228):');
    for (let i = 221; i < 229 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Cerca cosa c'è DOPO la riga 225
    console.log('\nDopo riga 225 (226-232):');
    for (let i = 225; i < 233 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Controlla se ci sono parentesi extra alla fine
    console.log('\nUltime 5 righe del file:');
    const start = Math.max(0, lines.length - 5);
    for (let i = start; i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Conta parentesi precise
    let openBraces = 0;
    let closeBraces = 0;
    for (let i = 0; i < lines.length; i++) {
        openBraces += (lines[i].match(/{/g) || []).length;
        closeBraces += (lines[i].match(/}/g) || []).length;
    }
    console.log(`\nParentesi precise: {=${openBraces} }=${closeBraces}`);
}

console.log('\n💡 ORA VEDRO\' ESATTAMENTE DOVE SONO LE PARENTESI EXTRA');
