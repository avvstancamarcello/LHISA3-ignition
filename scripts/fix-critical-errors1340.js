const { readFileSync, writeFileSync, existsSync } = require('fs');

class CriticalErrorsFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - ricostruisci completamente il return
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Trova la funzione che ha il return incompleto
        let functionStart = -1;
        for (let i = 280; i < 290; i++) {
            if (lines[i] && lines[i].includes('function getRouterStats')) {
                functionStart = i;
                break;
            }
        }
        
        if (functionStart !== -1) {
            // Ricostruisci il return statement completo
            // Trova dove inizia la lista dei parametri
            let paramsStart = -1;
            for (let i = functionStart; i < 295; i++) {
                if (lines[i] && lines[i].includes('totalRouteCalls,')) {
                    paramsStart = i;
                    break;
                }
            }
            
            if (paramsStart !== -1) {
                // Aggiungi "return (" prima dei parametri
                lines[paramsStart - 1] = '        return (';
                // Aggiungi ");" dopo l'ultimo parametro
                if (lines[293] && lines[293].includes('activeRoutes.length,')) {
                    lines[294] = '        );';
                }
                this.fixes.push('EnhancedModuleRouter: Ricostruito return statement completo');
            }
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi LunaComicsFT - riapri il contratto prima della funzione
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // RIMUOVI le parentesi } extra che chiudono il contratto troppo presto
        // Le righe 247-248 chiudono il contratto, ma dovrebbero chiudere solo una funzione
        
        if (lines[246] && lines[246].includes('pinataJWT = jwt;') && 
            lines[247] && lines[247].trim() === '}' && 
            lines[248] && lines[248].trim() === '}') {
            
            // Rimuovi UNA parentesi } per riaprire il contratto
            lines.splice(247, 1); // Rimuovi riga 248
            this.fixes.push('LunaComicsFT: Riaperto contratto - rimossa parentesi } extra');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    async fixAll() {
        console.log('🎯 CORREZIONE ERRORI CRITICI...\n');

        // Esegui tutte le correzioni
        this.fixEnhancedModuleRouter();
        this.fixLunaComicsFT();

        console.log('\n📊 RIEPILOGO CORREZIONI:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ✅ ${index + 1}. ${fix}`);
            });
            
            console.log('\n🎉 ERRORI CRITICI RISOLTI!');
        } else {
            console.log('  ❌ Nessuna correzione applicata');
        }

        console.log('\n🚀 PROVA LA COMPILAZIONE:');
        console.log('   npx hardhat compile');
    }
}

// Esegui
const fixer = new CriticalErrorsFixer();
fixer.fixAll().catch(console.error);
