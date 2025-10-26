const { readFileSync, writeFileSync, existsSync } = require('fs');

class ClearErrorsFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - operatore ternario malformato
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // AGGIUNGI la condizione dell'operatore ternario mancante
        if (lines[239] && lines[239].trim() === '' && 
            lines[240] && lines[240].includes('(route.successRate * 99 + 100) / 100 :')) {
            
            lines[239] = '        uint256 newSuccessRate = success ?';
            this.fixes.push('EnhancedModuleRouter: Aggiunta condizione ternario mancante');
        }
        
        // ASSEGNA il risultato a route.successRate
        if (lines[240] && lines[240].includes('(route.successRate * 99 + 100) / 100 :') &&
            lines[241] && lines[241].includes('(route.successRate * 99) / 100;')) {
            
            lines[241] = lines[241].replace(';', ';');
            // Aggiungi l'assegnazione dopo il ternario
            lines.splice(242, 0, '        route.successRate = newSuccessRate;');
            this.fixes.push('EnhancedModuleRouter: Aggiunta assegnazione route.successRate');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi LunaComicsFT - chiudi la funzione _removeFarm
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // CHIUDI COMPLETAMENTE la funzione _removeFarm
        // La funzione inizia alla riga 172 e non è chiusa
        if (lines[171] && lines[171].includes('function _removeFarm(')) {
            // Trova dove inserire la parentesi di chiusura
            // Dopo la riga 176 che chiude l'if
            if (lines[175] && lines[175].includes('userFarmsArray[index] =') && 
                lines[176] && lines[176].trim() === '}') {
                
                // Aggiungi la parentesi di chiusura della funzione DOPO l'if
                lines.splice(176, 0, '    }');
                this.fixes.push('LunaComicsFT: Chiusa funzione _removeFarm');
            }
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    async fixAll() {
        console.log('🎯 CORREZIONE ERRORI CHIARI...\n');

        // Esegui tutte le correzioni
        this.fixEnhancedModuleRouter();
        this.fixLunaComicsFT();

        console.log('\n📊 RIEPILOGO CORREZIONI:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ✅ ${index + 1}. ${fix}`);
            });
            
            console.log('\n🎉 ERRORI CHIARITI!');
        } else {
            console.log('  ❌ Nessuna correzione applicata');
        }

        console.log('\n🚀 PROVA LA COMPILAZIONE:');
        console.log('   npx hardhat compile');
    }
}

// Esegui
const fixer = new ClearErrorsFixer();
fixer.fixAll().catch(console.error);
