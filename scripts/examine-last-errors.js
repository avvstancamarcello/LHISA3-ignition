const { readFileSync, existsSync } = require('fs');

console.log('🔍 ANALISI ULTIMI ERRORI:\n');

// EnhancedModuleRouter - contesto riga 167
const enhancedPath = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
if (existsSync(enhancedPath)) {
    console.log('📖 EnhancedModuleRouter.sol (righe 160-170):');
    const content = readFileSync(enhancedPath, 'utf8').split('\n');
    for (let i = 159; i < 170 && i < content.length; i++) {
        console.log(`${i + 1}: ${content[i]}`);
    }
}

// LunaComicsFT - contesto riga 78
const lunaPath = 'contracts/satellites/LunaComicsFT.sol';
if (existsSync(lunaPath)) {
    console.log('\n📖 LunaComicsFT.sol (righe 73-82):');
    const content = readFileSync(lunaPath, 'utf8').split('\n');
    for (let i = 72; i < 82 && i < content.length; i++) {
        console.log(`${i + 1}: ${content[i]}`);
    }
}
