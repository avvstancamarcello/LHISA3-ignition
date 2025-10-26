const { readFileSync, writeFileSync, existsSync } = require('fs');

class RealProblemsFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - aggiungi corpo alla funzione getRouterStats
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Trova la funzione getRouterStats
        let functionStart = -1;
        for (let i = 0; i < lines.length; i++) {
            if (lines[i] && lines[i].includes('function getRouterStats()')) {
                functionStart = i;
                break;
            }
        }
        
        if (functionStart !== -1) {
            // Trova dove inizia il corpo della funzione
            let bodyStart = -1;
            for (let i = functionStart; i < lines.length; i++) {
                if (lines[i] && lines[i].includes('{')) {
                    bodyStart = i;
                    break;
                }
            }
            
            if (bodyStart !== -1) {
                // Sostituisci il contenuto corrotto con un return statement valido
                // Trova dove finiscono i parametri attuali
                let paramsEnd = -1;
                for (let i = bodyStart + 1; i < lines.length; i++) {
                    if (lines[i] && lines[i].trim() === '' && i > bodyStart + 5) {
                        paramsEnd = i;
                        break;
                    }
                }
                
                if (paramsEnd !== -1) {
                    // Ricostruisci la funzione con return statement valido
                    const newBody = [
                        '    ) external view returns (',
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
                    
                    // Rimuovi il vecchio contenuto e inserisci il nuovo
                    lines.splice(functionStart, paramsEnd - functionStart + 1, ...newBody);
                    this.fixes.push('EnhancedModuleRouter: Ricostruita funzione getRouterStats');
                }
            }
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi LunaComicsFT - sistema la struttura del contratto
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // La funzione _uploadToIPFS è nel posto giusto ma verifichiamo la struttura
        // Controlla se ci sono parentesi extra che causano problemi
        
        // Verifica la funzione configureStorage che precede _uploadToIPFS
        let configureStorageEnd = -1;
        for (let i = 240; i < 250; i++) {
            if (lines[i] && lines[i].includes('configureStorage') && lines[i].includes('function')) {
                // Trova la fine di questa funzione
                let braceCount = 0;
                for (let j = i; j < Math.min(i + 10, lines.length); j++) {
                    if (lines[j].includes('{')) braceCount++;
                    if (lines[j].includes('}')) braceCount--;
                    if (braceCount === 0 && j > i) {
                        configureStorageEnd = j;
                        break;
                    }
                }
                break;
            }
        }
        
        // Se configureStorage non è chiusa correttamente, sistemala
        if (configureStorageEnd !== -1 && lines[configureStorageEnd] && 
            lines[configureStorageEnd].trim() === '}' && 
            lines[configureStorageEnd + 1] && lines[configureStorageEnd + 1].trim() === '}') {
            
            // Rimuovi la parentesi extra
            lines.splice(configureStorageEnd + 1, 1);
            this.fixes.push('LunaComicsFT: Sistemata struttura configureStorage');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    async fixAll() {
        console.log('🎯 CORREZIONE PROBLEMI REALI...\n');

        // Esegui tutte le correzioni
        this.fixEnhancedModuleRouter();
        this.fixLunaComicsFT();

        console.log('\n📊 RIEPILOGO CORREZIONI:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ✅ ${index + 1}. ${fix}`);
            });
            
            console.log('\n🎉 PROBLEMI REALI RISOLTI!');
        } else {
            console.log('  ❌ Nessuna correzione applicata');
        }

        console.log('\n🚀 PROVA LA COMPILAZIONE:');
        console.log('   npx hardhat compile');
    }
}

// Esegui
const fixer = new RealProblemsFixer();
fixer.fixAll().catch(console.error);
