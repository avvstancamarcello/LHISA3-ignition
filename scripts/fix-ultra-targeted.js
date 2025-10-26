const { readFileSync, writeFileSync, existsSync } = require('fs');

class UltraTargetedFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi EnhancedModuleRouter - errore di sintassi alla riga 97
    fixEnhancedModuleRouter(content) {
        const lines = content.split('\n');
        
        // Correggi la riga 97: moduleAddress: moduleAddress, → moduleAddress = moduleAddress;
        if (lines[96] && lines[96].includes('moduleAddress: moduleAddress,')) {
            lines[96] = lines[96].replace('moduleAddress: moduleAddress,', 'moduleAddress: moduleAddress,');
            // Aspetta, il problema potrebbe essere la struttura dell'oggetto
            // Cerchiamo il contesto completo
            for (let i = 95; i < 100; i++) {
                if (lines[i] && lines[i].includes('modules[moduleName] = ModuleInfo({')) {
                    // Questo è un inizializzatore di struct - dovrebbe usare i due punti
                    // Il problema potrebbe essere altrove
                    console.log('🔍 EnhancedModuleRouter: Trovato inizializzatore struct alla riga', i + 1);
                }
            }
        }

        // Controlla se ci sono errori di struct
        let fixedContent = content;
        
        // Se è un inizializzatore di struct, assicurati che sia corretto
        if (content.includes('ModuleInfo({') && content.includes('moduleAddress:')) {
            // La sintassi struct è corretta, il problema potrebbe essere prima/dopo
            // Controlla parentesi e virgole
            fixedContent = this.fixStructSyntax(content);
        }
        
        return fixedContent !== content ? fixedContent : lines.join('\n');
    }

    // Correggi sintassi struct
    fixStructSyntax(content) {
        // Cerca e correggi pattern di struct common
        return content
            .replace(/ModuleInfo\(\{/g, 'ModuleInfo({')
            .replace(/moduleAddress:\s*moduleAddress,/g, 'moduleAddress: moduleAddress,')
            .replace(/version:\s*version,/g, 'version: version,')
            .replace(/isActive:\s*true,/g, 'isActive: true,')
            .replace(/lastUsed:\s*block\.timestamp/g, 'lastUsed: block.timestamp');
    }

    // Correggi MareaMangaNFT - emit fuori da funzione (RIGA 562)
    fixMareaMangaNFT(content) {
        const lines = content.split('\n');
        let fixedLines = [];
        
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            
            // Riga 562 specifica - emit fuori da funzione
            if (i === 561 && line.includes('emit CommercialAuctionStarted(')) {
                // Verifica se è già dentro una funzione
                if (!this.isInsideFunction(lines, i)) {
                    // Crea una funzione wrapper per l'emit
                    fixedLines.push('    function _emitCommercialAuction(uint256 portId, uint256[] memory nftIds, uint256 duration) internal {');
                    fixedLines.push('        emit CommercialAuctionStarted(portId, nftIds, duration);');
                    fixedLines.push('    }');
                    this.fixes.push('MareaMangaNFT: emit CommercialAuctionStarted incapsulato');
                } else {
                    fixedLines.push(line);
                }
            } else {
                fixedLines.push(line);
            }
        }
        
        return fixedLines.join('\n');
    }

    // Correggi LunaComicsFT - assegnazione fuori da funzione (RIGA 66)
    fixLunaComicsFT(content) {
        const lines = content.split('\n');
        let fixedLines = [];
        
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            
            // Riga 66 specifica - assegnazione fuori da funzione
            if (i === 65 && line.includes('lunarGravity = 1e18;')) {
                // Verifica se è già dentro una funzione
                if (!this.isInsideFunction(lines, i)) {
                    // Crea una funzione di inizializzazione
                    fixedLines.push('    function _initializeGravity() internal {');
                    fixedLines.push('        lunarGravity = 1e18;');
                    fixedLines.push('    }');
                    this.fixes.push('LunaComicsFT: lunarGravity initialization incapsulata');
                } else {
                    fixedLines.push(line);
                }
            } else {
                fixedLines.push(line);
            }
        }
        
        return fixedLines.join('\n');
    }

    // Verifica se una riga è dentro una funzione
    isInsideFunction(lines, targetIndex) {
        let braceCount = 0;
        let inFunction = false;
        
        for (let i = 0; i < targetIndex; i++) {
            const line = lines[i];
            
            if (line.includes('contract ') && braceCount === 0) {
                braceCount++; // Entra nel contratto
            }
            else if (line.includes('function ') && braceCount === 1) {
                inFunction = true;
                braceCount++; // Entra nella funzione
            }
            else if (line.includes('{')) {
                braceCount++;
            }
            else if (line.includes('}')) {
                braceCount--;
                if (braceCount === 1) {
                    inFunction = false; // Esce dalla funzione
                }
            }
        }
        
        return inFunction && braceCount > 1;
    }

    async fixAll() {
        console.log('🔧 CORREZIONE ULTRA-MIRATA...\n');

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
                    console.log(`🔧 Analizzando: ${contract.name}`);
                    const content = readFileSync(contract.path, 'utf8');
                    const fixedContent = contract.fix(content);
                    
                    if (fixedContent !== content) {
                        writeFileSync(contract.path, fixedContent);
                        console.log(`✅ ${contract.name} - CORRETTO`);
                    } else {
                        console.log(`ℹ️  ${contract.name} - Nessuna modifica necessaria`);
                        console.log(`   💡 Correzione manuale richiesta per gli errori specifici`);
                    }
                } catch (error) {
                    console.log(`❌ ${contract.name} - Errore: ${error.message}`);
                }
            }
        }

        console.log('\n📊 RIEPILOGO:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ${index + 1}. ${fix}`);
            });
        }

        console.log('\n🎯 PROVA ORA: npx hardhat compile');
        
        console.log('\n💡 CORREZIONI MANUALI SE PERSISTONO ERRORI:');
        console.log('   EnhancedModuleRouter.sol riga 97:');
        console.log('     Verifica la sintassi: modules[moduleName] = ModuleInfo({');
        console.log('                            moduleAddress: moduleAddress,');
        console.log('                            version: version,');
        console.log('                            isActive: true,');
        console.log('                            lastUsed: block.timestamp');
        console.log('                          });');
        console.log('   MareaMangaNFT.sol riga 562:');
        console.log('     Sposta dentro una funzione: function xxx() { emit CommercialAuctionStarted(...); }');
        console.log('   LunaComicsFT.sol riga 66:');
        console.log('     Sposta dentro una funzione: function xxx() { lunarGravity = 1e18; }');
    }
}

// Esegui
const fixer = new UltraTargetedFixer();
fixer.fixAll().catch(console.error);
