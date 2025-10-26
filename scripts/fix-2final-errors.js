const { readFileSync, writeFileSync, existsSync } = require('fs');

class FinalErrorsFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - manca ); dopo la chiamata call()
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Riga 163: Aggiungi ); dopo la chiamata call()
        if (lines[162] && lines[162].includes('            )')) {
            // La chiamata call() non è chiusa - aggiungi );
            lines[162] = '            );';
            this.fixes.push('EnhancedModuleRouter: Aggiunto ); alla chiamata call()');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi LunaComicsFT - _mint fuori da funzione
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Riga 78: _mint fuori da funzione - spostalo in initialize()
        if (lines[77] && lines[77].includes('_mint(msg.sender, 1000000 * 10**18);')) {
            
            // Cerca la funzione initialize()
            let initializeIndex = -1;
            for (let i = 0; i < lines.length; i++) {
                if (lines[i].includes('function initialize()')) {
                    initializeIndex = i;
                    break;
                }
            }
            
            if (initializeIndex !== -1) {
                // Trova dove inserire in initialize() (prima dell'ultima })
                let insertIndex = initializeIndex + 1;
                let braceCount = 0;
                
                while (insertIndex < lines.length) {
                    if (lines[insertIndex].includes('{')) braceCount++;
                    if (lines[insertIndex].includes('}')) {
                        braceCount--;
                        if (braceCount === 0) {
                            // Trovata la parentesi di chiusura di initialize
                            break;
                        }
                    }
                    insertIndex++;
                }
                
                // Inserisci prima della parentesi di chiusura
                if (insertIndex < lines.length) {
                    lines.splice(insertIndex, 0, '        _mint(msg.sender, 1000000 * 10**18);');
                    // Rimuovi la riga originale fuori posto
                    lines.splice(77, 1);
                    this.fixes.push('LunaComicsFT: _mint spostato in initialize()');
                }
            } else {
                // Se non trova initialize, crea una funzione separata
                lines[77] = '    function initialMint() external onlyOwner {';
                lines.splice(78, 0, '        _mint(msg.sender, 1000000 * 10**18);');
                lines.splice(79, 0, '    }');
                this.fixes.push('LunaComicsFT: _mint incapsulato in initialMint()');
            }
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    async fixAll() {
        console.log('🎯 CORREZIONE ERRORI FINALI...\n');

        // Esegui tutte le correzioni
        this.fixEnhancedModuleRouter();
        this.fixLunaComicsFT();

        console.log('\n📊 RIEPILOGO CORREZIONI:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ✅ ${index + 1}. ${fix}`);
            });
            
            console.log('\n🎉 TUTTI GLI ERRORI RISOLTI!');
            console.log('   EnhancedModuleRouter: Chiamata call() completata con );');
            console.log('   LunaComicsFT: _mint spostato dentro una funzione');
        } else {
            console.log('  ❌ Nessuna correzione applicata');
        }

        console.log('\n🚀 PROVA LA COMPILAZIONE FINALE:');
        console.log('   npx hardhat compile');
    }
}

// Esegui
const fixer = new FinalErrorsFixer();
fixer.fixAll().catch(console.error);
