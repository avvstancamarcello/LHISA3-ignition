import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const SolidaryEcosystemModule = buildModule("SolidaryEcosystemModule", (m) => {
  // Sostituisci con il tuo indirizzo admin reale
  const initialAdmin = "0x514EFc732Cc787fb19C90d01eDaf5a79d7E2385D";

  // Contratti upgradeable

  const solidaryMetrics = m.contract("SolidarySystemMetrics", []);
  m.call(solidaryMetrics, "initialize", [initialAdmin]);

  const impactLogger1 = m.contract("SolidarySystemImpactLogger1", []);
  m.call(impactLogger1, "initialize", [initialAdmin]);

  const moduleRouter2 = m.contract("SolidarySystemModuleRouter2", []);
  m.call(moduleRouter2, "initialize", [initialAdmin]);

  const reputationManager3 = m.contract("SolidarySystemReputationManager3", []);
  m.call(reputationManager3, "initialize", [initialAdmin]);

  const trustManager4 = m.contract("SolidarySystemSolidaryTrustManager4", []);
  m.call(trustManager4, "initialize", [initialAdmin]);

  // Contratti non-upgradeable (stateless, solo funzioni pure)
  const moduleUtils = m.contract("SolidarySystemModuleUtils", []);
  const tokenRouter = m.contract("SolidarySystemTokenRouter", []);

  return {
    solidaryMetrics,
    impactLogger1,
    moduleRouter2,
    reputationManager3,
    trustManager4,
    moduleUtils,
    tokenRouter,
  };
});

export default SolidaryEcosystemModule;
