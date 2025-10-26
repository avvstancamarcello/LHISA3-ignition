const { readFileSync, writeFileSync, existsSync } = require('fs');
const { join } = require('path');

class SolidityErrorFixer {
    constructor() {
        this.fixes = [];
    }

    // Analisi più approfondita per EnhancedModuleRouter
    fixEnhancedModuleRouter(content) {
        let lines = content.split('\n');
        let fixedContent = content;
        let fixed = false;

        // CERCA: Funzione incompleta alla fine del file
        if (lines.length > 394 && lines[394].trim() === '') {
            // Controlla se l'ultima funzione non è chiusa
            let lastFunctionIndex = -1;
            for (let i = lines.length - 1; i >= 0; i--) {
                if (lines[i].includes('function') && !lines[i].includes(';')) {
                    lastFunctionIndex = i;
                    break;
                }
            }

            if (lastFunctionIndex !== -1) {
                // Conta le parentesi dalla funzione in poi
                let openBraces = 0;
                let closeBraces = 0;
                for (let i = lastFunctionIndex; i < lines.length; i++) {
                    openBraces += (lines[i].match(/{/g) || []).length;
                    closeBraces += (lines[i].match(/}/g) || []).length;
                }

                if (openBraces > closeBraces) {
                    // Aggiungi parentesi di chiusura alla fine
                    lines.push('}');
                    fixed = true;
                    this.fixes.push('EnhancedModuleRouter: Aggiunta parentesi finale mancante');
                }
            }
        }

        // CORREGGI: Se manca completamente la parentesi di una funzione
        const functionRegex = /function\s+\w+\s*\([^)]*\)[^{]*{/g;
        let match;
        while ((match = functionRegex.exec(content)) !== null) {
            const startIndex = match.index;
            const functionStartLine = content.substring(0, startIndex).split('\n').length - 1;
            
            // Controlla se questa funzione ha parentesi bilanciate
            let braceCount = 1;
            let currentIndex = startIndex + match[0].length;
            
            while (braceCount > 0 && currentIndex < content.length) {
                if (content[currentIndex] === '{') braceCount++;
                if (content[currentIndex] === '}') braceCount--;
                currentIndex++;
            }
            
            if (braceCount > 0) {
                // Funzione non chiusa - aggiungi parentesi
                const insertPosition = content.lastIndexOf('\n', startIndex);
                fixedContent = fixedContent + '\n}';
                fixed = true;
                this.fixes.push('EnhancedModuleRouter: Funzione non chiusa corretta');
                break;
            }
        }

        return fixed ? lines.join('\n') : fixedContent;
    }

    // CORREZIONE AGGRESSIVA per MareaMangaNFT
    fixMareaMangaNFT(content) {
        if (content.includes('_deployCompleteFleet();')) {
            // CERCA la posizione esatta
            const deployLineIndex = content.indexOf('_deployCompleteFleet();');
            
            if (deployLineIndex !== -1) {
                // Controlla il contesto - se non è dentro una funzione
                const beforeCode = content.substring(0, deployLineIndex);
                const lastBrace = beforeCode.lastIndexOf('}');
                const lastFunction = beforeCode.lastIndexOf('function');
                
                if (lastBrace > lastFunction) {
                    // La chiamata è fuori da qualsiasi funzione
                    const fixedContent = content.replace(
                        '_deployCompleteFleet();',
                        'function deployFleet() external onlyOwner {\n        _deployCompleteFleet();\n    }'
                    );
                    this.fixes.push('MareaMangaNFT: _deployCompleteFleet() incapsulata in funzione');
                    return fixedContent;
                }
            }
        }
        return content;
    }

    // CORREZIONE DETTAGLIATA per LunaComicsFT
    fixLunaComicsFT(content) {
        const lines = content.split('\n');
        let fixed = false;

        // CERCA la riga specifica con l'errore
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].includes('string public pinataJWT;')) {
                // Analizza le righe precedenti per trovare la funzione non chiusa
                for (let j = i - 1; j >= 0; j--) {
                    if (lines[j].includes('function') || lines[j].includes('modifier')) {
                        // Controlla se questa funzione/modifier è chiusa
                        let openBraces = 0;
                        let closeBraces = 0;
                        
                        for (let k = j; k < i; k++) {
                            openBraces += (lines[k].match(/{/g) || []).length;
                            closeBraces += (lines[k].match(/}/g) || []).length;
                        }

                        if (openBraces > closeBraces) {
                            // Aggiungi parentesi di chiusura prima delle variabili
                            lines.splice(i, 0, '    }');
                            fixed = true;
                            this.fixes.push('LunaComicsFT: Parentesi aggiunta prima di pinataJWT');
                            break;
                        }
                    }
                }
                break;
            }
        }

        return fixed ? lines.join('\n') : content;
    }

    fixSolidaryOrchestrator(content) {
        // Rimuovi TUTTO il codice JavaScript
        const fixedContent = content
            .replace(/await contract\.[^;]+;/g, '')
            .replace(/SET BASE URI/g, '')
            .replace(/^.*JavaScript.*$/gm, '')
            .replace(/\n\s*\n\s*\n/g, '\n\n') // Rimuovi righe vuote multiple
            .trim();

        if (fixedContent !== content.trim()) {
            this.fixes.push('SolidaryOrchestrator: Codice JavaScript rimosso');
            return fixedContent + '\n';
        }
        return content;
    }

    // METODO DI FALLBACK - se le correzioni specifiche non funzionano
    applyAggressiveFixes(content, filename) {
        let lines = content.split('\n');
        let fixed = false;

        // CORREGGI: Chiamate funzione fuori contesto
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            
            // Se trova una chiamata funzione fuori posto
            if (line.endsWith('();') && !line.startsWith('function') && 
                !line.startsWith('//') && !line.startsWith('*') && 
                line !== '' && !line.includes('=') && !line.includes('return')) {
                
                // Incapsula in una funzione
                const functionName = line.split('(')[0].replace('_', '');
                lines[i] = `    function ${functionName}() external onlyOwner {\n        ${line}\n    }`;
                fixed = true;
                this.fixes.push(`${filename}: ${line} incapsulata in funzione`);
            }
        }

        return fixed ? lines.join('\n') : content;
    }

    async fixAll() {
        const contracts = [
            {
                path: 'contracts/core_infrastructure/EnhancedModuleRouter.sol',
                fix: (content) => {
                    const fixed = this.fixEnhancedModuleRouter(content);
                    return fixed !== content ? fixed : this.applyAggressiveFixes(content, 'EnhancedModuleRouter');
                }
            },
            {
                path: 'contracts/planetary/MareaMangaNFT.sol', 
                fix: (content) => {
                    const fixed = this.fixMareaMangaNFT(content);
                    return fixed !== content ? fixed : this.applyAggressiveFixes(content, 'MareaMangaNFT');
                }
            },
            {
                path: 'contracts/satellites/LunaComicsFT.sol',
                fix: (content) => {
                    const fixed = this.fixLunaComicsFT(content);
                    return fixed !== content ? fixed : this.applyAggressiveFixes(content, 'LunaComicsFT');
                }
            },
            {
                path: 'contracts/stellar/SolidaryOrchestrator.sol',
                fix: this.fixSolidaryOrchestrator.bind(this)
            }
        ];

        console.log('🔧 INIZIO CORREZIONE AGGRESSIVA ERRORI SOLIDITY...\n');

        for (const contract of contracts) {
            if (existsSync(contract.path)) {
                try {
                    let content = readFileSync(contract.path, 'utf8');
                    console.log(`📖 Analizzando: ${contract.path}`);
                    
                    const originalContent = content;
                    content = contract.fix(content);
                    
                    if (content !== originalContent) {
                        writeFileSync(contract.path, content);
                        console.log(`✅ ${contract.path} - MODIFICATO`);
                    } else {
                        console.log(`❌ ${contract.path} - Impossibile correggere automaticamente`);
                        console.log(`   🔍 Controlla manualmente il codice attorno alle righe indicate negli errori`);
                    }
                } catch (error) {
                    console.log(`💥 ${contract.path} - Errore: ${error.message}`);
                }
            } else {
                console.log(`⚠️  ${contract.path} - File non trovato`);
            }
        }

        console.log('\n📊 RIEPILOGO CORREZIONI:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ${index + 1}. ${fix}`);
            });
            console.log('\n🎯 PROVA ORA: npx hardhat compile');
        } else {
            console.log('  ❌ Nessuna correzione applicata - gli errori sono troppo specifici');
            console.log('\n💡 SUGGERIMENTO: Condividi il codice delle righe problematiche per una correzione manuale');
        }
    }
}

// Esegui
const fixer = new SolidityErrorFixer();
fixer.fixAll().catch(console.error);
