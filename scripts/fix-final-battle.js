const { readFileSync, existsSync } = require('fs');

console.log('🔍 ANALISI COMPLETA CONTESTO ERRORI:\n');

// EnhancedModuleRouter - contesto struct
const enhancedPath = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
if (existsSync(enhancedPath)) {
    console.log('📖 EnhancedModuleRouter.sol (righe 90-105):');
    const content = readFileSync(enhancedPath, 'utf8').split('\n');
    for (let i = 89; i < 105 && i < content.length; i++) {
        console.log(`${i + 1}: ${content[i]}`);
    }
}

// MareaMangaNFT - contesto mapping  
const mareaPath = 'contracts/planetary/MareaMangaNFT.sol';
if (existsSync(mareaPath)) {
    console.log('\n📖 MareaMangaNFT.sol (righe 565-575):');
    const content = readFileSync(mareaPath, 'utf8').split('\n');
    for (let i = 564; i < 575 && i < content.length; i++) {
        console.log(`${i + 1}: ${content[i]}`);
    }
}

// LunaComicsFT - contesto assegnazione
const lunaPath = 'contracts/satellites/LunaComicsFT.sol';
if (existsSync(lunaPath)) {
    console.log('\n📖 LunaComicsFT.sol (righe 68-75):');
    const content = readFileSync(lunaPath, 'utf8').split('\n');
    for (let i = 67; i < 75 && i < content.length; i++) {
        console.log(`${i + 1}: ${content[i]}`);
    }
}
