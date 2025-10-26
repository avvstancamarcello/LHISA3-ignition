const { readFileSync, writeFileSync, existsSync, copyFileSync } = require('fs');
const { join } = require('path');

class EmergencyRestorer {
    constructor() {
        this.backupDir = 'contracts_backup';
    }

    // Ripristina da backup se disponibili
    async restoreFromBackup() {
        console.log('🔄 RIPRISTINO EMERGENZA...\n');
        
        const contracts = [
            'contracts/core_infrastructure/EnhancedModuleRouter.sol',
            'contracts/planetary/MareaMangaNFT.sol',
            'contracts/satellites/LunaComicsFT.sol'
        ];

        let restoredCount = 0;

        for (const contractPath of contracts) {
            const backupPath = join(this.backupDir, contractPath);
            
            if (existsSync(backupPath)) {
                try {
                    copyFileSync(backupPath, contractPath);
                    console.log(`✅ ${contractPath} - RIPRISTINATO da backup`);
                    restoredCount++;
                } catch (error) {
                    console.log(`❌ ${contractPath} - Errore nel ripristino: ${error.message}`);
                }
            } else {
                console.log(`⚠️  ${contractPath} - Nessun backup trovato`);
            }
        }

        if (restoredCount > 0) {
            console.log(`\n🎯 ${restoredCount} contratti ripristinati. Prova: npx hardhat compile`);
        } else {
            console.log('\n💡 CREA NUOVI CONTRATTI PULITI...');
            await this.createCleanContracts();
        }
    }

    // Crea contratti puliti di base
    async createCleanContracts() {
        console.log('\n🔧 CREAZIONE CONTRATTI PULITI...\n');

        // EnhancedModuleRouter pulito
        const enhancedRouter = `// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract EnhancedModuleRouter is Initializable, AccessControlUpgradeable {
    function initialize() public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Aggiungi le tue funzioni qui...
}`;

        // MareaMangaNFT pulito
        const mareaManga = `// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract MareaMangaNFT is 
    ERC1155Upgradeable, 
    OwnableUpgradeable, 
    UUPSUpgradeable, 
    ReentrancyGuardUpgradeable 
{
    function initialize() public initializer {
        __ERC1155_init("https://api.mareamanga.com/metadata/");
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // Aggiungi le tue funzioni qui...
}`;

        // LunaComicsFT pulito
        const lunaComics = `// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract LunaComicsFT is 
    ERC20Upgradeable, 
    OwnableUpgradeable, 
    UUPSUpgradeable, 
    ReentrancyGuardUpgradeable 
{
    function initialize() public initializer {
        __ERC20_init("LunaComics", "LUNA");
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // Aggiungi le tue funzioni qui...
}`;

        const contracts = [
            { path: 'contracts/core_infrastructure/EnhancedModuleRouter.sol', content: enhancedRouter },
            { path: 'contracts/planetary/MareaMangaNFT.sol', content: mareaManga },
            { path: 'contracts/satellites/LunaComicsFT.sol', content: lunaComics }
        ];

        for (const contract of contracts) {
            try {
                writeFileSync(contract.path, contract.content);
                console.log(`✅ ${contract.path} - CREATO pulito`);
            } catch (error) {
                console.log(`❌ ${contract.path} - Errore: ${error.message}`);
            }
        }

        console.log('\n🎯 CONTRATTI PULITI CREATI! Prova: npx hardhat compile');
        console.log('\n💡 Ora puoi aggiungere gradualmente le tue funzioni originali');
    }

    // Correggi solo i problemi specifici senza rompere il resto
    async fixSpecificProblems() {
        console.log('🔧 CORREZIONE SPECIFICA...\n');

        const contracts = [
            'contracts/core_infrastructure/EnhancedModuleRouter.sol',
            'contracts/planetary/MareaMangaNFT.sol', 
            'contracts/satellites/LunaComicsFT.sol'
        ];

        for (const contractPath of contracts) {
            if (existsSync(contractPath)) {
                try {
                    let content = readFileSync(contractPath, 'utf8');
                    
                    // RIPRISTINA i pragma e import
                    content = content
                        .replace(/function setPragma solidity \^0\.8\.29;\(\) internal \{[^}]+\}/g, 'pragma solidity ^0.8.29;')
                        .replace(/function setImport[^;]+;\(\) internal \{[^}]+\}/g, '')
                        .replace(/function set[^{]+\{[^}]+\}/g, '')
                        .replace(/function setEvent[^;]+;\(\) internal \{[^}]+\}/g, '')
                        .replace(/function setMapping[^;]+;\(\) internal \{[^}]+\}/g, '')
                        .replace(/function setUint256[^;]+;\(\) internal \{[^}]+\}/g, '')
                        .replace(/function setReturn[^;]+;\(\) internal \{[^}]+\}/g, '')
                        .replace(/function setRequire[^;]+;\(\) internal \{[^}]+\}/g, '')
                        .replace(/function setEmit[^;]+;\(\) internal \{[^}]+\}/g, '')
                        .replace(/\n\s*\n\s*\n/g, '\n\n'); // Rimuovi righe vuote multiple

                    writeFileSync(contractPath, content);
                    console.log(`✅ ${contractPath} - RIPULITO`);
                } catch (error) {
                    console.log(`❌ ${contractPath} - Errore: ${error.message}`);
                }
            }
        }

        console.log('\n🎯 PROVA ORA: npx hardhat compile');
    }
}

// Esegui
const restorer = new EmergencyRestorer();

// Prima prova a correggere i problemi specifici
restorer.fixSpecificProblems().catch(async (error) => {
    console.log('❌ Correzione specifica fallita, ripristino completo...');
    await restorer.restoreFromBackup();
});
