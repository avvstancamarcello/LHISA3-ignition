const { readFileSync, writeFileSync, existsSync } = require('fs');

class NewErrorsFixer2 {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - aggiungi virgola mancante
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // AGGIUNGI virgola all'ultimo parametro del return
        if (lines[292] && lines[292].includes('activeRoutes.length') && 
            !lines[292].includes(',')) {
            
            lines[292] = lines[292] + ',';
            this.fixes.push('EnhancedModuleRouter: Aggiunta virgola dopo activeRoutes.length');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi LunaComicsFT - rimuovi parentesi extra
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // RIMUOVI parentesi } extra alle righe 234-235
        if (lines[233] && lines[233].trim() === '}' && 
            lines[234] && lines[234].trim() === '}') {
            
            // Rimuovi entrambe le parentesi extra
            lines.splice(233, 2); // Rimuovi righe 234 e 235
            this.fixes.push('LunaComicsFT: Rimosse parentesi } extra alle righe 234-235');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    async fixAll() {
        console.log('🎯 CORREZIONE NUOVI ERRORI...\n');

        // Esegui tutte le correzioni
        this.fixEnhancedModuleRouter();
        this.fixLunaComicsFT();

        console.log('\n📊 RIEPILOGO CORREZIONI:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ✅ ${index + 1}. ${fix}`);
            });
            
            console.log('\n🎉 NUOVI ERRORI RISOLTI!');
        } else {
            console.log('  ❌ Nessuna correzione applicata');
        }

        console.log('\n🚀 PROVA LA COMPILAZIONE:');
        console.log('   npx hardhat compile');
    }
}

// Esegui
const fixer = new NewErrorsFixer2();
fixer.fixAll().catch(console.error);
