// ignition/modules/SolidaryCoreModule.ts

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

// Utilizziamo nomi simbolici per i contratti (quelli presenti nel tuo progetto)

const InitialAdmin = "0x8495B3f7493263685fFcDA2602fFfF349d4eD3B8"; // Indirizzo del Deployer per la stabilità

const SolidaryCoreModule = buildModule("SolidaryCoreModule", (m) => {
    // =========================================================================
    // FASE 1: I Pilastri (Utilities - Primi ad essere risolti)
    // =========================================================================

    // NOTA: Ignition gestisce l'ordinamento basato sulle dipendenze.
    // Usiamo `m.contract` con l'opzione `id` per dare un nome simbolico all'indirizzo.

    // 1. SolidarySystemImpactLogger1
    const ImpactLogger = m.contract("SolidarySystemImpactLogger1", [], {
        id: "ImpactLogger",
        args: [], // UUPS proxy constructor ha argomenti vuoti
    });

    // 2. SolidarySystemModuleRouter2
    const ModuleRouter = m.contract("SolidarySystemModuleRouter2", [], { id: "Router" });
    m.call(ModuleRouter, "initialize", [InitialAdmin]);

    // 3. SolidarySystemReputationManager3
    const ReputationManager = m.contract("SolidarySystemReputationManager3", [], {
        id: "ReputationManager",
        args: [],
    });

    // 4. SolidarySystemTrustManager4
    const TrustManager = m.contract("SolidarySystemTrustManager4", [], {
        id: "TrustManager",
    });
    // Chiamata initialize spostata dopo Hub

    // ... Continua con tutti gli altri moduli (Metrics, OrchestratorV2) ...
    const Metrics = m.contract("SolidarySystemMetrics", [], { id: "Metrics" });
    const OrchestratorV2 = m.contract("UniversalMultiChainOrchestratorV2", [], { id: "OrchestratorV2" });
    // Chiamata initialize spostata dopo Hub

    // =========================================================================
    // FASE 2: Core Hub (Dipende dai Pilastri - UUPS Proxy)
    // =========================================================================

    // 7. SolidarySystemHub (Il Core Hub - ALTO RISCHIO BYTECODE)
    const Hub = m.contract("SolidarySystemHub", [], {
        id: "SolidaryHub",
    });
    m.call(Hub, "initialize", [InitialAdmin]);
    m.call(TrustManager, "initialize", [InitialAdmin, Hub, ReputationManager]);
    m.call(OrchestratorV2, "initialize", [InitialAdmin, Hub, ReputationManager, "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", "0x0000000000000000000000000000000000000000", Metrics]);

    // =========================================================================
    // FASE 3: Inizializzazione Core Ecosystem (Chiamata esterna)
    // =========================================================================

    // Inizializzazione Core Ecosystem (Hub.initializeEcosystem)
    // Aspetta 9 argomenti: _orchestrator, _nft, _ft, _metrics, _reputationManager, _impactLogger, _moduleRouter, _orchestratorV2, _trustManager
    const InitCall = m.call(Hub, "initializeEcosystem", [
        Hub, // _orchestrator
        m.contract("OceanMangaNFT", []), // _nft (costruttore vuoto, se non UUPS potrebbe fallire)
        m.contract("LunaComicsFT", []), // _ft (costruttore vuoto)
        Metrics, // _metrics
        ReputationManager, // _reputationManager
        ImpactLogger, // _impactLogger
        ModuleRouter, // _moduleRouter
        OrchestratorV2, // _orchestratorV2
        TrustManager // _trustManager (aggiunto)
    ]);

    // =========================================================================
    // FASE 4: Ethical Role Modules (Gestione ruoli granulari per categorie utente)
    // =========================================================================

    // Questi moduli concedono DEFAULT_ADMIN_ROLE e ruoli specifici all'InitialAdmin
    const EduManager = m.contract("SolidaryEduManager", [InitialAdmin], { id: "EduManager" });
    const FaithMint = m.contract("SolidaryFaithMint", [InitialAdmin], { id: "FaithMint" });
    const GovMint = m.contract("SolidaryGovMint", [InitialAdmin], { id: "GovMint" });
    const GovToken = m.contract("SolidaryGovToken", [InitialAdmin], { id: "GovToken" });
    const HeartBridge = m.contract("SolidaryHeartBridge", [InitialAdmin], { id: "HeartBridge" });
    const JusticeManager = m.contract("SolidaryJusticeManager", [InitialAdmin], { id: "JusticeManager" });
    const PeaceManager = m.contract("SolidaryPeaceManager", [InitialAdmin], { id: "PeaceManager" });
    const SocialMint = m.contract("SolidarySocialMint", [InitialAdmin], { id: "SocialMint" });
    const SoulBridge = m.contract("SolidarySoulBridge", [InitialAdmin], { id: "SoulBridge" });
    const SponsorVault = m.contract("SolidarySponsorVault", [InitialAdmin], { id: "SponsorVault" });
    const UnivManager = m.contract("SolidaryUnivManager", [InitialAdmin], { id: "UnivManager" });

    // Restituisci il Hub come risorsa principale
    return { solidaryHub: Hub };
});

export default SolidaryCoreModule;
