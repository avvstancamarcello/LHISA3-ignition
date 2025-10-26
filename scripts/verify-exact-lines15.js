const { readFileSync, existsSync } = require('fs');

console.log('🔍 VERIFICA REALE DELLE LINEE PROBLEMATICHE:\n');

// EnhancedModuleRouter - verifica riga 248
const enhancedPath = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
if (existsSync(enhancedPath)) {
    console.log('📖 EnhancedModuleRouter.sol - VERIFICA RIGA 248:');
    const content = readFileSync(enhancedPath, 'utf8');
    const lines = content.split('\n');
    
    console.log('Riga 247-249 REALI:');
    console.log(`  247: "${lines[246]}"`);
    console.log(`  248: "${lines[247]}"`);
    console.log(`  249: "${lines[248]}"`);
    
    // Verifica esatta
    if (lines[247] && lines[247].trim() === '}') {
        console.log('✅ Riga 248 contiene: }');
    } else {
        console.log('❌ Riga 248 NON contiene }');
        console.log(`   Contiene invece: "${lines[247]}"`);
    }
}

// LunaComicsFT - verifica riga 225
const lunaPath = 'contracts/satellites/LunaComicsFT.sol';
if (existsSync(lunaPath)) {
    console.log('\n📖 LunaComicsFT.sol - VERIFICA RIGA 225:');
    const content = readFileSync(lunaPath, 'utf8');
    const lines = content.split('\n');
    
    console.log('Riga 224-226 REALI:');
    console.log(`  224: "${lines[223]}"`);
    console.log(`  225: "${lines[224]}"`);
    console.log(`  226: "${lines[225]}"`);
    
    // Verifica esatta
    if (lines[224] && lines[224].trim() === '}') {
        console.log('✅ Riga 225 contiene: }');
    } else {
        console.log('❌ Riga 225 NON contiene }');
        console.log(`   Contiene invece: "${lines[224]}"`);
    }
}

console.log('\n💡 ORA CREERO\' LO SCRIPT CORRETTO BASATO SU QUESTA VERIFICA');
