const { readFileSync, writeFileSync, existsSync } = require('fs');

class FreshErrorsFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - completa il return statement
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // COMPLETA il return statement - aggiungi ); dopo l'ultimo parametro
        if (lines[293] && lines[293].includes('activeRoutes.length,') && 
            lines[294] && lines[294].trim() === '' && 
            lines[295] && lines[295].trim() === '}') {
            
            // Sostituisci la riga vuota con ); e return
            lines[294] = '        );';
            this.fixes.push('EnhancedModuleRouter: Completato return statement con );');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi LunaComicsFT - rimuovi parentesi extra prima della funzione
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // RIMUOVI parentesi } extra alle righe 247-248
        if (lines[246] && lines[246].includes('pinataJWT = jwt;') && 
            lines[247] && lines[247].trim() === '}' && 
            lines[248] && lines[248].trim() === '}') {
            
            // Rimuovi una delle parentesi extra (la seconda)
            lines.splice(247, 1); // Rimuovi riga 248
            this.fixes.push('LunaComicsFT: Rimossa parentesi } extra prima di _uploadToIPFS');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    async fixAll() {
        console.log('🎯 CORREZIONE ERRORI NUOVI...\n');

        // Esegui tutte le correzioni
        this.fixEnhancedModuleRouter();
        this.fixLunaComicsFT();

        console.log('\n📊 RIEPILOGO CORREZIONI:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ✅ ${index + 1}. ${fix}`);
            });
            
            console.log('\n🎉 ERRORI NUOVI RISOLTI!');
        } else {
            console.log('  ❌ Nessuna correzione applicata');
        }

        console.log('\n🚀 PROVA LA COMPILAZIONE:');
        console.log('   npx hardhat compile');
    }
}

// Esegui
const fixer = new FreshErrorsFixer();
fixer.fixAll().catch(console.error);
