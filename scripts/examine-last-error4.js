const { readFileSync, writeFileSync, existsSync } = require('fs');

class LatestErrorsFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - parentesi problematica
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Analizza il contesto della riga 215
        console.log('🔍 EnhancedModuleRouter riga 215 contesto:');
        for (let i = 212; i < 218 && i < lines.length; i++) {
            console.log(`   ${i + 1}: ${lines[i]}`);
        }
        
        // Probabile problema: encodeWithSignature non chiuso correttamente
        // Cerca encodeWithSignature prima della riga 215
        let encodeLine = -1;
        for (let i = 210; i < 215; i++) {
            if (lines[i] && lines[i].includes('abi.encodeWithSignature(')) {
                encodeLine = i;
                break;
            }
        }
        
        if (encodeLine !== -1) {
            // Verifica se encodeWithSignature è chiuso
            let parenCount = 0;
            let foundClose = false;
            
            for (let i = encodeLine; i < 215; i++) {
                if (lines[i].includes('(')) parenCount++;
                if (lines[i].includes(')')) {
                    parenCount--;
                    if (parenCount === 0) {
                        foundClose = true;
                        break;
                    }
                }
            }
            
            if (!foundClose) {
                // Aggiungi ); prima della parentesi }
                if (lines[214] && lines[214].trim() === '}') {
                    lines.splice(214, 0, '        );');
                    this.fixes.push('EnhancedModuleRouter: Aggiunto ); prima della parentesi }');
                }
            }
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi LunaComicsFT - parentesi extra
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Conta le parentesi per trovare quelle extra
        let openBraces = 0;
        let closeBraces = 0;
        
        for (let i = 0; i < lines.length; i++) {
            openBraces += (lines[i].match(/{/g) || []).length;
            closeBraces += (lines[i].match(/}/g) || []).length;
        }
        
        console.log(`🔍 LunaComicsFT parentesi: {=${openBraces} }=${closeBraces}`);
        
        // Se ci sono più }, rimuovi quelle extra dalla fine
        if (closeBraces > openBraces) {
            let removed = 0;
            while (closeBraces > openBraces && lines.length > 0) {
                if (lines[lines.length - 1].trim() === '}') {
                    lines.pop();
                    closeBraces--;
                    removed++;
                } else {
                    break;
                }
            }
            
            if (removed > 0) {
                this.fixes.push(`LunaComicsFT: Rimosse ${removed} parentesi } extra`);
            }
        }
        
        // Verifica specificamente la riga 105
        if (lines[104] && lines[104].trim() === '}') {
            // Controlla se questa parentesi è necessaria
            let braceCount = 0;
            for (let i = 0; i < 104; i++) {
                if (lines[i].includes('{')) braceCount++;
                if (lines[i].includes('}')) braceCount--;
            }
            
            // Se abbiamo già parentesi bilanciate, rimuovi questa
            if (braceCount <= 0) {
                lines.splice(104, 1);
                this.fixes.push('LunaComicsFT: Rimossa parentesi } extra alla riga 105');
            }
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    async fixAll() {
        console.log('🔧 CORREZIONE ULTIMI ERRORI...\n');

        // Esegui tutte le correzioni
        this.fixEnhancedModuleRouter();
        this.fixLunaComicsFT();

        console.log('\n📊 RIEPILOGO CORREZIONI:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ✅ ${index + 1}. ${fix}`);
            });
        } else {
            console.log('  ❌ Nessuna correzione applicata');
        }

        console.log('\n🚀 PROVA LA COMPILAZIONE:');
        console.log('   npx hardhat compile');
    }
}

// Esegui
const fixer = new LatestErrorsFixer();
fixer.fixAll().catch(console.error);
