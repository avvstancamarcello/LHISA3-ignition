const { readFileSync, writeFileSync, existsSync } = require('fs');

class DirectFixer {
    constructor() {
        this.fixes = [];
    }

    // Correggi DIRECTAMENTE EnhancedModuleRouter - riga 97
    fixEnhancedModuleRouter() {
        const path = 'contracts/core_infrastructure/EnhancedModuleRouter.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // CORREGGI RIGA 97 - Il problema potrebbe essere prima
        if (lines[96] && lines[96].includes('moduleAddress: moduleAddress,')) {
            console.log('🔍 EnhancedModuleRouter riga 97:', lines[96]);
            
            // Verifica il contesto - cerca la struct initialization
            let structStart = -1;
            for (let i = 95; i >= 0; i--) {
                if (lines[i] && lines[i].includes('ModuleInfo({')) {
                    structStart = i;
                    break;
                }
            }
            
            if (structStart !== -1) {
                console.log('✅ Trovata inizializzazione struct alla riga', structStart + 1);
                // La sintassi struct è corretta, il problema potrebbe essere altrove
            } else {
                // Forse manca la parentesi di apertura della struct
                for (let i = 95; i < 100; i++) {
                    if (lines[i] && lines[i].includes('modules[moduleName] = ModuleInfo')) {
                        if (!lines[i].includes('({')) {
                            // Aggiungi la parentesi di apertura
                            lines[i] = lines[i].replace('ModuleInfo', 'ModuleInfo({');
                            this.fixes.push('EnhancedModuleRouter: Aggiunta { alla struct initialization');
                        }
                    }
                }
            }
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi DIRECTAMENTE MareaMangaNFT - riga 562
    fixMareaMangaNFT() {
        const path = 'contracts/planetary/MareaMangaNFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // CORREGGI RIGA 562 - Sposta l'emit in una funzione
        if (lines[561] && lines[561].includes('emit CommercialAuctionStarted(')) {
            console.log('🔍 MareaMangaNFT riga 562:', lines[561]);
            
            // Sostituisci la riga con una funzione wrapper
            lines[561] = '    function _emitCommercialAuction(uint256 portId, uint256[] memory nftIds, uint256 duration) internal {\n        emit CommercialAuctionStarted(portId, nftIds, duration);\n    }';
            this.fixes.push('MareaMangaNFT: emit CommercialAuctionStarted incapsulato in funzione');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    // Correggi DIRECTAMENTE LunaComicsFT - riga 69
    fixLunaComicsFT() {
        const path = 'contracts/satellites/LunaComicsFT.sol';
        if (!existsSync(path)) return;

        let content = readFileSync(path, 'utf8');
        let lines = content.split('\n');
        
        // CORREGGI RIGA 69 - Sposta l'assegnazione in una funzione
        if (lines[68] && lines[68].includes('tidalForce = 1e18;')) {
            console.log('🔍 LunaComicsFT riga 69:', lines[68]);
            
            // Sostituisci la riga con una funzione di inizializzazione
            lines[68] = '    function _initializeTidalForce() internal {\n        tidalForce = 1e18;\n    }';
            this.fixes.push('LunaComicsFT: tidalForce initialization incapsulata in funzione');
        }
        
        writeFileSync(path, lines.join('\n'));
    }

    async fixAll() {
        console.log('🔧 CORREZIONE DIRETTA DELLE RIGHE PROBLEMATICHE...\n');

        // Esegui tutte le correzioni
        this.fixEnhancedModuleRouter();
        this.fixMareaMangaNFT();
        this.fixLunaComicsFT();

        console.log('\n📊 RIEPILOGO CORREZIONI APPLICATE:');
        if (this.fixes.length > 0) {
            this.fixes.forEach((fix, index) => {
                console.log(`  ${index + 1}. ${fix}`);
            });
        } else {
            console.log('  ❌ Nessuna correzione applicata - file non trovati o righe modificate');
        }

        console.log('\n🎯 PROVA ORA: npx hardhat compile');
        
        if (this.fixes.length === 0) {
            console.log('\n💡 CORREZIONI MANUALI OBBLIGATORIE:');
            console.log('\n1. EnhancedModuleRouter.sol - Riga 97:');
            console.log('   CERCA: moduleAddress: moduleAddress,');
            console.log('   VERIFICA che sia dentro: modules[moduleName] = ModuleInfo({ ... });');
            console.log('   SE MANCA, aggiungi: modules[moduleName] = ModuleInfo({');
            
            console.log('\n2. MareaMangaNFT.sol - Riga 562:');
            console.log('   SOSTITUISCI:');
            console.log('     emit CommercialAuctionStarted(portId, nftIds, duration);');
            console.log('   CON:');
            console.log('     function _startAuction(uint256 portId, uint256[] memory nftIds, uint256 duration) internal {');
            console.log('         emit CommercialAuctionStarted(portId, nftIds, duration);');
            console.log('     }');
            
            console.log('\n3. LunaComicsFT.sol - Riga 69:');
            console.log('   SOSTITUISCI:');
            console.log('     tidalForce = 1e18;');
            console.log('   CON:');
            console.log('     function _initTidalForce() internal {');
            console.log('         tidalForce = 1e18;');
            console.log('     }');
        }
    }
}

// Esegui
const fixer = new DirectFixer();
fixer.fixAll().catch(console.error);
