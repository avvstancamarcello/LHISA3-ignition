const { readFileSync, existsSync } = require('fs');

console.log('🔍 ANALISI RIGHE PROBLEMATICHE:\n');

// EnhancedModuleRouter.sol - righe 70-80
const enhancedPath = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
if (existsSync(enhancedPath)) {
    console.log('📖 EnhancedModuleRouter.sol (righe 70-80):');
    const content = readFileSync(enhancedPath, 'utf8').split('\n');
    for (let i = 69; i < 80 && i < content.length; i++) {
        console.log(`${i + 1}: ${content[i]}`);
    }
    console.log('');
}

// MareaMangaNFT.sol - righe 180-190  
const mareaPath = 'contracts/planetary/MareaMangaNFT.sol';
if (existsSync(mareaPath)) {
    console.log('📖 MareaMangaNFT.sol (righe 180-190):');
    const content = readFileSync(mareaPath, 'utf8').split('\n');
    for (let i = 179; i < 190 && i < content.length; i++) {
        console.log(`${i + 1}: ${content[i]}`);
    }
    console.log('');
}

// LunaComicsFT.sol - righe 55-65
const lunaPath = 'contracts/satellites/LunaComicsFT.sol';
if (existsSync(lunaPath)) {
    console.log('📖 LunaComicsFT.sol (righe 55-65):');
    const content = readFileSync(lunaPath, 'utf8').split('\n');
    for (let i = 54; i < 65 && i < content.length; i++) {
        console.log(`${i + 1}: ${content[i]}`);
    }
}
