// ignition/modules/LunaComix.ts
import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

/**
 * @title LunaComixModule - Doublestar Comicorum
 * @author Avv. Marcello Stanca - Creator Stellarum
 * @notice Hoc contractus est prima manifestatio Systematis Duplicis Stellae
 * @dev First Doublestar implementation for Lucca Comics 2025
 */
const LunaComixModule = buildModule("LunaComixModule", (m) => {
  // 🎯 WALLETS - ARCae THEsauri
  const admin = m.getParameter("admin", "0x514efc732cc787fb19c90d01edaf5a79d7e2385d");
  const charityWallet = m.getParameter("charity", "0x514efc732cc787fb19c90d01edaf5a79d7e2385d");

  console.log("🎨 Initializing Luna Comix Doublestar deployment...");
  console.log("📚 Inceptio Lunae Comicorum - Via ad Lucca Comics");

  // 🌟 LUNA COMIX - PRIMA STELLA DUPLEX
  const lunaComix = m.contract("SolidaryComics_StellaDoppia", [], {
    id: "LunaComixDuplex"
  });

  // 🏗️ INITIALIZATION - CONSECRATIO CONTRACTUS
  m.call(lunaComix, "initialize", [
    admin,           // initialOwner - Dominus
    charityWallet,   // _charityWallet - Cista Caritatis
    5,               // _feePercent - Quinque per Centum
    admin,           // _creatorWallet - Cista Creatoris
    charityWallet,   // _solidaryWallet - Cista Solidarietatis
    Math.floor(Date.now() / 1000) + 86400 * 30, // _refundDeadline - Terminus XXX dies
    ethers.parseEther("100") // _initialThreshold - Centum Etherorum
  ], {
    id: "ConsecratioLunae"
  });

  console.log("✅ Luna Comix Doublestar configured successfully!");
  console.log("🌕 Luna Comix Parata - Ad Lucca Comics Procedimus!");

  return { lunaComix };
});

export default LunaComixModule;
