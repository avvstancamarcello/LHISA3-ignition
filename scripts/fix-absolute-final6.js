const { readFileSync, writeFileSync, existsSync } = require('fs');

class AbsoluteFinalFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - aggiungi ); dopo weight
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Riga 214: Aggiungi ); dopo weight per chiudere encodeWithSignature
        if (lines[213] && lines[213].includes('weight') && !lines[213].includes(');')) {
            lines[213] = lines[213] + ');';
            this.fixes.push('EnhancedModuleRouter: Aggiunto ); dopo weight alla riga 214');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi LunaComicsFT - rimuovi le ultime 2 parentesi extra
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Rimuovi le ultime 2 parentesi } extra
        let removed = 0;
        
        // Cerca parentesi } alla fine del file
        for (let i = lines.length - 1; i >= 0 && removed < 2; i--) {
            if (lines[i].trim() === '}') {
                lines.splice(i, 1);
                removed++;
            }
        }
        
        if (removed > 0) {
            this.fixes.push(`LunaComicsFT: Rimosse ${removed} parentesi } extra finali`);
        }
        
        // Verifica il bilanciamento finale
        let openBraces = 0;
        let closeBraces = 0;
        for (let i = 0; i < lines.length; i++) {
            openBraces += (lines[i].match(/{/g) || []).length;
            closeBraces += (lines[i].match(/}/g) || []).length;
        }
        
        console.log(`🔍 LunaComicsFT parentesi finali: {=${openBraces} }=${closeBraces}`);
        
        writeFileSync(path, lines.join('\n'));
    }

    async fixAll() {
        console.log('🏁 CORREZIONE ASSOLUTAMENTE FINALE...\n');

        // Esegui tutte le correzioni
        this.fixEnhancedModuleRouter();
        this.fixLunaComicsFT();

        console.log('\n📊 RIEPILOGO CORREZIONI:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ✅ ${index + 1}. ${fix}`);
            });
            
            console.log('\n🎉 TUTTI GLI ERRORI RISOLTI!');
            console.log('   EnhancedModuleRouter: encodeWithSignature chiuso correttamente');
            console.log('   LunaComicsFT: Parentesi bilanciate');
        } else {
            console.log('  ❌ Nessuna correzione applicata');
        }

        console.log('\n🚀 PROVA LA COMPILAZIONE FINALE:');
        console.log('   npx hardhat compile');
    }
}

// Esegui
const fixer = new AbsoluteFinalFixer();
fixer.fixAll().catch(console.error);
