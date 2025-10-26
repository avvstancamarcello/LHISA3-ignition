const { readFileSync, writeFileSync, existsSync } = require('fs');

class FinalTouchFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - parentesi mancante
    fixEnhancedModuleRouter(content) {
        // Conta le parentesi per vedere se il contratto è chiuso correttamente
        const openBraces = (content.match(/{/g) || []).length;
        const closeBraces = (content.match(/}/g) || []).length;
        
        if (openBraces > closeBraces) {
            // Aggiungi parentesi di chiusura finale
            content += '\n}';
            this.fixes.push('EnhancedModuleRouter: Aggiunta parentesi finale mancante');
        }
        
        return content;
    }

    // Correggi MareaMangaNFT - codice fuori dalle funzioni
    fixMareaMangaNFT(content) {
        let lines = content.split('\n');
        let fixedLines = [];

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];

            // Riga 567: port.activeAuctions.push(auctionId); - probabilmente fuori contesto
            if (line.includes('port.activeAuctions.push(auctionId);') && 
                !this.isInsideFunction(lines, i)) {
                
                // Incapsula in una funzione
                fixedLines.push('    function addAuctionToPort(uint256 auctionId) internal {');
                fixedLines.push('        port.activeAuctions.push(auctionId);');
                fixedLines.push('    }');
                this.fixes.push('MareaMangaNFT: addAuctionToPort incapsulata correttamente');
                continue;
            }

            fixedLines.push(line);
        }

        return fixedLines.join('\n');
    }

    // Correggi LunaComicsFT - funzione malformata
    fixLunaComicsFT(content) {
        // La funzione _ReentrancyGuard_init() non dovrebbe esistere come funzione separata
        // È una funzione di inizializzazione di OpenZeppelin
        return content.replace(
            /function _ReentrancyGuard_init\(\) external onlyOwner \{[\s\S]*?\}/g,
            '    // ReentrancyGuard initialization is handled in initialize() function'
        );
    }

    // Verifica se una riga è dentro una funzione
    isInsideFunction(lines, targetLine) {
        let braceCount = 0;
        let inFunction = false;

        for (let i = 0; i < targetLine; i++) {
            if (lines[i].includes('{')) braceCount++;
            if (lines[i].includes('}')) braceCount--;
            if (lines[i].includes('function') && braceCount === 0) {
                inFunction = true;
            }
        }

        return inFunction && braceCount > 0;
    }

    // Pulizia generale - rimuovi funzioni problematiche
    cleanupProblematicFunctions(content) {
        // Rimuovi funzioni che non dovrebbero esistere come separate
        const patterns = [
            /function _ReentrancyGuard_init\(\)[^{]*\{[^}]*\}/g,
            /function __ReentrancyGuard_init\(\)[^{]*\{[^}]*\}/g,
            /function _AccessControl_init\(\)[^{]*\{[^}]*\}/g,
            /function __AccessControl_init\(\)[^{]*\{[^}]*\}/g
        ];

        let cleanedContent = content;
        patterns.forEach(pattern => {
            if (pattern.test(cleanedContent)) {
                cleanedContent = cleanedContent.replace(pattern, '');
                this.fixes.push('Rimosse funzioni di inizializzazione duplicate');
            }
        });

        return cleanedContent;
    }

    async fixAll() {
        console.log('🔧 CORREZIONE FINALE...\n');

        const contracts = [
            {
                path: 'contracts/core_infrastructure/EnhancedModuleRouter.sol',
                fix: (content) => this.cleanupProblematicFunctions(this.fixEnhancedModuleRouter(content)),
                name: 'EnhancedModuleRouter'
            },
            {
                path: 'contracts/planetary/MareaMangaNFT.sol',
                fix: (content) => this.cleanupProblematicFunctions(this.fixMareaMangaNFT(content)),
                name: 'MareaMangaNFT'
            },
            {
                path: 'contracts/satellites/LunaComicsFT.sol',
                fix: (content) => this.cleanupProblematicFunctions(this.fixLunaComicsFT(content)),
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
            console.log('\n💡 Se persistono errori, condividi:');
            console.log('   - Le ultime 10 righe di EnhancedModuleRouter.sol');
            console.log('   - Le righe 565-570 di MareaMangaNFT.sol');
            console.log('   - Le righe 65-75 di LunaComicsFT.sol');
        }
    }
}

// Esegui
const fixer = new FinalTouchFixer();
fixer.fixAll().catch(console.error);
