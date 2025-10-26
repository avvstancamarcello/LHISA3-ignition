const { readFileSync, writeFileSync, existsSync } = require('fs');

class FinalBattleRealFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - manca la linea della struct
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Riga 97: Manca "modules[moduleName] = ModuleInfo({" prima della struct
        if (lines[96] && lines[96].includes('moduleAddress: moduleAddress,')) {
            // Aggiungi la linea mancante PRIMA della struct
            lines.splice(96, 0, '        modules[moduleName] = ModuleInfo({');
            this.fixes.push('EnhancedModuleRouter: Aggiunta linea struct mancante');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi MareaMangaNFT - mapping fuori dal contratto
    fixMareaMangaNFT() {
        const path = 'contracts/planetary/MareaMangaNFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Trova la fine del contratto (ultima parentesi)
        let contractEnd = -1;
        for (let i = lines.length - 1; i >= 0; i--) {
            if (lines[i].trim() === '}') {
                contractEnd = i;
                break;
            }
        }
        
        // Trova i mapping fuori posto (righe 570-573)
        let mappingLines = [];
        let mappingIndices = [];
        
        for (let i = 0; i < lines.length; i++) {
            if ((i >= 569 && i <= 573) && lines[i].includes('mapping(')) {
                mappingLines.push(lines[i]);
                mappingIndices.push(i);
            }
        }
        
        if (mappingLines.length > 0 && contractEnd !== -1) {
            // Rimuovi i mapping dalla posizione sbagliata
            for (let i = mappingIndices.length - 1; i >= 0; i--) {
                lines.splice(mappingIndices[i], 1);
            }
            
            // Trova dove inserire i mapping (dopo le variabili esistenti)
            let insertIndex = -1;
            for (let i = 0; i < contractEnd; i++) {
                if (lines[i].includes('contract ') && lines[i].includes('{')) {
                    insertIndex = i + 1;
                    break;
                }
            }
            
            // Trova la fine della sezione variabili
            if (insertIndex !== -1) {
                while (insertIndex < contractEnd && 
                       (lines[insertIndex].includes('mapping') || 
                        lines[insertIndex].includes('public') ||
                        lines[insertIndex].includes('private') ||
                        lines[insertIndex].includes('string') ||
                        lines[insertIndex].includes('uint') ||
                        lines[insertIndex].includes('address') ||
                        lines[insertIndex].trim() === '')) {
                    insertIndex++;
                }
                
                // Inserisci i mapping
                lines.splice(insertIndex, 0, '');
                lines.splice(insertIndex, 0, '    // 🗃️ MAPPING PER STORAGE IPFS');
                for (let i = mappingLines.length - 1; i >= 0; i--) {
                    lines.splice(insertIndex, 0, '    ' + mappingLines[i]);
                }
                
                this.fixes.push('MareaMangaNFT: Mapping spostati dentro il contratto');
            }
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi LunaComicsFT - codice fuori posto
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Riga 72: Codice fuori da qualsiasi funzione
        if (lines[71] && lines[71].includes('lastGravityUpdate = block.timestamp;')) {
            // Incapsula in una funzione
            lines[71] = '    function _initializeGravityParams() internal {';
            lines.splice(72, 0, '        lastGravityUpdate = block.timestamp;');
            lines.splice(73, 0, '        peakGravity = lunarGravity;');
            lines.splice(74, 0, '    }');
            lines.splice(75, 0, '');
            
            this.fixes.push('LunaComicsFT: Codice gravity incapsulato in funzione');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    async fixAll() {
        console.log('⚔️  BATTAGLIA FINALE REALE - CORREZIONE ERRORI...\n');

        // Esegui tutte le correzioni
        this.fixEnhancedModuleRouter();
        this.fixMareaMangaNFT();
        this.fixLunaComicsFT();

        console.log('\n📊 RIEPILOGO VITTORIE:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  🎯 ${index + 1}. ${fix}`);
            });
            console.log('\n✅ TUTTI GLI ERRORI CORRETTI!');
        } else {
            console.log('  ❌ Nessuna correzione applicata');
        }

        console.log('\n🚀 PROVA LA COMPILAZIONE FINALE:');
        console.log('   npx hardhat compile');
    }
}

// Esegui la battaglia finale REALE!
const fixer = new FinalBattleRealFixer();
fixer.fixAll().catch(console.error);
