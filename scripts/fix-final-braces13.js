const { readFileSync, writeFileSync, existsSync } = require('fs');

class FinalBracesFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - chiudi _uint2str e rimuovi parentesi extra
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // CHIUDI la funzione _uint2str (manca })
        if (lines[333] && lines[333].includes('function _uint2str(') && 
            lines[334] && lines[334].includes('if (_i == 0) return "0";') &&
            lines[335] && lines[335].trim() === '}') {
            
            // La riga 335 chiude _uint2str, ma abbiamo una parentesi extra dopo
            // Verifica se c'è una parentesi extra alla fine
            if (lines[lines.length - 1].trim() === '}' && lines[lines.length - 2].trim() === '}') {
                // Rimuovi l'ultima parentesi extra
                lines.pop();
                this.fixes.push('EnhancedModuleRouter: Rimossa parentesi } extra finale');
            }
        }
        
        // Se ancora abbiamo parentesi extra, rimuovile dalla fine
        let openBraces = 0;
        let closeBraces = 0;
        for (let i = 0; i < lines.length; i++) {
            openBraces += (lines[i].match(/{/g) || []).length;
            closeBraces += (lines[i].match(/}/g) || []).length;
        }
        
        if (closeBraces > openBraces) {
            let extra = closeBraces - openBraces;
            for (let i = 0; i < extra && lines.length > 0; i++) {
                if (lines[lines.length - 1].trim() === '}') {
                    lines.pop();
                }
            }
            this.fixes.push(`EnhancedModuleRouter: Rimosse ${extra} parentesi } extra`);
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi LunaComicsFT - chiudi _addressToString e sistema updateGravity
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // CHIUDI la funzione _addressToString e sposta updateGravity FUORI
        let addressToStringStart = -1;
        for (let i = 0; i < lines.length; i++) {
            if (lines[i] && lines[i].includes('function _addressToString(')) {
                addressToStringStart = i;
                break;
            }
        }
        
        if (addressToStringStart !== -1) {
            // Trova updateGravity dentro _addressToString
            let updateGravityStart = -1;
            for (let i = addressToStringStart; i < lines.length; i++) {
                if (lines[i] && lines[i].includes('function updateGravity()')) {
                    updateGravityStart = i;
                    break;
                }
            }
            
            if (updateGravityStart !== -1) {
                // Chiudi _addressToString prima di updateGravity
                lines.splice(updateGravityStart, 0, '    }');
                this.fixes.push('LunaComicsFT: Chiusa _addressToString e separata updateGravity');
            }
        }
        
        // Verifica parentesi finali
        let openBraces = 0;
        let closeBraces = 0;
        for (let i = 0; i < lines.length; i++) {
            openBraces += (lines[i].match(/{/g) || []).length;
            closeBraces += (lines[i].match(/}/g) || []).length;
        }
        
        console.log(`🔍 LunaComicsFT parentesi dopo correzione: {=${openBraces} }=${closeBraces}`);
        
        writeFileSync(path, lines.join('\n'));
    }

    async fixAll() {
        console.log('🎯 CORREZIONE PARENTESI FINALI...\n');

        // Esegui tutte le correzioni
        this.fixEnhancedModuleRouter();
        this.fixLunaComicsFT();

        console.log('\n📊 RIEPILOGO CORREZIONI:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ✅ ${index + 1}. ${fix}`);
            });
            
            console.log('\n🎉 PARENTESI SISTEMATE!');
        } else {
            console.log('  ❌ Nessuna correzione applicata');
        }

        console.log('\n🚀 PROVA LA COMPILAZIONE FINALE:');
        console.log('   npx hardhat compile');
    }
}

// Esegui
const fixer = new FinalBracesFixer();
fixer.fixAll().catch(console.error);
