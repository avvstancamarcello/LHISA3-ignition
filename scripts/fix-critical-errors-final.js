const { readFileSync, writeFileSync, existsSync } = require('fs');

class CriticalErrorsFinalFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - ricostruisci completamente getRouterStats
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // TROVA e CORREGGI la funzione getRouterStats malformata
        let problemStart = -1;
        for (let i = 0; i < lines.length; i++) {
            if (lines[i] && lines[i].includes(') external view returns (')) {
                problemStart = i;
                break;
            }
        }
        
        if (problemStart !== -1) {
            // Ricostruisci la funzione CORRETTAMENTE
            const correctFunction = [
                '    function getRouterStats() external view returns (',
                '        uint256 totalCalls,',
                '        uint256 successfulCalls,',
                '        uint256 totalInteractions,',
                '        uint256 activeModulesCount,',
                '        uint256 activeRoutesCount',
                '    ) {',
                '        return (',
                '            totalRouteCalls,',
                '            successfulRouteCalls,',
                '            totalModuleInteractions,',
                '            activeModules.length,',
                '            activeRoutes.length',
                '        );',
                '    }'
            ];
            
            // Rimuovi la versione malformata e inserisci quella corretta
            // Trova dove finisce la versione malformata
            let problemEnd = problemStart;
            while (problemEnd < lines.length && !lines[problemEnd].includes('}')) {
                problemEnd++;
            }
            
            lines.splice(problemStart, problemEnd - problemStart + 1, ...correctFunction);
            this.fixes.push('EnhancedModuleRouter: Ricostruita funzione getRouterStats correttamente');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi LunaComicsFT - sistema definitivamente la struttura
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // RIMUOVI COMPLETAMENTE le parentesi extra che corrompono la struttura
        // Le righe 247-248 hanno parentesi } extra
        
        if (lines[246] && lines[246].includes('pinataJWT = jwt;') && 
            lines[247] && lines[247].trim() === '}' && 
            lines[248] && lines[248].trim() === '}') {
            
            // Rimuovi UNA parentesi } per sistemare la struttura
            lines.splice(247, 1); // Rimuovi riga 248
            this.fixes.push('LunaComicsFT: Rimossa parentesi } extra che corrompeva la struttura');
        }
        
        // Verifica finale
        let braceCount = 0;
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].includes('{')) braceCount++;
            if (lines[i].includes('}')) braceCount--;
        }
        console.log(`🔍 LunaComicsFT parentesi finali: ${braceCount}`);
        
        writeFileSync(path, lines.join('\n'));
    }

    async fixAll() {
        console.log('🎯 CORREZIONE ERRORI CRITICI FINALI...\n');

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

        console.log('\n🚀 PROVA LA COMPILAZIONE FINALE:');
        console.log('   npx hardhat compile');
    }
}

// Esegui
const fixer = new CriticalErrorsFinalFixer();
fixer.fixAll().catch(console.error);
