const { readFileSync, writeFileSync, existsSync } = require('fs');

class LastErrorFixer {
    constructor() {
        this.fixes = [];
    }

    // Analisi più approfondita - il problema potrebbe essere prima di queste funzioni
    fixEnhancedModuleRouter(content) {
        let lines = content.split('\n');
        let fixed = false;

        // Cerca la riga 75 e analizza il contesto
        for (let i = 0; i < lines.length; i++) {
            if (i === 74) { // Righe sono 0-based, quindi 74 = riga 75
                console.log(`🔍 EnhancedModuleRouter riga 75: "${lines[i]}"`);
                
                // Il problema potrebbe essere una parentesi o punto e virgola mancante PRIMA
                if (i > 0) {
                    const previousLine = lines[i - 1];
                    if (!previousLine.trim().endsWith(';') && !previousLine.trim().endsWith('}') && 
                        !previousLine.trim().endsWith('{') && previousLine.trim() !== '') {
                        // Aggiungi punto e virgola alla riga precedente
                        lines[i - 1] = lines[i - 1] + ';';
                        fixed = true;
                        this.fixes.push('EnhancedModuleRouter: Aggiunto ; alla riga precedente');
                    }
                }
            }
        }

        return fixed ? lines.join('\n') : content;
    }

    fixMareaMangaNFT(content) {
        let lines = content.split('\n');
        let fixed = false;

        // Cerca _registerDefaultGameUniverses();
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].includes('_registerDefaultGameUniverses();')) {
                console.log(`🔍 MareaMangaNFT trovato a riga ${i + 1}: "${lines[i]}"`);
                
                // Verifica se è dentro una funzione guardando le parentesi
                let braceCount = 0;
                let functionFound = false;
                
                for (let j = 0; j < i; j++) {
                    if (lines[j].includes('{')) braceCount++;
                    if (lines[j].includes('}')) braceCount--;
                    if (lines[j].includes('function') && braceCount === 0) {
                        functionFound = true;
                    }
                }
                
                if (!functionFound || braceCount <= 0) {
                    // Non è dentro una funzione valida - incapsula
                    lines[i] = `    function registerDefaultGameUniverses() external onlyOwner {\n        _registerDefaultGameUniverses();\n    }`;
                    fixed = true;
                    this.fixes.push('MareaMangaNFT: _registerDefaultGameUniverses() incapsulata');
                }
                break;
            }
        }

        return fixed ? lines.join('\n') : content;
    }

    fixLunaComicsFT(content) {
        // Stesso approccio di EnhancedModuleRouter
        let lines = content.split('\n');
        let fixed = false;

        for (let i = 0; i < lines.length; i++) {
            if (i === 60) { // Righe sono 0-based, quindi 60 = riga 61
                console.log(`🔍 LunaComicsFT riga 61: "${lines[i]}"`);
                
                // Controlla la riga precedente
                if (i > 0) {
                    const previousLine = lines[i - 1];
                    if (!previousLine.trim().endsWith(';') && !previousLine.trim().endsWith('}') && 
                        !previousLine.trim().endsWith('{') && previousLine.trim() !== '') {
                        lines[i - 1] = lines[i - 1] + ';';
                        fixed = true;
                        this.fixes.push('LunaComicsFT: Aggiunto ; alla riga precedente');
                    }
                }
            }
        }

        return fixed ? lines.join('\n') : content;
    }

    // Metodo AGGRESSIVO - se i metodi precisi non funzionano
    fixAggressive(content, filename) {
        let lines = content.split('\n');
        let fixed = false;

        // Cerca pattern specifici che causano errori
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            
            // Pattern 1: Funzione che inizia ma ha errori di parsing
            if (line.startsWith('function') && line.includes('external') && !line.includes('(')) {
                // Ricostruisci la riga della funzione
                const functionName = line.split(' ')[1];
                lines[i] = `    function ${functionName}() external onlyOwner {`;
                fixed = true;
                this.fixes.push(`${filename}: Ricostruita funzione ${functionName}`);
            }
            
            // Pattern 2: Chiamate funzione fuori contesto
            if (line.endsWith('();') && !line.startsWith('function') && !line.startsWith('//') && 
                !line.includes('=') && !line.includes('return')) {
                
                const callName = line.replace('();', '').trim();
                lines[i] = `    function ${callName.replace('_', '')}() external onlyOwner {\n        ${line}\n    }`;
                fixed = true;
                this.fixes.push(`${filename}: Incapsulata ${callName}()`);
            }
        }

        return fixed ? lines.join('\n') : content;
    }

    async fixAll() {
        console.log('🔧 CORREZIONE ULTIMI ERRORI...\n');

        const contracts = [
            {
                path: 'contracts/core_infrastructure/EnhancedModuleRouter.sol',
                name: 'EnhancedModuleRouter'
            },
            {
                path: 'contracts/planetary/MareaMangaNFT.sol',
                name: 'MareaMangaNFT'
            },
            {
                path: 'contracts/satellites/LunaComicsFT.sol', 
                name: 'LunaComicsFT'
            }
        ];

        for (const contract of contracts) {
            if (existsSync(contract.path)) {
                try {
                    let content = readFileSync(contract.path, 'utf8');
                    console.log(`\n📖 Analizzando: ${contract.path}`);
                    
                    // Prima prova i fix precisi
                    let fixedContent = content;
                    if (contract.name === 'EnhancedModuleRouter') {
                        fixedContent = this.fixEnhancedModuleRouter(content);
                    } else if (contract.name === 'MareaMangaNFT') {
                        fixedContent = this.fixMareaMangaNFT(content);
                    } else if (contract.name === 'LunaComicsFT') {
                        fixedContent = this.fixLunaComicsFT(content);
                    }
                    
                    // Se i fix precisi non funzionano, usa quello aggressivo
                    if (fixedContent === content) {
                        fixedContent = this.fixAggressive(content, contract.name);
                    }
                    
                    if (fixedContent !== content) {
                        writeFileSync(contract.path, fixedContent);
                        console.log(`✅ ${contract.path} - CORRETTO`);
                    } else {
                        console.log(`❌ ${contract.path} - Impossibile correggere automaticamente`);
                        console.log(`   💡 Controlla manualmente le righe indicate`);
                    }
                } catch (error) {
                    console.log(`💥 ${contract.path} - Errore: ${error.message}`);
                }
            }
        }

        console.log('\n📊 RIEPILOGO CORREZIONI:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ${index + 1}. ${fix}`);
            });
        } else {
            console.log('  ❌ Nessuna correzione applicata');
        }

        console.log('\n🎯 PROVA ORA: npx hardhat compile');
    }
}

// Esegui
const fixer = new LastErrorFixer();
fixer.fixAll().catch(console.error);
