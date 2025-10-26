const { readFileSync, existsSync } = require('fs');

console.log('🔍 VERIFICA SPECIFICA PATTERN:\n');

// EnhancedModuleRouter - verifica esatta del contesto
const enhancedPath = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
if (existsSync(enhancedPath)) {
    console.log('📖 EnhancedModuleRouter.sol - CERCO FUNCTION getRouterStats:');
    const content = readFileSync(enhancedPath, 'utf8');
    const lines = content.split('\n');
    
    // Cerca la funzione specifica
    for (let i = 0; i < lines.length; i++) {
        if (lines[i] && lines[i].includes('getRouterStats')) {
            console.log(`Trovata alla riga ${i + 1}: "${lines[i]}"`);
            
            // Mostra il contenuto completo della funzione
            console.log('\nContenuto funzione getRouterStats:');
            let braceCount = 0;
            let foundReturn = false;
            
            for (let j = i; j < Math.min(i + 15, lines.length); j++) {
                console.log(`  ${j + 1}: "${lines[j]}"`);
                if (lines[j].includes('{')) braceCount++;
                if (lines[j].includes('}')) braceCount--;
                if (lines[j].includes('return')) foundReturn = true;
                if (braceCount === 0 && j > i) break;
            }
            
            console.log(`\nReturn trovato: ${foundReturn}`);
            break;
        }
    }
    
    // Cerca specificamente i parametri del return
    console.log('\n🔍 CERCO PARAMETRI RETURN (totalRouteCalls, ecc):');
    for (let i = 0; i < lines.length; i++) {
        if (lines[i] && lines[i].includes('totalRouteCalls,')) {
            console.log(`Parametri trovati alla riga ${i + 1}:`);
            for (let j = i; j < Math.min(i + 6, lines.length); j++) {
                console.log(`  ${j + 1}: "${lines[j]}"`);
            }
            break;
        }
    }
}

// LunaComicsFT - verifica esatta del contesto
const lunaPath = 'contracts/satellites/LunaComicsFT.sol';
if (existsSync(lunaPath)) {
    console.log('\n📖 LunaComicsFT.sol - VERIFICA CONTRATTO CHIUSO:');
    const content = readFileSync(lunaPath, 'utf8');
    const lines = content.split('\n');
    
    // Trova l'inizio del contratto
    let contractStart = -1;
    for (let i = 0; i < lines.length; i++) {
        if (lines[i] && lines[i].includes('contract ') && lines[i].includes('{')) {
            contractStart = i;
            console.log(`Contratto inizia alla riga ${i + 1}: "${lines[i]}"`);
            break;
        }
    }
    
    // Conta parentesi fino alla riga 251
    if (contractStart !== -1) {
        let openBraces = 0;
        let closeBraces = 0;
        
        for (let i = contractStart; i < 251; i++) {
            openBraces += (lines[i].match(/{/g) || []).length;
            closeBraces += (lines[i].match(/}/g) || []).length;
        }
        
        console.log(`Parentesi fino a riga 251: {=${openBraces} }=${closeBraces}`);
        console.log(`Contratto aperto: ${openBraces > closeBraces}`);
        
        // Mostra le ultime parentesi prima della riga 251
        console.log('\nUltime parentesi prima di riga 251:');
        for (let i = 240; i < 251; i++) {
            if (lines[i].includes('{') || lines[i].includes('}')) {
                console.log(`  ${i + 1}: "${lines[i]}"`);
            }
        }
    }
}

console.log('\n💡 ORA CREERO\' LO SCRIPT CORRETTO BASATO SU QUESTA VERIFICA');
