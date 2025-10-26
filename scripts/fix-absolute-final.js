const { readFileSync, writeFileSync, existsSync } = require('fs');

class AbsoluteFinalFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - ricostruisci completamente la funzione
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // TROVA il blocco di parametri malformato (righe 269-272)
        let paramsStart = -1;
        for (let i = 0; i < lines.length; i++) {
            if (lines[i] && lines[i].includes('uint256 successfulCalls,')) {
                paramsStart = i;
                break;
            }
        }
        
        if (paramsStart !== -1) {
            // Ricostruisci la funzione COMPLETAMENTE
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
            
            // Trova dove finisce il blocco malformato
            let paramsEnd = paramsStart;
            while (paramsEnd < lines.length && !lines[paramsEnd].includes('}')) {
                paramsEnd++;
            }
            
            // Sostituisci il blocco malformato con la funzione corretta
            lines.splice(paramsStart, paramsEnd - paramsStart + 1, ...correctFunction);
            this.fixes.push('EnhancedModuleRouter: Ricostruita completamente funzione getRouterStats');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi LunaComicsFT - riapri il contratto
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // RIMUOVI le parentesi di chiusura premature
        // Trova l'ultima parentesi } prima della riga 251
        let lastBraceIndex = -1;
        for (let i = 250; i >= 0; i--) {
            if (lines[i] && lines[i].trim() === '}') {
                lastBraceIndex = i;
                break;
            }
        }
        
        if (lastBraceIndex !== -1) {
            // Rimuovi la parentesi di chiusura prematura
            lines.splice(lastBraceIndex, 1);
            this.fixes.push('LunaComicsFT: Riaperto contratto - rimossa parentesi } di chiusura prematura');
        }
        
        // Verifica se il contratto è ora aperto
        let contractBraces = 0;
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].includes('contract ') && contractBraces === 0) {
                contractBraces++;
            } else if (contractBraces > 0) {
                if (lines[i].includes('{')) contractBraces++;
                if (lines[i].includes('}')) contractBraces--;
            }
        }
        
        console.log(`🔍 LunaComicsFT - Contratto aperto dopo correzione: ${contractBraces > 0}`);
        
        writeFileSync(path, lines.join('\n'));
    }

    async fixAll() {
        console.log('🎯 CORREZIONE DEFINITIVA FINALE...\n');

        // Esegui tutte le correzioni
        this.fixEnhancedModuleRouter();
        this.fixLunaComicsFT();

        console.log('\n📊 RIEPILOGO CORREZIONI:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ✅ ${index + 1}. ${fix}`);
            });
            
            console.log('\n🎉 CORREZIONI DEFINITIVE APPLICATE!');
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
