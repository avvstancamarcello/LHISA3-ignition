const { readFileSync, writeFileSync, existsSync } = require('fs');

class WorkingBracesFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - rimuovi parentesi extra alla riga 248
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // VERIFICA: riga 247 = "    }", riga 248 = "    }"
        if (lines[246] && lines[246].trim() === '}' && 
            lines[247] && lines[247].trim() === '}') {
            
            // Rimuovi la riga 248 (la seconda parentesi })
            lines.splice(247, 1); // Rimuovi l'elemento all'indice 247 (riga 248)
            this.fixes.push('EnhancedModuleRouter: Rimossa parentesi } extra alla riga 248');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi LunaComicsFT - rimuovi parentesi extra alla riga 225
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // VERIFICA: riga 224 = funzione già chiusa, riga 225 = "    }" extra
        if (lines[223] && lines[223].includes('_authorizeUpgrade') && 
            lines[223].includes('{}') && // La funzione è già chiusa con {}
            lines[224] && lines[224].trim() === '}') {
            
            // Rimuovi la riga 225 (parentesi } extra)
            lines.splice(224, 1); // Rimuovi l'elemento all'indice 224 (riga 225)
            this.fixes.push('LunaComicsFT: Rimossa parentesi } extra alla riga 225');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    async fixAll() {
        console.log('🎯 CORREZIONE PARENTESI EXTRA FUNZIONANTE...\n');

        // Esegui tutte le correzioni
        this.fixEnhancedModuleRouter();
        this.fixLunaComicsFT();

        console.log('\n📊 RIEPILOGO CORREZIONI:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ✅ ${index + 1}. ${fix}`);
            });
            
            console.log('\n🎉 PARENTESI EXTRA RIMOSSE!');
        } else {
            console.log('  ❌ Nessuna correzione applicata');
        }

        console.log('\n🚀 PROVA LA COMPILAZIONE FINALE:');
        console.log('   npx hardhat compile');
    }
}

// Esegui
const fixer = new WorkingBracesFixer();
fixer.fixAll().catch(console.error);
