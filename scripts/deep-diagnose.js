const { readFileSync, existsSync } = require('fs');

console.log('🔍 DIAGNOSTICA PROFONDA - COSA C\'E\' REALMENTE NEI FILE?\n');

// EnhancedModuleRouter - diagnostica completa della sezione problematica
const enhancedPath = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
if (existsSync(enhancedPath)) {
    console.log('📖 EnhancedModuleRouter.sol - SEZIONE COMPLETA _updateRouteStats:');
    const content = readFileSync(enhancedPath, 'utf8');
    const lines = content.split('\n');
    
    // Trova la funzione _updateRouteStats
    let functionStart = -1;
    for (let i = 0; i < lines.length; i++) {
        if (lines[i] && lines[i].includes('function _updateRouteStats')) {
            functionStart = i;
            break;
        }
    }
    
    if (functionStart !== -1) {
        console.log(`Funzione _updateRouteStats trovata alla riga ${functionStart + 1}`);
        console.log('Contenuto della funzione:');
        for (let i = functionStart; i < Math.min(functionStart + 15, lines.length); i++) {
            console.log(`  ${i + 1}: "${lines[i]}"`);
        }
    } else {
        console.log('❌ Funzione _updateRouteStats NON TROVATA');
    }
    
    // Cerca specificamente la riga 240
    console.log('\n🔍 RIGA 240 SPECIFICA:');
    if (lines[239]) {
        console.log(`  Riga 240: "${lines[239]}"`);
    } else {
        console.log('  Riga 240: NON ESISTE');
    }
}

// LunaComicsFT - diagnostica completa della sezione _removeFarm
const lunaPath = 'contracts/satellites/LunaComicsFT.sol';
if (existsSync(lunaPath)) {
    console.log('\n📖 LunaComicsFT.sol - SEZIONE COMPLETA _removeFarm:');
    const content = readFileSync(lunaPath, 'utf8');
    const lines = content.split('\n');
    
    // Trova la funzione _removeFarm
    let functionStart = -1;
    for (let i = 0; i < lines.length; i++) {
        if (lines[i] && lines[i].includes('function _removeFarm')) {
            functionStart = i;
            break;
        }
    }
    
    if (functionStart !== -1) {
        console.log(`Funzione _removeFarm trovata alla riga ${functionStart + 1}`);
        console.log('Contenuto della funzione:');
        let braceCount = 0;
        for (let i = functionStart; i < Math.min(functionStart + 10, lines.length); i++) {
            console.log(`  ${i + 1}: "${lines[i]}"`);
            if (lines[i].includes('{')) braceCount++;
            if (lines[i].includes('}')) braceCount--;
            if (braceCount === 0 && i > functionStart) break;
        }
        
        console.log(`\nParentesi nella funzione: {=${braceCount > 0 ? 'PIU' : 'MENO'} }`);
    } else {
        console.log('❌ Funzione _removeFarm NON TROVATA');
    }
    
    // Cerca specificamente cosa c'è alla riga 177
    console.log('\n🔍 RIGA 177 SPECIFICA:');
    if (lines[176]) {
        console.log(`  Riga 177: "${lines[176]}"`);
        console.log(`  Riga 176 (prima): "${lines[175]}"`);
        console.log(`  Riga 178 (dopo): "${lines[177]}"`);
    } else {
        console.log('  Riga 177: NON ESISTE');
    }
}

console.log('\n💡 ORA CREERO\' LO SCRIPT CORRETTO BASATO SU QUESTA DIAGNOSTICA');
