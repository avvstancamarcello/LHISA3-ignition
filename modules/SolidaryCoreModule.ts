// ignition/modules/SolidaryCoreModule.ts

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

// Utilizziamo nomi simbolici per i contratti (quelli presenti nel tuo progetto)

const InitialAdmin = "0x514EFc732Cc787fb19C90d01eDaf5a79d7E2385D"; // Indirizzo del Deployer per la stabilità

const SolidaryCoreModule = buildModule("SolidaryCoreModule", (m) => {
    // =========================================================================
    // FASE 1: I Pilastri (Utilities - Primi ad essere risolti)
    // =========================================================================
    
    // NOTA: Ignition gestisce l'ordinamento basato sulle dipendenze.
    // Usiamo `m.contract` con l'opzione `id` per dare un nome simbolico all'indirizzo.

    // 1. EnhancedImpactLogger
    const ImpactLogger = m.contract("EnhancedImpactLogger", [], {
        id: "ImpactLogger", 
        args: [], // UUPS proxy constructor ha argomenti vuoti (o di indirizzo admin, se necessario)
    });

    // 2. EnhancedReputationManager (Dipende da ImpactLogger solo concettualmente, ma logica UUPS simile)
    const ReputationManager = m.contract("EnhancedReputationManager", [], {
        id: "ReputationManager",
        args: [],
    });
    
    // 3. EnhancedSolidaryTrustManager
    const TrustManager = m.contract("EnhancedSolidaryTrustManager", [InitialAdmin, InitialAdmin, InitialAdmin], {
        id: "TrustManager",
        // TrustManager ha un costruttore che necessita di parametri iniziali (User/Hub/Reputation)
    });

    // ... Continua con tutti gli altri 3 moduli (Metrics, Router, OrchestratorV2) ...
    // Esempio:
    const Metrics = m.contract("SolidaryMetrics", [], { id: "Metrics" });
    const ModuleRouter = m.contract("EnhancedModuleRouter", [InitialAdmin], { id: "Router" });
    const OrchestratorV2 = m.contract("UniversalMultiChainOrchestratorV2", [InitialAdmin], { id: "OrchestratorV2" });

    // =========================================================================
    // FASE 2: Core Hub (Dipende dai Pilastri - UUPS Proxy)
    // =========================================================================
    
    // 7. EnhancedSolidaryHub (Il Core Hub - ALTO RISCHIO BYTECODE)
    const Hub = m.contract("EnhancedSolidaryHub", [InitialAdmin], {
        id: "SolidaryHub",
    });

    // =========================================================================
    // FASE 3: Inizializzazione Core Ecosystem (Chiamata esterna)
    // =========================================================================
    
    // NOTA: Poiché stai usando UUPS, Ignition si aspetta che la logica di inizializzazione
    // sia nel costruttore o in una funzione 'initialize' che chiameremo esplicitamente.
    
    // Inizializzazione Core Ecosystem (Hub.initializeEcosystem)
    // Hub.initializeEcosystem(Hub, 0x, 0x, Metrics, RepManager, ImpactLogger, Router, OrchestratorV2)
    const InitCall = m.call(Hub, "initializeEcosystem", [
        Hub, // _orchestrator (Hub stesso per ora)
        m.contract("OceanMangaNFT", [Hub, InitialAdmin, "OceanManga", "OMNFT", "ipfs://base/uri/"]), // 9. NFT Deployato
        m.contract("LunaComicsFT", [InitialAdmin, "LunaComics", "LUNA", ethers.parseEther("1000000"), InitialAdmin]), // 10. FT Deployato
        Metrics,
        ReputationManager,
        ImpactLogger,
        ModuleRouter,
        OrchestratorV2
    ]);

    // Ignizione delle registrazioni finali dei token (Fase 4 - Chiamate aggiuntive)
    // m.call(Hub, "registerEnhancedModule", [NFT.address, "OceanMangaNFT", 2, "nft", [] , "metadata"]);
    
    // Restituisci il Hub (Hub) come risorsa principale
    return { solidaryHub: Hub };
});

export default SolidaryCoreModule;
