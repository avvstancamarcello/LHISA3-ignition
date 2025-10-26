const { readFileSync, writeFileSync, existsSync } = require('fs');

class RealErrorsFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - ricostruisci completamente _updateRouteStats
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Trova la funzione _updateRouteStats
        let functionStart = -1;
        for (let i = 0; i < lines.length; i++) {
            if (lines[i] && lines[i].includes('function _updateRouteStats')) {
                functionStart = i;
                break;
            }
        }
        
        if (functionStart !== -1) {
            // Sostituisci il contenuto corrotto della funzione
            // Trova la fine della funzione (})
            let functionEnd = -1;
            let braceCount = 0;
            
            for (let i = functionStart; i < lines.length; i++) {
                if (lines[i].includes('{')) braceCount++;
                if (lines[i].includes('}')) {
                    braceCount--;
                    if (braceCount === 0) {
                        functionEnd = i;
                        break;
                    }
                }
            }
            
            if (functionEnd !== -1) {
                // Ricostruisci la funzione correttamente
                const newFunctionBody = [
                    '    ) internal {',
                    '        RouteConfig storage route = routes[routeName];',
                    '',
                    '        // Aggiorna success rate con media mobile',
                    '        uint256 newSuccessRate = success ?',
                    '            (route.successRate * 99 + 100) / 100 : // Media mobile per successo',
                    '            (route.successRate * 99) / 100;        // Media mobile per fallimento',
                    '        route.successRate = newSuccessRate;',
                    '',
                    '        // Aggiorna latency media',
                    '        route.averageLatency = (route.averageLatency * 99 + latency) / 100;',
                    '    }'
                ];
                
                // Rimuovi il vecchio contenuto e inserisci il nuovo
                lines.splice(functionStart + 4, functionEnd - functionStart - 4, ...newFunctionBody);
                this.fixes.push('EnhancedModuleRouter: Ricostruita funzione _updateRouteStats');
            }
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi LunaComicsFT - chiudi _removeFarm e sistema popLastUserFarm
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Trova la funzione _removeFarm
        let removeFarmStart = -1;
        for (let i = 0; i < lines.length; i++) {
            if (lines[i] && lines[i].includes('function _removeFarm')) {
                removeFarmStart = i;
                break;
            }
        }
        
        if (removeFarmStart !== -1) {
            // La funzione _removeFarm non è chiusa - popLastUserFarm è dentro di essa
            // Sposta popLastUserFarm FUORI da _removeFarm
            
            // Trova dove inizia popLastUserFarm
            let popFunctionStart = -1;
            for (let i = removeFarmStart; i < lines.length; i++) {
                if (lines[i] && lines[i].includes('function popLastUserFarm')) {
                    popFunctionStart = i;
                    break;
                }
            }
            
            if (popFunctionStart !== -1) {
                // Chiudi _removeFarm prima di popLastUserFarm
                lines.splice(popFunctionStart, 0, '    }');
                this.fixes.push('LunaComicsFT: Chiusa _removeFarm e separata popLastUserFarm');
            }
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    async fixAll() {
        console.log('🎯 CORREZIONE ERRORI REALI...\n');

        // Esegui tutte le correzioni
        this.fixEnhancedModuleRouter();
        this.fixLunaComicsFT();

        console.log('\n📊 RIEPILOGO CORREZIONI:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ✅ ${index + 1}. ${fix}`);
            });
            
            console.log('\n🎉 ERRORI REALI RISOLTI!');
        } else {
            console.log('  ❌ Nessuna correzione applicata');
        }

        console.log('\n🚀 PROVA LA COMPILAZIONE:');
        console.log('   npx hardhat compile');
    }
}

// Esegui
const fixer = new RealErrorsFixer();
fixer.fixAll().catch(console.error);
