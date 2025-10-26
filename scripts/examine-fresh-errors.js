const { readFileSync, existsSync } = require('fs');

console.log('🔍 ANALISI NUOVISSIMI ERRORI:\n');

// EnhancedModuleRouter - contesto riga 215 (dopo la correzione)
const enhancedPath = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
if (existsSync(enhancedPath)) {
    console.log('📖 EnhancedModuleRouter.sol (righe 210-220 - DOPO correzione):');
    const content = readFileSync(enhancedPath, 'utf8').split('\n');
    for (let i = 209; i < 220 && i < content.length; i++) {
        console.log(`${i + 1}: ${content[i]}`);
    }
}

// LunaComicsFT - contesto riga 177
const lunaPath = 'contracts/satellites/LunaComicsFT.sol';
if (existsSync(lunaPath)) {
    console.log('\n📖 LunaComicsFT.sol (righe 172-182):');
    const content = readFileSync(lunaPath, 'utf8').split('\n');
    for (let i = 171; i < 182 && i < content.length; i++) {
        console.log(`${i + 1}: ${content[i]}`);
    }
}
