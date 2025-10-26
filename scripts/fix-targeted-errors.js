const { readFileSync, writeFileSync, existsSync } = require('fs');

class TargetedErrorFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - parentesi extra
    fixEnhancedModuleRouter(content) {
        const lines = content.split('\n');
        
        // Controlla la riga 82 - parentesi extra
        if (lines[81] && lines[81].trim() === '}') {
            // Verifica se questa parentesi è necessaria contando tutte le parentesi
            let openBraces = 0;
            let closeBraces = 0;
            
            for (let i = 0; i < lines.length; i++) {
                openBraces += (lines[i].match(/{/g) || []).length;
                closeBraces += (lines[i].match(/}/g) || []).length;
            }
            
            // Se abbiamo più parentesi chiuse che aperte, rimuovila
            if (closeBraces > openBraces) {
                lines.splice(81, 1); // Rimuovi la riga 82
                this.fixes.push('EnhancedModuleRouter: Rimossa parentesi extra alla riga 82');
                return lines.join('\n');
            }
        }
        
        return content;
    }

    // Correggi MareaMangaNFT - emit fuori da funzione
    fixMareaMangaNFT(content) {
        const lines = content.split('\n');
        let fixedLines = [];
        let inFunction = false;
        let functionBraces = 0;

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            const trimmed = line.trim();

            // Controlla se siamo in una funzione
            if (trimmed.startsWith('function ') && trimmed.endsWith('{')) {
                inFunction = true;
                functionBraces = 1;
            } else if (inFunction) {
                if (trimmed.includes('{')) functionBraces++;
                if (trimmed.includes('}')) functionBraces--;
                if (functionBraces === 0) inFunction = false;
            }

            // Riga 562: emit fuori da funzione
            if (i === 561 && trimmed.startsWith('emit CommercialAuctionStarted(') && !inFunction) {
                // Trova la funzione più vicina prima di questo emit
                let foundFunction = false;
                for (let j = i - 1; j >= 0; j--) {
                    if (lines[j].trim().startsWith('function ')) {
                        // Incapsula l'emit nella funzione esistente
                        const functionLine = lines[j];
                        const functionName = functionLine.trim().split(' ')[1].split('(')[0];
                        
                        fixedLines.push(line);
                        this.fixes.push(`MareaMangaNFT: emit CommercialAuctionStarted spostato nella funzione ${functionName}`);
                        foundFunction = true;
                        break;
                    }
                }
                
                if (!foundFunction) {
                    // Crea una nuova funzione per l'emit
                    fixedLines.push('    function _startCommercialAuction(uint256 portId, uint256[] memory nftIds, uint256 duration) internal {');
                    fixedLines.push('        emit CommercialAuctionStarted(portId, nftIds, duration);');
                    fixedLines.push('    }');
                    this.fixes.push('MareaMangaNFT: emit CommercialAuctionStarted incapsulato in _startCommercialAuction');
                }
            } else {
                fixedLines.push(line);
            }
        }

        return fixedLines.join('\n');
    }

    // Correggi LunaComicsFT - assegnazione fuori da funzione
    fixLunaComicsFT(content) {
        const lines = content.split('\n');
        let fixedLines = [];
        let inFunction = false;
        let functionBraces = 0;

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            const trimmed = line.trim();

            // Controlla se siamo in una funzione
            if (trimmed.startsWith('function ') && trimmed.endsWith('{')) {
                inFunction = true;
                functionBraces = 1;
            } else if (inFunction) {
                if (trimmed.includes('{')) functionBraces++;
                if (trimmed.includes('}')) functionBraces--;
                if (functionBraces === 0) inFunction = false;
            }

            // Riga 66: lunarGravity = 1e18; fuori da funzione
            if (i === 65 && trimmed === 'lunarGravity = 1e18;' && !inFunction) {
                // Trova la funzione initialize più vicina
                let foundInitialize = false;
                for (let j = i - 1; j >= 0; j--) {
                    if (lines[j].trim().startsWith('function initialize(') || 
                        lines[j].trim().startsWith('function initialize()')) {
                        // Aggiungi l'assegnazione alla funzione initialize
                        fixedLines.push('        lunarGravity = 1e18;');
                        this.fixes.push('LunaComicsFT: lunarGravity initialization spostata in initialize()');
                        foundInitialize = true;
                        break;
                    }
                }
                
                if (!foundInitialize) {
                    // Crea una funzione di inizializzazione
                    fixedLines.push('    function _initializeLunarGravity() internal {');
                    fixedLines.push('        lunarGravity = 1e18;');
                    fixedLines.push('    }');
                    this.fixes.push('LunaComicsFT: lunarGravity initialization incapsulata in _initializeLunarGravity');
                }
            } else {
                fixedLines.push(line);
            }
        }

        return fixedLines.join('\n');
    }

    // Metodo per verificare se una riga è dentro una funzione
    isInsideFunction(lines, lineIndex) {
        let braceCount = 0;
        let inContract = false;

        for (let i = 0; i < lineIndex; i++) {
            if (lines[i].includes('contract ') && braceCount === 0) {
                inContract = true;
                braceCount++;
            } else if (inContract) {
                if (lines[i].includes('{')) braceCount++;
                if (lines[i].includes('}')) braceCount--;
            }
        }

        return braceCount > 1; // >1 perché il contratto stesso ha già una parentesi
    }

    async fixAll() {
        console.log('🔧 CORREZIONE ERRORI MIRATA...\n');

        const contracts = [
            {
                path: 'contracts/core_infrastructure/EnhancedModuleRouter.sol',
                fix: this.fixEnhancedModuleRouter.bind(this),
                name: 'EnhancedModuleRouter'
            },
            {
                path: 'contracts/planetary/MareaMangaNFT.sol',
                fix: this.fixMareaMangaNFT.bind(this),
                name: 'MareaMangaNFT'
            },
            {
                path: 'contracts/satellites/LunaComicsFT.sol',
                fix: this.fixLunaComicsFT.bind(this),
                name: 'LunaComicsFT'
            }
        ];

        for (const contract of contracts) {
            if (existsSync(contract.path)) {
                try {
                    console.log(`🔧 Correggendo: ${contract.name}`);
                    const content = readFileSync(contract.path, 'utf8');
                    const fixedContent = contract.fix(content);
                    
                    if (fixedContent !== content) {
                        writeFileSync(contract.path, fixedContent);
                        console.log(`✅ ${contract.name} - CORRETTO`);
                    } else {
                        console.log(`ℹ️  ${contract.name} - Nessuna modifica necessaria`);
                    }
                } catch (error) {
                    console.log(`❌ ${contract.name} - Errore: ${error.message}`);
                }
            }
        }

        console.log('\n📊 RIEPILOGO CORREZIONI:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ${index + 1}. ${fix}`);
            });
        } else {
            console.log('  ℹ️  Nessuna correzione applicata');
        }

        console.log('\n🎯 PROVA ORA: npx hardhat compile');
        
        if (this.fixes.length === 0) {
            console.log('\n💡 Per correggere manualmente:');
            console.log('   EnhancedModuleRouter.sol - Rimuovi parentesi extra alla riga 82');
            console.log('   MareaMangaNFT.sol - Sposta emit CommercialAuctionStarted dentro una funzione');
            console.log('   LunaComicsFT.sol - Sposta lunarGravity = 1e18; dentro una funzione');
        }
    }
}

// Esegui
const fixer = new TargetedErrorFixer();
fixer.fixAll().catch(console.error);
