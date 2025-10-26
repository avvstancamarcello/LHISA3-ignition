// ignition/modules/01_CoreInfrastructure.ts
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const CoreInfrastructureModule = buildModule("CoreInfrastructureModule", (m) => {
  // ✅ SOSTITUISCI con il TUO indirizzo wallet reale
  const initialAdmin = "0x514EFc732Cc787fb19C90d01eDaf5a79d7E2385D";

  console.log("🏗️ Iniziando deploy infrastruttura core (contratti upgradeable)...");

  // ✅ CONTRATTI UPGRADEABLE: Deploy + Initialize separati

  // 1. OraculumCaritatis
  const oraculumCaritatis = m.contract("OraculumCaritatis", []); // Constructor vuoto
  m.call(oraculumCaritatis, "initialize", [initialAdmin, initialAdmin]); // Initialize con parametri

  // 2. SolidaryTrustManager  
  const solidaryTrustManager = m.contract("SolidaryTrustManager", []); // Constructor vuoto
  m.call(solidaryTrustManager, "initialize", [initialAdmin]); // Initialize con parametri

  // 3. SolidaryHub
  const solidaryHub = m.contract("SolidaryHub", []); // Constructor vuoto
  m.call(solidaryHub, "initialize", [initialAdmin]); // Initialize con parametri

  console.log("✅ Contratti upgradeable configurati correttamente");

  return { 
    oraculumCaritatis, 
    solidaryTrustManager, 
    solidaryHub 
  };
});

export default CoreInfrastructureModule;
