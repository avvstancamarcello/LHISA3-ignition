const { readFileSync, writeFileSync, existsSync } = require('fs');

class FinalIssuesFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - rimuovi completamente la funzione malformata
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // CERCA e RIMUOVI la funzione malformata
        let malformedStart = -1;
        for (let i = 0; i < lines.length; i++) {
            if (lines[i] && lines[i].includes(') external view returns (')) {
                malformedStart = i;
                break;
            }
        }
        
        if (malformedStart !== -1) {
            // Trova dove finisce questa funzione malformata
            let malformedEnd = malformedStart;
            let braceCount = 0;
            
            for (let i = malformedStart; i < lines.length; i++) {
                if (lines[i].includes('{')) braceCount++;
                if (lines[i].includes('}')) braceCount--;
                if (braceCount === 0 && i > malformedStart) {
                    malformedEnd = i;
                    break;
                }
            }
            
            // RIMUOVI completamente la funzione malformata
            lines.splice(malformedStart, malformedEnd - malformedStart + 1);
            this.fixes.push('EnhancedModuleRouter: Rimossa completamente funzione malformata');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi LunaComicsFT - sistema definitivamente le parentesi
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // RIMUOVI COMPLETAMENTE le parentesi extra che corrompono tutto
        if (lines[246] && lines[246].includes('pinataJWT = jwt;') && 
            lines[247] && lines[247].trim() === '}' && 
            lines[248] && lines[248].trim() === '}') {
            
            // Rimuovi UNA parentesi per bilanciare
            lines.splice(247, 1); // Rimuovi riga 248
            this.fixes.push('LunaComicsFT: Sistemate parentesi extra');
        }
        
        // Verifica se la funzione è ancora fuori dal contratto
        let contractOpen = false;
        let braceCount = 0;
        
        for (let i = 0; i < 251; i++) {
            if (lines[i].includes('contract ') && braceCount === 0) {
                contractOpen = true;
                braceCount++;
            } else if (contractOpen) {
                if (lines[i].includes('{')) braceCount++;
                if (lines[i].includes('}')) braceCount--;
            }
        }
        
        console.log(`🔍 LunaComicsFT - Contratto aperto alla riga 251: ${braceCount > 0}`);
        
        // Se il contratto è chiuso, dobbiamo riaprirlo
        if (braceCount <= 0) {
            // Trova l'ultima parentesi } e rimuovila
            for (let i = 250; i >= 0; i--) {
                if (lines[i] && lines[i].trim() === '}') {
                    lines.splice(i, 1);
                    this.fixes.push('LunaComicsFT: Riaperto contratto - rimossa parentesi } di chiusura prematura');
                    break;
                }
            }
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    async fixAll() {
        console.log('🎯 CORREZIONE PROBLEMI FINALI...\n');

        // Esegui tutte le correzioni
        this.fixEnhancedModuleRouter();
        this.fixLunaComicsFT();

        console.log('\n📊 RIEPILOGO CORREZIONI:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ✅ ${index + 1}. ${fix}`);
            });
            
            console.log('\n🎉 PROBLEMI FINALI RISOLTI!');
        } else {
            console.log('  ❌ Nessuna correzione applicata');
        }

        console.log('\n🚀 PROVA LA COMPILAZIONE FINALE:');
        console.log('   npx hardhat compile');
    }
}

// Esegui
const fixer = new FinalIssuesFixer();
fixer.fixAll().catch(console.error);
