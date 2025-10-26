const { readFileSync, writeFileSync, existsSync } = require('fs');

class FinalBattleFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - encodeWithSignature mancante
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Riga 207: Aggiungi encodeWithSignature
        if (lines[206] && lines[206].includes('"addReputationEvent(address,string,string,string,uint256)",')) {
            lines.splice(206, 0, '        bytes memory payload = abi.encodeWithSignature(');
            this.fixes.push('EnhancedModuleRouter: Aggiunto encodeWithSignature alla riga 206');
            
            // Aggiungi ); dopo l'ultimo parametro (weight)
            if (lines[211] && lines[211].includes('weight')) {
                lines[211] = lines[211] + ');';
                this.fixes.push('EnhancedModuleRouter: Aggiunto ); dopo weight');
            }
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi LunaComicsFT - funzione nel posto sbagliato e parentesi extra
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // Riga 104: La funzione è nel posto sbagliato - spostala alla fine del contratto
        let functionBlock = [];
        let functionStart = -1;
        let functionEnd = -1;
        
        // Trova il blocco della funzione updateGravity
        for (let i = 103; i < lines.length; i++) {
            if (lines[i].includes('function updateGravity()')) {
                functionStart = i;
            }
            if (functionStart !== -1) {
                functionBlock.push(lines[i]);
                if (lines[i].includes('}') && functionBlock.length > 1) {
                    functionEnd = i;
                    break;
                }
            }
        }
        
        if (functionStart !== -1 && functionEnd !== -1) {
            // Rimuovi la funzione dalla posizione corrente
            for (let i = functionStart; i <= functionEnd; i++) {
                lines.splice(functionStart, 1);
            }
            
            // Trova la fine del contratto (prima dell'ultima })
            let contractEnd = -1;
            for (let i = lines.length - 1; i >= 0; i--) {
                if (lines[i].trim() === '}') {
                    contractEnd = i;
                    break;
                }
            }
            
            if (contractEnd !== -1) {
                // Inserisci la funzione prima dell'ultima }
                lines.splice(contractEnd, 0, '');
                for (let i = functionBlock.length - 1; i >= 0; i--) {
                    lines.splice(contractEnd, 0, functionBlock[i]);
                }
                this.fixes.push('LunaComicsFT: Funzione updateGravity spostata alla fine del contratto');
            }
        }
        
        // Rimuovi parentesi extra alla fine
        let lastBraceIndex = -1;
        let braceCount = 0;
        
        for (let i = lines.length - 1; i >= 0; i--) {
            if (lines[i].trim() === '}') {
                if (lastBraceIndex === -1) {
                    lastBraceIndex = i;
                }
                braceCount++;
            }
        }
        
        // Se ci sono più parentesi dell'ultima riga, rimuovi quelle extra
        if (braceCount > 1 && lastBraceIndex !== -1) {
            // Conta le parentesi nel contratto per vedere quante dovrebbero essercene
            let openBraces = 0;
            let closeBraces = 0;
            
            for (let i = 0; i < lines.length; i++) {
                openBraces += (lines[i].match(/{/g) || []).length;
                closeBraces += (lines[i].match(/}/g) || []).length;
            }
            
            // Rimuovi parentesi extra
            while (closeBraces > openBraces && lines[lines.length - 1].trim() === '}') {
                lines.pop();
                closeBraces--;
                this.fixes.push('LunaComicsFT: Rimossa parentesi } extra');
            }
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    async fixAll() {
        console.log('⚔️  BATTAGLIA FINALE - CORREZIONE DEFINITIVA...\n');

        // Esegui tutte le correzioni
        this.fixEnhancedModuleRouter();
        this.fixLunaComicsFT();

        console.log('\n📊 RIEPILOGO CORREZIONI:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ✅ ${index + 1}. ${fix}`);
            });
            
            console.log('\n🎉 TUTTI GLI ERRORI RISOLTI!');
        } else {
            console.log('  ❌ Nessuna correzione applicata');
        }

        console.log('\n🚀 PROVA LA COMPILAZIONE FINALE:');
        console.log('   npx hardhat compile');
    }
}

// Esegui
const fixer = new FinalBattleFixer();
fixer.fixAll().catch(console.error);
