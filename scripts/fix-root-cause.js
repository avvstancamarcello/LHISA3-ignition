const { readFileSync, writeFileSync, existsSync } = require('fs');

class RootCauseFixer {
    constructor() {
        this.fixes = [];
    }

    // Trova e chiudi le parentesi mancanti PRIMA delle funzioni problematiche
    fixEnhancedModuleRouter(content) {
        const lines = content.split('\n');
        const errorLine = 75; // Dove segnala l'errore
        
        // Cerca la funzione prima della riga 75 che non è chiusa
        for (let i = errorLine - 2; i >= 0; i--) {
            if (lines[i].includes('function') && !lines[i].includes(';')) {
                // Conta le parentesi da questa funzione fino all'errore
                let openBraces = 0;
                let closeBraces = 0;
                
                for (let j = i; j < errorLine - 1; j++) {
                    openBraces += (lines[j].match(/{/g) || []).length;
                    closeBraces += (lines[j].match(/}/g) || []).length;
                }
                
                // Se ci sono parentesi aperte non chiuse, aggiungi la chiusura
                if (openBraces > closeBraces) {
                    lines.splice(errorLine - 1, 0, '    }');
                    this.fixes.push('EnhancedModuleRouter: Aggiunta parentesi mancante prima della riga 75');
                    return lines.join('\n');
                }
            }
        }
        
        return content;
    }

    fixMareaMangaNFT(content) {
        const lines = content.split('\n');
        const errorLine = 186; // Dove segnala l'errore
        
        // Cerca la funzione prima della riga 186
        for (let i = errorLine - 2; i >= 0; i--) {
            if (lines[i].includes('function') && !lines[i].includes(';')) {
                let openBraces = 0;
                let closeBraces = 0;
                
                for (let j = i; j < errorLine - 1; j++) {
                    openBraces += (lines[j].match(/{/g) || []).length;
                    closeBraces += (lines[j].match(/}/g) || []).length;
                }
                
                if (openBraces > closeBraces) {
                    lines.splice(errorLine - 1, 0, '    }');
                    this.fixes.push('MareaMangaNFT: Aggiunta parentesi mancante prima della riga 186');
                    return lines.join('\n');
                }
            }
        }
        
        return content;
    }

    fixLunaComicsFT(content) {
        const lines = content.split('\n');
        const errorLine = 61; // Dove segnala l'errore
        
        // Stessa logica per LunaComicsFT
        for (let i = errorLine - 2; i >= 0; i--) {
            if (lines[i].includes('function') && !lines[i].includes(';')) {
                let openBraces = 0;
                let closeBraces = 0;
                
                for (let j = i; j < errorLine - 1; j++) {
                    openBraces += (lines[j].match(/{/g) || []).length;
                    closeBraces += (lines[j].match(/}/g) || []).length;
                }
                
                if (openBraces > closeBraces) {
                    lines.splice(errorLine - 1, 0, '    }');
                    this.fixes.push('LunaComicsFT: Aggiunta parentesi mancante prima della riga 61');
                    return lines.join('\n');
                }
            }
        }
        
        return content;
    }

    // Ripristina le chiamate legittime che sono state incapsulate erroneamente
    restoreLegitimateCode(content) {
        // Rimuovi le funzioni wrapper create erroneamente e ripristina le chiamate originali
        return content
            .replace(/function _disableInitializers\(\) external onlyOwner \{\s*_disableInitializers\(\);\s*\}/g, '        _disableInitializers();')
            .replace(/function __AccessControl_init\(\) external onlyOwner \{\s*__AccessControl_init\(\);\s*\}/g, '        __AccessControl_init();')
            .replace(/function __ReentrancyGuard_init\(\) external onlyOwner \{\s*__ReentrancyGuard_init\(\);\s*\}/g, '        __ReentrancyGuard_init();')
            .replace(/function _updateGravity\(\) external onlyOwner \{\s*_updateGravity\(\);\s*\}/g, '        _updateGravity();')
            .replace(/function userFarmsArray\.pop\(\) external onlyOwner \{\s*userFarmsArray\.pop\(\);\s*\}/g, '        userFarmsArray.pop();')
            .replace(/function _configureFromOrchestrator\(\) external onlyOwner \{\s*_configureFromOrchestrator\(\);\s*\}/g, '        _configureFromOrchestrator();')
            .replace(/function _takeGravitySnapshot\(\) external onlyOwner \{\s*_takeGravitySnapshot\(\);\s*\}/g, '        _takeGravitySnapshot();');
    }

    async fixAll() {
        console.log('🔧 CORREZIONE CAUSA RADICE...\n');

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

        // PRIMA: Aggiungi parentesi mancanti
        for (const contract of contracts) {
            if (existsSync(contract.path)) {
                try {
                    let content = readFileSync(contract.path, 'utf8');
                    const fixedContent = contract.fix(content);
                    
                    if (fixedContent !== content) {
                        writeFileSync(contract.path, fixedContent);
                        console.log(`✅ ${contract.path} - Parentesi aggiunta`);
                    }
                } catch (error) {
                    console.log(`❌ ${contract.path} - Errore: ${error.message}`);
                }
            }
        }

        // POI: Ripristina il codice legittimo
        console.log('\n🔄 Ripristino codice legittimo...');
        for (const contract of contracts) {
            if (existsSync(contract.path)) {
                try {
                    let content = readFileSync(contract.path, 'utf8');
                    const restoredContent = this.restoreLegitimateCode(content);
                    
                    if (restoredContent !== content) {
                        writeFileSync(contract.path, restoredContent);
                        console.log(`✅ ${contract.path} - Codice ripristinato`);
                        this.fixes.push(`${contract.path.split('/').pop()}: Chiamate legittime ripristinate`);
                    }
                } catch (error) {
                    console.log(`❌ ${contract.path} - Errore: ${error.message}`);
                }
            }
        }

        console.log('\n📊 RIEPILOGO:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ${index + 1}. ${fix}`);
            });
        } else {
            console.log('  ℹ️  Nessuna modifica necessaria');
        }

        console.log('\n🎯 PROVA ORA: npx hardhat compile');
        console.log('\n💡 SE PERSISTONO ERRORI:');
        console.log('   Condividi le righe 70-80 di EnhancedModuleRouter.sol');
        console.log('   e le righe 180-190 di MareaMangaNFT.sol');
    }
}

// Esegui
const fixer = new RootCauseFixer();
fixer.fixAll().catch(console.error);
