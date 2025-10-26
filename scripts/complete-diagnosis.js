const { readFileSync, existsSync } = require('fs');

console.log('🔍 DIAGNOSTICA COMPLETA:\n');

// EnhancedModuleRouter - diagnostica completa
const enhancedPath = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
if (existsSync(enhancedPath)) {
    console.log('📖 EnhancedModuleRouter.sol - ANALISI COMPLETA:');
    const content = readFileSync(enhancedPath, 'utf8');
    const lines = content.split('\n');
    
    // Cerca TUTTE le occorrenze del problema
    console.log('🔍 CERCO TUTTE LE FUNZIONI MALFORMATE:');
    for (let i = 0; i < lines.length; i++) {
        if (lines[i] && lines[i].includes(') external view returns (')) {
            console.log(`\n⚠️  Trovata alla riga ${i + 1}:`);
            console.log(`  "${lines[i]}"`);
            console.log('Contesto (5 righe prima e dopo):');
            for (let j = Math.max(0, i - 5); j < Math.min(i + 6, lines.length); j++) {
                console.log(`  ${j + 1}: "${lines[j]}"`);
            }
        }
    }
    
    // Conta parentesi totali
    let openBraces = 0;
    let closeBraces = 0;
    for (let i = 0; i < lines.length; i++) {
        openBraces += (lines[i].match(/{/g) || []).length;
        closeBraces += (lines[i].match(/}/g) || []).length;
    }
    console.log(`\n📊 Parentesi totali EnhancedModuleRouter: {=${openBraces} }=${closeBraces}`);
}

// LunaComicsFT - diagnostica completa
const lunaPath = 'contracts/satellites/LunaComicsFT.sol';
if (existsSync(lunaPath)) {
    console.log('\n📖 LunaComicsFT.sol - ANALISI COMPLETA:');
    const content = readFileSync(lunaPath, 'utf8');
    const lines = content.split('\n');
    
    // Verifica se _uploadToIPFS è dentro il contratto
    let contractStart = -1;
    let contractEnd = -1;
    let braceCount = 0;
    
    for (let i = 0; i < lines.length; i++) {
        if (lines[i].includes('contract ') && braceCount === 0) {
            contractStart = i;
            braceCount++;
        } else if (braceCount > 0) {
            if (lines[i].includes('{')) braceCount++;
            if (lines[i].includes('}')) braceCount--;
            if (braceCount === 0) {
                contractEnd = i;
                break;
            }
        }
    }
    
    console.log(`Contratto: riga ${contractStart + 1} - ${contractEnd + 1}`);
    console.log(`Funzione _uploadToIPFS alla riga: 250`);
    console.log(`_uploadToIPFS dentro contratto: ${250 >= contractStart && 250 <= contractEnd ? 'SI' : 'NO'}`);
    
    // Mostra la fine del contratto
    console.log('\nFine del contratto:');
    for (let i = Math.max(0, contractEnd - 5); i <= contractEnd && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
    
    // Mostra dove si trova _uploadToIPFS
    console.log('\nPosizione _uploadToIPFS:');
    for (let i = 245; i < 255 && i < lines.length; i++) {
        console.log(`  ${i + 1}: "${lines[i]}"`);
    }
}

console.log('\n💡 BASATO SU QUESTA DIAGNOSTICA COMPLETA, CREERO\' LO SCRIPT FINALE');
