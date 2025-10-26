// ignition/modules/SolidaryTrustManager_Deploy.ts
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

/**
 * @title SolidaryTrustManagerModule - Custos Fidei
 * @author Avv. Marcello Stanca - Architectus Aequitatis
 * @notice Governance Layer for DoubleStar Ecosystem
 */
const SolidaryTrustManagerModule = buildModule("SolidaryTrustManagerModule", (m) => {
  
  const admin = m.getParameter("admin", "0x514efc732cc787fb19c90d01edaf5a79d7e2385d");
  
  console.log("🏛️ Deploying SolidaryTrustManager...");
  console.log("⚖️ Custos Fidei - The Guardian of Trust");

  // Deploy del contratto
  const trustManager = m.contract("SolidaryTrustManager", [], {
    id: "TrustManager"
  });

  // Initialize call
  m.call(trustManager, "initialize", [admin], {
    id: "InitializeTrustManager"
  });

  console.log("✅ SolidaryTrustManager deployment configured!");
  console.log("🌠 Custos Fidei - Systema Gubernationis Procedit!");

  return { trustManager };
});

export default SolidaryTrustManagerModule;
