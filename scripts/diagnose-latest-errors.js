const { readFileSync, existsSync } = require('fs');

console.log('🔍 DIAGNOSTICA ULTIMI ERRORI:\n');

// EnhancedModuleRouter - diagnostica riga 269
const enhancedPath = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
if (existsSync(enhancedPath)) {
    console.log('📖 EnhancedModuleRouter.sol - RIGA 269:');
    const content = readFileSync(enhancedPath, 'utf8');
    const lines = content.split('\n');
    
    console.log('Contesto riga 269 (266-272):');
    for (let i = 265; i < 273 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Cosa c'è PRIMA e DOPO?
    console.log('\nContesto completo (264-275):');
    for (let i = 263; i < 276 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
}

// LunaComicsFT - diagnostica riga 251 (stesso problema persistente)
const lunaPath = 'contracts/satellites/LunaComicsFT.sol';
if (existsSync(lunaPath)) {
    console.log('\n📖 LunaComicsFT.sol - RIGA 251 (PERSISTENTE):');
    const content = readFileSync(lunaPath, 'utf8');
    const lines = content.split('\n');
    
    console.log('Contesto riga 251 (248-254):');
    for (let i = 247; i < 255 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Verifica se il contratto è aperto
    let contractBraces = 0;
    for (let i = 0; i < 251; i++) {
        if (lines[i].includes('contract ') && contractBraces === 0) {
            contractBraces++;
        } else if (contractBraces > 0) {
            if (lines[i].includes('{')) contractBraces++;
            if (lines[i].includes('}')) contractBraces--;
        }
    }
    console.log(`\nContratto aperto alla riga 251: ${contractBraces > 0 ? 'SI' : 'NO'}`);
    console.log(`Bilancio parentesi: ${contractBraces}`);
}

console.log('\n💡 BASATO SU QUESTA DIAGNOSTICA, CREERO\' LO SCRIPT CORRETTO');
