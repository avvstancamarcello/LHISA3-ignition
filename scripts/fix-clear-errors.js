const { readFileSync, writeFileSync, existsSync } = require('fs');

class ClearErrorsFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - aggiungi corpo funzione mancante
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Aggiungi il corpo mancante della funzione dopo encodeWithSignature
        if (lines[213] && lines[213].includes('weight') && lines[214].trim() === '' && lines[215].trim() === '}') {
            // Sostituisci le righe vuote con il corpo della funzione
            lines[214] = '        );';
            lines[215] = '';
            lines[216] = '        (success, ) = executeRoute("reputation_update", payload);';
            lines[217] = '        return success;';
            
            // Sposta la parentesi } alla riga corretta
            lines[218] = '    }';
            
            this.fixes.push('EnhancedModuleRouter: Aggiunto corpo funzione updateReputation');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi LunaComicsFT - sistema funzione malformata e parentesi
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Sistema la funzione _removeFarm (manca la parentesi di chiusura)
        if (lines[172] && lines[172].includes('function _removeFarm(') && 
            lines[175] && lines[175].includes('userFarmsArray[index] =') && 
            lines[176] && lines[176].trim() === '}') {
            
            // La funzione _removeFarm non è chiusa correttamente - aggiungi }
            lines.splice(176, 0, '        }');
            this.fixes.push('LunaComicsFT: Aggiunta parentesi } a _removeFarm');
        }
        
        // Correggi la funzione malformata userFarmsArray.pop()
        if (lines[177] && lines[177].includes('function userFarmsArray.pop()')) {
            // Cambia in una funzione normale
            lines[177] = '    function popUserFarm() external onlyOwner {';
            this.fixes.push('LunaComicsFT: Corretta funzione userFarmsArray.pop()');
        }
        
        // Rimuovi parentesi extra
        if (lines[180] && lines[180].trim() === '}') {
            lines.splice(180, 1);
            this.fixes.push('LunaComicsFT: Rimossa parentesi } extra');
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
