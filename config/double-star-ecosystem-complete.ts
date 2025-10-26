export const DOUBLE_STAR_ECOSYSTEM = {
  NETWORK: "Base Mainnet",
  DEPLOYER: "0x514efc732cc787fb19c90d01edaf5a79d7e2385d",
  DEPLOYMENT_DATE: "2024-10-16T22:54:00.000Z",
  STATUS: "🟢 FULLY DEPLOYED",
  
  TRIPLE_LAYER_ARCHITECTURE: {
    INFRASTRUCTURE: {
      contract: "SolidaryHub",
      address: "0xE9458CdA8e3dA88E1b1588EeCd6b1CFE2A398602",
      role: "Core Infrastructure & Hub",
      explorer: "https://basescan.org/address/0xE9458CdA8e3dA88E1b1588EeCd6b1CFE2A398602"
    },
    JUSTICE: {
      contract: "OraculumCaritatis", 
      address: "0xcc516a4374021d4a959A6887F2b1501F372f27F6",
      role: "Charity & Justice System",
      explorer: "https://basescan.org/address/0xcc516a4374021d4a959A6887F2b1501F372f27F6"
    },
    GOVERNANCE: {
      contract: "SolidaryTrustManager",
      proxy: "0x625c95A763F900f3d60fdCEC01A4474B985bAb45",
      implementation: "0x78E2514CD81aB1891B38c0Bb7ebd83E646Af5629",
      role: "Trust & Governance Layer",
      type: "UUPS Upgradeable Proxy",
      explorer: "https://basescan.org/address/0x625c95A763F900f3d60fdCEC01A4474B985bAb45"
    }
  }
};
