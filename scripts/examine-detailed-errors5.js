const { readFileSync, existsSync } = require('fs');

console.log('🔍 ANALISI DETTAGLIATA ERRORI:\n');

// EnhancedModuleRouter - contesto completo della funzione
const enhancedPath = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
if (existsSync(enhancedPath)) {
    console.log('📖 EnhancedModuleRouter.sol (righe 200-220 - CONTESTO COMPLETO):');
    const content = readFileSync(enhancedPath, 'utf8').split('\n');
    for (let i = 199; i < 220 && i < content.length; i++) {
        console.log(`${i + 1}: ${content[i]}`);
    }
}

// LunaComicsFT - verifica dopo la correzione
const lunaPath = 'contracts/satellites/LunaComicsFT.sol';
if (existsSync(lunaPath)) {
    console.log('\n📖 LunaComicsFT.sol (dopo correzione - ultime 5 righe):');
    const content = readFileSync(lunaPath, 'utf8').split('\n');
    const start = Math.max(0, content.length - 5);
    for (let i = start; i < content.length; i++) {
        console.log(`${i + 1}: ${content[i]}`);
    }
    
    // Conta parentesi finali
    let openBraces = 0;
    let closeBraces = 0;
    for (let i = 0; i < content.length; i++) {
        openBraces += (content[i].match(/{/g) || []).length;
        closeBraces += (content[i].match(/}/g) || []).length;
    }
    console.log(`\nParentesi finali: {=${openBraces} }=${closeBraces}`);
}
