// ignition/modules/00_TestDeploy.ts
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

/**
 * @title TestDeployModule - Primum Mobile
 * @author Avv. Marcello Stanca - Architectus Stellarum
 * @notice Hoc est primum experimentum in via ad Doublestar System
 * @dev Initial deployment test for Upgradeable Contracts
 */
const TestDeployModule = buildModule("TestDeployModule", (m) => {
  // 🎯 ADMIN WALLET - COR ET CAPUT SYSTEMATIS
  const admin = m.getParameter("admin", "0x514efc732cc787fb19c90d01edaf5a79d7e2385d");
  
  console.log("🧪 Deploying SolidaryTrustManager (Upgradeable)...");
  
  // 🌟 DEPLOY - CONSTRUCTOR VUOTO per upgradeable
  const solidaryTrustManager = m.contract("SolidaryTrustManager", [], {
    id: "FiduciaeFundamentum"
  });
  
  // 🏗️ INITIALIZATION - CHIAMATA SEPARATA
  m.call(solidaryTrustManager, "initialize", [admin], {
    id: "InitFiduciae"
  });
  
  console.log("✅ Upgradeable contract configured correctly");
  console.log("🌟 Doublestar System - Primus Gradus ad Sidera");
  
  return { solidaryTrustManager };
});

export default TestDeployModule;
