const { readFileSync, writeFileSync, existsSync } = require('fs');

class DiagnosedErrorsFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - encodeWithSignature non chiuso
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // CHIUDI encodeWithSignature alla riga 207 (aggiungi ); dopo weight)
        if (lines[212] && lines[212].includes('weight') && !lines[212].includes(');')) {
            lines[212] = lines[212] + ');';
            this.fixes.push('EnhancedModuleRouter: Chiuso encodeWithSignature con ); dopo weight');
        }
        
        // AGGIUNGI il corpo della funzione dopo encodeWithSignature
        if (lines[212] && lines[212].includes('weight);') && lines[213].trim() === '' && lines[214].trim() === '}') {
            lines[213] = '';
            lines[214] = '        (success, ) = executeRoute("reputation_update", payload);';
            lines[215] = '        return success;';
            // La riga 216 rimane come }
            
            this.fixes.push('EnhancedModuleRouter: Aggiunto corpo funzione updateReputation');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi LunaComicsFT - funzione malformata e parentesi extra
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // CORREGGI la funzione malformata alla riga 177
        if (lines[176] && lines[176].includes('function userFarmsArray.pop()')) {
            // Cambia in una funzione normale
            lines[176] = '    function popLastUserFarm() external onlyOwner {';
            this.fixes.push('LunaComicsFT: Corretta funzione userFarmsArray.pop() -> popLastUserFarm()');
        }
        
        // RIMUOVI parentesi extra alla riga 180
        if (lines[179] && lines[179].trim() === '}') {
            lines.splice(179, 1); // Rimuovi la riga 180
            this.fixes.push('LunaComicsFT: Rimossa parentesi } extra alla riga 180');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    async fixAll() {
        console.log('🎯 CORREZIONE ERRORI DIAGNOSTICATI...\n');

        // Esegui tutte le correzioni
        this.fixEnhancedModuleRouter();
        this.fixLunaComicsFT();

        console.log('\n📊 RIEPILOGO CORREZIONI:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ✅ ${index + 1}. ${fix}`);
            });
            
            console.log('\n🎉 ERRORI DIAGNOSTICATI RISOLTI!');
        } else {
            console.log('  ❌ Nessuna correzione applicata');
        }

        console.log('\n🚀 PROVA LA COMPILAZIONE:');
        console.log('   npx hardhat compile');
    }
}

// Esegui
const fixer = new DiagnosedErrorsFixer();
fixer.fixAll().catch(console.error);
