const { readFileSync, writeFileSync, existsSync } = require('fs');

class FinalErrorFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - conflitto di nomi
    fixEnhancedModuleRouter(content) {
        // Il problema: `disableInitializers` è già definito in OpenZeppelin
        // Cambia il nome della funzione per evitare conflitti
        return content.replace(
            /function disableInitializers\(\) external onlyOwner \{/g,
            'function disableContractInitializers() external onlyOwner {'
        );
    }

    // Correggi MareaMangaNFT - chiamata funzione fuori posto
    fixMareaMangaNFT(content) {
        let lines = content.split('\n');
        
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].includes('_initializeCommercialPorts();')) {
                // Verifica se è dentro una funzione
                let isInsideFunction = false;
                let braceCount = 0;
                
                for (let j = 0; j < i; j++) {
                    if (lines[j].includes('{')) braceCount++;
                    if (lines[j].includes('}')) braceCount--;
                    if (lines[j].includes('function') && braceCount === 0) {
                        isInsideFunction = true;
                    }
                }
                
                if (!isInsideFunction) {
                    // Incapsula in una funzione
                    lines[i] = `    function initializeCommercialPorts() external onlyOwner {\n        _initializeCommercialPorts();\n    }`;
                    this.fixes.push('MareaMangaNFT: _initializeCommercialPorts() incapsulata correttamente');
                }
                break;
            }
        }
        
        return lines.join('\n');
    }

    // Correggi LunaComicsFT - stesso conflitto di EnhancedModuleRouter
    fixLunaComicsFT(content) {
        // Stesso problema: `disableInitializers` è già in OpenZeppelin
        return content.replace(
            /function disableInitializers\(\) external onlyOwner \{/g,
            'function disableContractInitializers() external onlyOwner {'
        );
    }

    async fixAll() {
        console.log('🔧 CORREZIONE FINALE ERRORI...\n');

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
            }
        ];

        for (const contract of contracts) {
            if (existsSync(contract.path)) {
                try {
                    const content = readFileSync(contract.path, 'utf8');
                    const fixedContent = contract.fix(content);
                    
                    if (fixedContent !== content) {
                        writeFileSync(contract.path, fixedContent);
                        console.log(`✅ ${contract.path} - CORRETTO`);
                        this.fixes.push(`${contract.path.split('/').pop()}: Errore risolto`);
                    } else {
                        console.log(`❌ ${contract.path} - Impossibile trovare il pattern dell'errore`);
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
            console.log('  ❌ Nessuna correzione applicata');
            console.log('\n💡 CORREZIONE MANUALE:');
            console.log('   Per EnhancedModuleRouter.sol e LunaComicsFT.sol:');
            console.log('   - Cambia "function disableInitializers()" in "function disableContractInitializers()"');
            console.log('   Per MareaMangaNFT.sol:');
            console.log('   - Sposta "_initializeCommercialPorts();" dentro una funzione');
        }
    }
}

// Esegui
const fixer = new FinalErrorFixer();
fixer.fixAll().catch(console.error);
