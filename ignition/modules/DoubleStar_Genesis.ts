// ignition/modules/DoubleStar_Genesis.ts
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

/**
 * @title DoubleStarGenesis - Propositum Stellarum Duplicium
 * @author Avv. Marcello Stanca - Creator Stellarum
 * @notice Hoc contractus est fundamentum Systematis Securitatis Internationalis
 * @dev First DoubleStar implementation for Global Financial Security
 */
const DoubleStarGenesisModule = buildModule("DoubleStarGenesis", (m) => {
  
  // 🏛️ ARCae THEsauri - Treasury Vaults for Financial Security
  const admin = m.getParameter("admin", "0x514efc732cc787fb19c90d01edaf5a79d7e2385d");
  const securityWallet = m.getParameter("security", "0x514efc732cc787fb19c90d01edaf5a79d7e2385d");
  const charityWallet = m.getParameter("charity", "0x514efc732cc787fb19c90d01edaf5a79d7e2385d");

  console.log("🌌 Initializing DoubleStar Financial Security Protocol...");
  console.log("🏛️ Propositum Stellarum Duplicium - Via ad Securitatem Globalem");

  // 🌟 DOUBLE STAR GENESIS - COR PLANETAE NFT
  // ✅ USA IL FULLY QUALIFIED NAME
  const doubleStarGenesis = m.contract("contracts/creative_cultural/SolidaryComics.sol:SolidaryComics_StellaDoppia", [], {
    id: "DoubleStarCore"
  });

  // 🪐 INITIALIZATION - CREATIO PLANETAE ET SATELLITIS
  m.call(doubleStarGenesis, "initialize", [
    admin,           // initialOwner - Dominus Securitatis
    securityWallet,  // _securityWallet - Cista Securitatis
    3,               // _feePercent - Tres per Centum (più competitivo)
    admin,           // _creatorWallet - Cista Creatoris
    charityWallet,   // _solidaryWallet - Cista Solidarietatis
    Math.floor(Date.now() / 1000) + 86400 * 90, // _refundDeadline - Terminus XC dies
    "250000000000000000000" // 250 ETH in wei
  ], {
    id: "ConsecratioStellarum"
  });

  console.log("✅ DoubleStar Financial Security Protocol deployed!");
  console.log("🌠 Propositum Stellarum Duplicium Procedit!");
  console.log("💫 Brand Security Internazionale: ATTIVO");

  return { doubleStarGenesis };
});

export default DoubleStarGenesisModule;
