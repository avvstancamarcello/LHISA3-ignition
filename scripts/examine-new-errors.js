const { readFileSync, existsSync } = require('fs');

console.log('🔍 ANALISI NUOVI ERRORI:\n');

// EnhancedModuleRouter - contesto riga 183
const enhancedPath = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
if (existsSync(enhancedPath)) {
    console.log('📖 EnhancedModuleRouter.sol (righe 178-188):');
    const content = readFileSync(enhancedPath, 'utf8').split('\n');
    for (let i = 177; i < 188 && i < content.length; i++) {
        console.log(`${i + 1}: ${content[i]}`);
    }
}

// LunaComicsFT - contesto riga 104
const lunaPath = 'contracts/satellites/LunaComicsFT.sol';
if (existsSync(lunaPath)) {
    console.log('\n📖 LunaComicsFT.sol (righe 99-109):');
    const content = readFileSync(lunaPath, 'utf8').split('\n');
    for (let i = 98; i < 109 && i < content.length; i++) {
        console.log(`${i + 1}: ${content[i]}`);
    }
}
