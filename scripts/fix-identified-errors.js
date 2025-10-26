const { readFileSync, writeFileSync, existsSync } = require('fs');

class IdentifiedErrorsFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - verifica parentesi prima della funzione
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Conta le parentesi fino alla riga 220
        let openBraces = 0;
        let closeBraces = 0;
        
        for (let i = 0; i < 220; i++) {
            openBraces += (lines[i].match(/{/g) || []).length;
            closeBraces += (lines[i].match(/}/g) || []).length;
        }
        
        console.log(`🔍 EnhancedModuleRouter parentesi fino a riga 220: {=${openBraces} }=${closeBraces}`);
        
        // Se manca una parentesi di chiusura, aggiungila prima della funzione
        if (openBraces > closeBraces) {
            // Aggiungi parentesi } prima della funzione alla riga 221
            lines.splice(220, 0, '}');
            this.fixes.push('EnhancedModuleRouter: Aggiunta parentesi } mancante prima della funzione');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi LunaComicsFT - chiudi la funzione _removeFarm
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // CHIUDI la funzione _removeFarm - aggiungi } dopo riga 176
        if (lines[172] && lines[172].includes('function _removeFarm(') && 
            lines[175] && lines[175].includes('userFarmsArray[index] =') && 
            lines[176] && lines[176].trim() === '}') {
            
            // La riga 176 chiude solo l'if, manca la } della funzione
            // Aggiungi un'altra } dopo
            lines.splice(176, 0, '    }');
            this.fixes.push('LunaComicsFT: Aggiunta parentesi } per chiudere _removeFarm');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    async fixAll() {
        console.log('🎯 CORREZIONE ERRORI IDENTIFICATI...\n');

        // Esegui tutte le correzioni
        this.fixEnhancedModuleRouter();
        this.fixLunaComicsFT();

        console.log('\n📊 RIEPILOGO CORREZIONI:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ✅ ${index + 1}. ${fix}`);
            });
            
            console.log('\n🎉 ERRORI IDENTIFICATI RISOLTI!');
        } else {
            console.log('  ❌ Nessuna correzione applicata');
        }

        console.log('\n🚀 PROVA LA COMPILAZIONE:');
        console.log('   npx hardhat compile');
    }
}

// Esegui
const fixer = new IdentifiedErrorsFixer();
fixer.fixAll().catch(console.error);
