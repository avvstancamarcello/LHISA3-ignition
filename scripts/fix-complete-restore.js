const { readFileSync, writeFileSync, existsSync } = require('fs');

class CompleteRestorer {
    constructor() {
        this.fixes = [];
    }

    // RIPRISTINA EnhancedModuleRouter - codice completamente rotto
    fixEnhancedModuleRouter(content) {
        const lines = content.split('\n');
        const fixedLines = [];
        let inBrokenConstructor = false;
        let constructorClosed = false;

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];

            // Gestisce il constructor rotto (righe 74-80)
            if (line.includes('constructor() {') && i === 73) { // riga 74
                fixedLines.push('    /// @custom:oz-upgrades-unsafe-allow constructor');
                fixedLines.push('    constructor() {');
                fixedLines.push('        _disableInitializers();');
                fixedLines.push('    }');
                fixedLines.push('');
                inBrokenConstructor = true;
                // Salta le righe corrotte (75-80)
                while (i < lines.length && !lines[i].includes('}') && i < 80) {
                    i++;
                }
                constructorClosed = true;
                continue;
            }

            // Se siamo nelle righe corrotte, saltale
            if (i >= 74 && i <= 80 && !constructorClosed) {
                continue;
            }

            // Rimuovi funzioni duplicate
            if (line.includes('function disableInitializers() external onlyOwner') && 
                fixedLines.some(l => l.includes('function disableInitializers'))) {
                continue;
            }

            fixedLines.push(line);
        }

        this.fixes.push('EnhancedModuleRouter: Constructor e funzioni ripristinati');
        return fixedLines.join('\n');
    }

    // RIPRISTINA MareaMangaNFT - codice fuori posto
    fixMareaMangaNFT(content) {
        const lines = content.split('\n');
        const fixedLines = [];
        let inFunction = false;

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];

            // Salta le righe corrotte (186-188)
            if (i >= 185 && i <= 187) {
                // Queste righe dovrebbero essere dentro una funzione, non fuori!
                continue;
            }

            // Verifica se "ocean.totalShips" è dentro una funzione valida
            if (line.includes('ocean.totalShips = shipCount;')) {
                let isInsideFunction = false;
                let braceCount = 0;
                
                // Controlla il contesto precedente
                for (let j = 0; j < i; j++) {
                    if (lines[j].includes('{')) braceCount++;
                    if (lines[j].includes('}')) braceCount--;
                    if (lines[j].includes('function') && braceCount === 0) {
                        isInsideFunction = true;
                    }
                }

                if (!isInsideFunction) {
                    // Incapsula in una funzione
                    fixedLines.push('    function updateOceanStats(uint256 shipCount) internal {');
                    fixedLines.push('        ocean.totalShips = shipCount;');
                    fixedLines.push('        ocean.lowTide = block.timestamp;');
                    fixedLines.push('    }');
                    this.fixes.push('MareaMangaNFT: ocean stats incapsulati in funzione');
                    continue;
                }
            }

            fixedLines.push(line);
        }

        return fixedLines.join('\n');
    }

    // RIPRISTINA LunaComicsFT - stesso problema di EnhancedModuleRouter
    fixLunaComicsFT(content) {
        const lines = content.split('\n');
        const fixedLines = [];
        let inBrokenConstructor = false;

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];

            // Gestisce il constructor rotto (righe 60-65)
            if (line.includes('constructor() {') && i === 59) { // riga 60
                fixedLines.push('    /// @custom:oz-upgrades-unsafe-allow constructor');
                fixedLines.push('    constructor() {');
                fixedLines.push('        _disableInitializers();');
                fixedLines.push('    }');
                fixedLines.push('');
                inBrokenConstructor = true;
                // Salta le righe corrotte (61-65)
                while (i < lines.length && !lines[i].includes('}') && i < 65) {
                    i++;
                }
                continue;
            }

            // Se siamo nelle righe corrotte, saltale
            if (i >= 60 && i <= 65 && inBrokenConstructor) {
                continue;
            }

            // Rimuovi funzioni duplicate
            if (line.includes('function disableInitializers() external onlyOwner') && 
                fixedLines.some(l => l.includes('function disableInitializers'))) {
                continue;
            }

            fixedLines.push(line);
        }

        this.fixes.push('LunaComicsFT: Constructor e funzioni ripristinati');
        return fixedLines.join('\n');
    }

    async fixAll() {
        console.log('🔧 RIPRISTINO COMPLETO CODICE CORROTTO...\n');

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
                    console.log(`\n🔄 Ripristinando: ${contract.name}`);
                    const content = readFileSync(contract.path, 'utf8');
                    const fixedContent = contract.fix(content);
                    
                    writeFileSync(contract.path, fixedContent);
                    console.log(`✅ ${contract.name} - RIPRISTINATO`);
                } catch (error) {
                    console.log(`❌ ${contract.name} - Errore: ${error.message}`);
                }
            }
        }

        console.log('\n📊 RIEPILOGO RIPRISTINO:');
        this.fixes.forEach((fix, index) => {
            console.log(`  ${index + 1}. ${fix}`);
        });

        console.log('\n🎯 PROVA ORA: npx hardhat compile');
        console.log('\n💡 Il codice corrotto è stato sostituito con versioni pulite!');
    }
}

// Esegui
const restorer = new CompleteRestorer();
restorer.fixAll().catch(console.error);
