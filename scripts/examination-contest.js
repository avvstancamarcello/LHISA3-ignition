const { readFileSync, existsSync } = require('fs');

console.log('🔍 ANALISI NUOVI ERRORI:\n');

// EnhancedModuleRouter - contesto riga 130
const enhancedPath = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
if (existsSync(enhancedPath)) {
    console.log('📖 EnhancedModuleRouter.sol (righe 125-135):');
    const content = readFileSync(enhancedPath, 'utf8').split('\n');
    for (let i = 124; i < 135 && i < content.length; i++) {
        console.log(`${i + 1}: ${content[i]}`);
    }
}

// MareaMangaNFT - fine file
const mareaPath = 'contracts/planetary/MareaMangaNFT.sol';
if (existsSync(mareaPath)) {
    console.log('\n📖 MareaMangaNFT.sol (ultime 10 righe):');
    const content = readFileSync(mareaPath, 'utf8').split('\n');
    const start = Math.max(0, content.length - 10);
    for (let i = start; i < content.length; i++) {
        console.log(`${i + 1}: ${content[i]}`);
    }
}

// LunaComicsFT - contesto riga 77
const lunaPath = 'contracts/satellites/LunaComicsFT.sol';
if (existsSync(lunaPath)) {
    console.log('\n📖 LunaComicsFT.sol (righe 72-80):');
    const content = readFileSync(lunaPath, 'utf8').split('\n');
    for (let i = 71; i < 80 && i < content.length; i++) {
        console.log(`${i + 1}: ${content[i]}`);
    }
}
