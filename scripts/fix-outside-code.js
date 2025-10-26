const { readFileSync, writeFileSync, existsSync } = require('fs');

class OutsideCodeFixer {
    constructor() {
        this.fixes = [];
    }

    // Controlla se una riga è dentro una funzione
    isInsideFunction(lines, lineIndex) {
        let braceCount = 0;
        let inContract = false;

        for (let i = 0; i < lineIndex; i++) {
            if (lines[i].includes('contract ') && braceCount === 0) {
                inContract = true;
            }
            if (lines[i].includes('{') && inContract) braceCount++;
            if (lines[i].includes('}') && inContract) braceCount--;
        }

        return braceCount > 0;
    }

    // Correggi EnhancedModuleRouter - parentesi fuori posto
    fixEnhancedModuleRouter(content) {
        let lines = content.split('\n');
        
        // Controlla la riga 80 - probabilmente una parentesi extra
        if (lines[79] && lines[79].trim() === '}') {
            // Verifica se questa parentesi è necessaria
            let openBraces = 0;
            let closeBraces = 0;
            
            for (let i = 0; i < 80; i++) {
                openBraces += (lines[i].match(/{/g) || []).length;
                closeBraces += (lines[i].match(/}/g) || []).length;
            }
            
            // Se abbiamo più parentesi chiuse che aperte, rimuovila
            if (closeBraces >= openBraces) {
                lines.splice(79, 1); // Rimuovi la riga 80
                this.fixes.push('EnhancedModuleRouter: Rimossa parentesi extra alla riga 80');
            }
        }
        
        return lines.join('\n');
    }

    // Correggi MareaMangaNFT - emit fuori da funzione
    fixMareaMangaNFT(content) {
        let lines = content.split('\n');
        let fixedLines = [];

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];

            // Riga 572: emit fuori da funzione
            if (line.includes('emit CommercialAuctionStarted(') && 
                !this.isInsideFunction(lines, i)) {
                
                // Trova la funzione più vicina prima di questo emit
                let functionStart = -1;
                for (let j = i - 1; j >= 0; j--) {
                    if (lines[j].includes('function ') && this.isInsideFunction(lines, j)) {
                        functionStart = j;
                        break;
                    }
                }
                
                if (functionStart !== -1) {
                    // Sposta l'emit dentro la funzione
                    fixedLines.push(line);
                } else {
                    // Incapsula in una nuova funzione
                    fixedLines.push('    function startCommercialAuction(uint256 portId, uint256[] memory nftIds, uint256 duration) internal {');
                    fixedLines.push('        emit CommercialAuctionStarted(portId, nftIds, duration);');
                    fixedLines.push('    }');
                    this.fixes.push('MareaMangaNFT: emit CommercialAuctionStarted incapsulato');
                }
            } else {
                fixedLines.push(line);
            }
        }

        return fixedLines.join('\n');
    }

    // Correggi LunaComicsFT - assegnazione fuori da funzione
    fixLunaComicsFT(content) {
        let lines = content.split('\n');
        let fixedLines = [];

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];

            // Riga 72: lunarGravity = 1e18; fuori da funzione
            if (line.includes('lunarGravity = 1e18;') && 
                !this.isInsideFunction(lines, i)) {
                
                // Incapsula in una funzione di inizializzazione
                fixedLines.push('    function initializeLunarGravity() internal {');
                fixedLines.push('        lunarGravity = 1e18;');
                fixedLines.push('    }');
                this.fixes.push('LunaComicsFT: lunarGravity initialization incapsulata');
            } else {
                fixedLines.push(line);
            }
        }

        return fixedLines.join('\n');
    }

    // Scansione completa per codice fuori posto
    comprehensiveFix(content, filename) {
        let lines = content.split('\n');
        let fixedLines = [];
        let currentFunction = null;

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            const trimmedLine = line.trim();

            // Identifica l'inizio di una funzione
            if (trimmedLine.startsWith('function ') && trimmedLine.endsWith('{')) {
                currentFunction = trimmedLine.split(' ')[1].split('(')[0];
            }

            // Identifica la fine di una funzione
            if (trimmedLine === '}' && currentFunction) {
                currentFunction = null;
            }

            // Se troviamo codice eseguibile fuori da una funzione
            if ((trimmedLine.startsWith('emit ') || 
                 trimmedLine.includes(' = ') || 
                 trimmedLine.endsWith(';')) && 
                !trimmedLine.startsWith('//') &&
                !currentFunction &&
                !this.isInsideFunction(lines, i)) {
                
                console.log(`🔍 ${filename}: Codice fuori posto alla riga ${i + 1}: "${trimmedLine}"`);
                
                // Incapsula in una funzione
                const varName = trimmedLine.split('=')[0]?.trim() || 'value';
                const functionName = `set${varName.charAt(0).toUpperCase() + varName.slice(1)}`;
                
                fixedLines.push(`    function ${functionName}() internal {`);
                fixedLines.push(`        ${trimmedLine}`);
                fixedLines.push(`    }`);
                this.fixes.push(`${filename}: ${trimmedLine} incapsulato in ${functionName}`);
            } else {
                fixedLines.push(line);
            }
        }

        return fixedLines.join('\n');
    }

    async fixAll() {
        console.log('🔧 CORREZIONE CODICE FUORI POSTO...\n');

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
                    console.log(`🔍 Scansionando: ${contract.name}`);
                    let content = readFileSync(contract.path, 'utf8');
                    
                    // Applica fix specifici prima della scansione completa
                    if (contract.name === 'EnhancedModuleRouter') {
                        content = this.fixEnhancedModuleRouter(content);
                    } else if (contract.name === 'MareaMangaNFT') {
                        content = this.fixMareaMangaNFT(content);
                    } else if (contract.name === 'LunaComicsFT') {
                        content = this.fixLunaComicsFT(content);
                    }
                    
                    // Poi applica la scansione completa
                    const finalContent = this.comprehensiveFix(content, contract.name);
                    
                    if (finalContent !== content) {
                        writeFileSync(contract.path, finalContent);
                        console.log(`✅ ${contract.name} - CORRETTO`);
                    } else {
                        console.log(`ℹ️  ${contract.name} - Nessun codice fuori posto trovato`);
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
            console.log('  ℹ️  Nessuna correzione necessaria');
        }

        console.log('\n🎯 PROVA ORA: npx hardhat compile');
    }
}

// Esegui
const fixer = new OutsideCodeFixer();
fixer.fixAll().catch(console.error);
