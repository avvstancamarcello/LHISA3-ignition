const { readFileSync, writeFileSync, existsSync } = require('fs');

class ExactErrorFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - aggiungi linea struct mancante
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Riga 130: Aggiungi "routes[routeName] = RouteConfig({" prima della struct
        if (lines[129] && lines[129].includes('routeName: routeName,')) {
            lines.splice(129, 0, '        routes[routeName] = RouteConfig({');
            this.fixes.push('EnhancedModuleRouter: Aggiunta routes[routeName] = RouteConfig({ alla riga 129');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi MareaMangaNFT - rimuovi parentesi extra
    fixMareaMangaNFT() {
        const path = 'contracts/planetary/MareaMangaNFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Riga 735: Rimuovi la parentesi } extra
        if (lines[734] && lines[734].trim() === '}') {
            lines.splice(734, 1); // Rimuovi la riga 735
            this.fixes.push('MareaMangaNFT: Rimossa parentesi } extra alla riga 735');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi LunaComicsFT - rimuovi codice duplicato
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Riga 77: Rimuovi "peakGravity = lunarGravity;" duplicato
        if (lines[76] && lines[76].includes('peakGravity = lunarGravity;')) {
            lines.splice(76, 1); // Rimuovi la riga 77
            this.fixes.push('LunaComicsFT: Rimossa assegnazione duplicata peakGravity alla riga 77');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    async fixAll() {
        console.log('🎯 CORREZIONE ERRORI ESATTI...\n');

        // Esegui tutte le correzioni
        this.fixEnhancedModuleRouter();
        this.fixMareaMangaNFT();
        this.fixLunaComicsFT();

        console.log('\n📊 RIEPILOGO CORREZIONI APPLICATE:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ✅ ${index + 1}. ${fix}`);
            });
            
            console.log('\n🎉 CORREZIONI COMPLETATE!');
            console.log('   EnhancedModuleRouter: Struct RouteConfig completata');
            console.log('   MareaMangaNFT: Parentesi extra rimossa'); 
            console.log('   LunaComicsFT: Codice duplicato rimosso');
        } else {
            console.log('  ❌ Nessuna correzione applicata - errori già risolti');
        }

        console.log('\n🚀 PROVA LA COMPILAZIONE:');
        console.log('   npx hardhat compile');
    }
}

// Esegui
const fixer = new ExactErrorFixer();
fixer.fixAll().catch(console.error);
