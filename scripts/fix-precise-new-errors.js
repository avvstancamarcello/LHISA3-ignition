const { readFileSync, writeFileSync, existsSync } = require('fs');

class PreciseNewErrorsFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - manca encodeWithSignature
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Riga 183: Aggiungi "bytes memory payload = abi.encodeWithSignature(" prima
        if (lines[182] && lines[182].includes('"logImpact(string,string,string,uint256,uint256,string,uint256,string)",')) {
            lines.splice(182, 0, '        bytes memory payload = abi.encodeWithSignature(');
            this.fixes.push('EnhancedModuleRouter: Aggiunto encodeWithSignature alla riga 182');
        }
        
        // Assicurati che encodeWithSignature sia chiuso correttamente
        let encodeOpen = -1;
        for (let i = 0; i < lines.length; i++) {
            if (lines[i] && lines[i].includes('abi.encodeWithSignature(')) {
                encodeOpen = i;
                break;
            }
        }
        
        if (encodeOpen !== -1) {
            // Trova e aggiungi la parentesi di chiusura dopo tutti i parametri
            let paramCount = 0;
            let foundClose = false;
            
            for (let i = encodeOpen + 1; i < Math.min(encodeOpen + 15, lines.length); i++) {
                if (lines[i] && lines[i].trim() && !lines[i].includes(')') && !foundClose) {
                    paramCount++;
                }
                if (lines[i] && lines[i].includes(');')) {
                    foundClose = true;
                    break;
                }
            }
            
            if (!foundClose) {
                // Trova l'ultimo parametro e aggiungi ); dopo
                for (let i = encodeOpen + 10; i >= encodeOpen + 1; i--) {
                    if (lines[i] && lines[i].trim() && !lines[i].includes(')')) {
                        lines[i] = lines[i] + ');';
                        this.fixes.push('EnhancedModuleRouter: Aggiunto ); alla fine di encodeWithSignature');
                        break;
                    }
                }
            }
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi LunaComicsFT - funzione duplicata
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Riga 104-105: Funzione updateGravity DUPLICATA
        if (lines[103] && lines[103].includes('function updateGravity() external onlyOwner {') &&
            lines[104] && lines[104].includes('function updateGravity() external onlyOwner {')) {
            
            // Rimuovi la riga 105 duplicata (la seconda occorrenza)
            lines.splice(104, 1);
            this.fixes.push('LunaComicsFT: Rimossa funzione updateGravity duplicata alla riga 105');
        }
        
        // Se la riga 104 non ha la parentesi, aggiungila
        if (lines[103] && lines[103].includes('function updateGravity() external onlyOwner') && 
            !lines[103].includes('{')) {
            lines[103] = lines[103] + ' {';
            this.fixes.push('LunaComicsFT: Aggiunta { alla funzione updateGravity');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    async fixAll() {
        console.log('🎯 CORREZIONE PRECISA NUOVI ERRORI...\n');

        // Esegui tutte le correzioni
        this.fixEnhancedModuleRouter();
        this.fixLunaComicsFT();

        console.log('\n📊 RIEPILOGO CORREZIONI:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ✅ ${index + 1}. ${fix}`);
            });
            
            console.log('\n🎉 ERRORI RISOLTI!');
            console.log('   EnhancedModuleRouter: encodeWithSignature completato');
            console.log('   LunaComicsFT: Funzione duplicata rimossa');
        } else {
            console.log('  ❌ Nessuna correzione applicata');
        }

        console.log('\n🚀 PROVA LA COMPILAZIONE:');
        console.log('   npx hardhat compile');
    }
}

// Esegui
const fixer = new PreciseNewErrorsFixer();
fixer.fixAll().catch(console.error);
