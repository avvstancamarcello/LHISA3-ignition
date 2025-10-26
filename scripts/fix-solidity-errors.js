const { readFileSync, writeFileSync, existsSync } = require('fs');
const { join } = require('path');

class SolidityErrorFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter.sol - funzione incompleta
    fixEnhancedModuleRouter(content) {
        const lines = content.split('\n');
        let fixed = false;

        // Cerca l'ultima funzione prima della riga 395
        for (let i = 393; i >= 0; i--) {
            if (lines[i].includes('function') && !lines[i].includes(';')) {
                // Verifica se manca la parentesi di chiusura
                let openBraces = 0;
                let closeBraces = 0;
                
                for (let j = i; j < Math.min(i + 50, lines.length); j++) {
                    openBraces += (lines[j].match(/{/g) || []).length;
                    closeBraces += (lines[j].match(/}/g) || []).length;
                    
                    if (openBraces > 0 && openBraces === closeBraces) {
                        break;
                    }
                    
                    // Se arriviamo alla fine senza parentesi bilanciate
                    if (j === Math.min(i + 50, lines.length) - 1 && openBraces !== closeBraces) {
                        // Aggiungi parentesi di chiusura
                        lines.splice(j + 1, 0, '    }');
                        fixed = true;
                        this.fixes.push('EnhancedModuleRouter: Aggiunta parentesi mancante');
                        break;
                    }
                }
                break;
            }
        }

        return fixed ? lines.join('\n') : content;
    }

    // Correggi MareaMangaNFT.sol - chiamata funzione fuori posto
    fixMareaMangaNFT(content) {
        if (content.includes('_deployCompleteFleet();')) {
            // Sposta la chiamata dentro una funzione
            const fixedContent = content.replace(
                /_deployCompleteFleet\(\);[\s]*$/,
                '    function initializeFleet() external onlyOwner {\n        _deployCompleteFleet();\n    }'
            );
            
            if (fixedContent !== content) {
                this.fixes.push('MareaMangaNFT: Spostata _deployCompleteFleet() in funzione dedicata');
                return fixedContent;
            }
        }
        return content;
    }

    // Correggi LunaComicsFT.sol - variabili in contesto sbagliato
    fixLunaComicsFT(content) {
        const lines = content.split('\n');
        let fixed = false;

        // Cerca parentesi mancanti prima della riga 232
        for (let i = 230; i >= 0; i--) {
            if (lines[i].trim().includes('function') || lines[i].trim().includes('modifier')) {
                let openBraces = 0;
                let closeBraces = 0;
                
                // Conta parentesi dalla funzione fino alla riga 232
                for (let j = i; j < 232; j++) {
                    openBraces += (lines[j].match(/{/g) || []).length;
                    closeBraces += (lines[j].match(/}/g) || []).length;
                }

                // Se ci sono più { che }, aggiungi parentesi mancante
                if (openBraces > closeBraces) {
                    lines.splice(231, 0, '    }');
                    fixed = true;
                    this.fixes.push('LunaComicsFT: Aggiunta parentesi mancante prima delle variabili');
                    break;
                }
            }
        }

        return fixed ? lines.join('\n') : content;
    }

    // Correggi SolidaryOrchestrator.sol - codice JavaScript nel Solidity
    fixSolidaryOrchestrator(content) {
        // Rimuovi righe JavaScript
        const fixedContent = content
            .replace(/await contract\.setIPFSBaseURI\([^)]+\);[\s]*SET BASE URI/g, '')
            .replace(/^\/\/.*JavaScript.*$/gm, '')
            .trim();

        if (fixedContent !== content.trim()) {
            this.fixes.push('SolidaryOrchestrator: Rimosso codice JavaScript');
            return fixedContent;
        }
        return content;
    }

    // Applica tutte le correzioni
    async fixAll() {
        const contracts = [
            {
                path: 'contracts/core_infrastructure/EnhancedModuleRouter.sol',
                fix: this.fixEnhancedModuleRouter.bind(this)
            },
            {
                path: 'contracts/planetary/MareaMangaNFT.sol', 
                fix: this.fixMareaMangaNFT.bind(this)
            },
            {
                path: 'contracts/satellites/LunaComicsFT.sol',
                fix: this.fixLunaComicsFT.bind(this)
            },
            {
                path: 'contracts/stellar/SolidaryOrchestrator.sol',
                fix: this.fixSolidaryOrchestrator.bind(this)
            }
        ];

        console.log('🔧 INIZIO CORREZIONE ERRORI SOLIDITY...\n');

        for (const contract of contracts) {
            if (existsSync(contract.path)) {
                try {
                    const content = readFileSync(contract.path, 'utf8');
                    const fixedContent = contract.fix(content);
                    
                    if (fixedContent !== content) {
                        writeFileSync(contract.path, fixedContent);
                        console.log(`✅ ${contract.path} - CORRETTO`);
                    } else {
                        console.log(`ℹ️  ${contract.path} - Nessuna modifica necessaria`);
                    }
                } catch (error) {
                    console.log(`❌ ${contract.path} - Errore: ${error.message}`);
                }
            } else {
                console.log(`⚠️  ${contract.path} - File non trovato`);
            }
        }

        console.log('\n📊 RIEPILOGO CORREZIONI:');
        this.fixes.forEach((fix, index) => {
            console.log(`  ${index + 1}. ${fix}`);
        });

        if (this.fixes.length > 0) {
            console.log('\n🎯 ESECUZIONE COMPLETATA! Prova ora: npx hardhat compile');
        } else {
            console.log('\n✅ Nessun errore da correggere!');
        }
    }
}

// Esegui le correzioni
const fixer = new SolidityErrorFixer();
fixer.fixAll().catch(console.error);
