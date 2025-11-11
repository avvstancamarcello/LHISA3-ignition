"use strict";
require("dotenv").config();
const { ethers, upgrades, artifacts } = require("hardhat");
const fs = require("fs");

async function resolveFTAddress() {
  if (process.env.FT_ADDRESS) return process.env.FT_ADDRESS;
  if (fs.existsSync("BASE_COMPLETE_ECOSYSTEM.json")) {
    try {
      const info = JSON.parse(fs.readFileSync("BASE_COMPLETE_ECOSYSTEM.json", "utf8"));
      const ft = info?.contracts?.LunaComicsFT;
      if (ft) return ft;
    } catch {}
  }
  throw new Error("FT proxy address not found (set FT_ADDRESS env or update BASE_COMPLETE_ECOSYSTEM.json)");
}

function hashCode(hexCode) {
  return ethers.keccak256(hexCode);
}

async function main() {
  const net = await ethers.provider.getNetwork();
  const networkName = process.env.HARDHAT_NETWORK || net.name || `${net.chainId}`;
  console.log("🔍 Verify FT Upgrade • network:", networkName, `(chainId=${net.chainId})`);

  const proxyAddr = await resolveFTAddress();
  console.log("📍 Proxy address:", proxyAddr);

  const codeProxy = await ethers.provider.getCode(proxyAddr);
  if (codeProxy === "0x") throw new Error("Proxy address has no code on this network.");
  console.log("📦 Proxy code size:", (codeProxy.length - 2) / 2, "bytes");

  // Implementation address via ERC1967 slot
  const implAddr = await upgrades.erc1967.getImplementationAddress(proxyAddr);
  console.log("🧠 Implementation address:", implAddr);
  const codeImpl = await ethers.provider.getCode(implAddr);
  console.log("📦 Implementation code size:", (codeImpl.length - 2) / 2, "bytes");
  console.log("🔐 Implementation code hash:", hashCode(codeImpl));

  // Admin (Transparent proxies block admin from calling implementation functions)
  let adminAddr;
  try {
    adminAddr = await upgrades.erc1967.getAdminAddress(proxyAddr);
    console.log("👑 Proxy admin:", adminAddr);
  } catch (e) {
    console.log("👑 Proxy admin: <unavailable>");
  }

  // Load local artifact
  let artifact;
  try {
    artifact = await artifacts.readArtifact("contracts/ft/CosmixProtocolToken.sol:CosmixProtocolToken");
  } catch (e) {
    throw new Error("Cannot read local artifact for CosmixProtocolToken (FQN). Compile first.");
  }

  const abiFnNames = artifact.abi.filter(f => f.type === "function").map(f => f.name);
  console.log("🧪 Local ABI functions count:", abiFnNames.length);
  console.log("🧪 Local ABI functions (first 20):", abiFnNames.slice(0, 20).join(", "));

  const expectedNewFns = ["tokensPerEth", "mintWithEth", "setTokensPerEth", "withdrawEther"];
  const missingInLocal = expectedNewFns.filter(n => !abiFnNames.includes(n));
  if (missingInLocal.length) {
    console.warn("⚠️ Local artifact missing expected new functions:", missingInLocal.join(", "));
    console.warn("   → Il file sorgente potrebbe non includere le modifiche o serve ricompilare.");
  }

  // Attach proxy with local ABI to test presence through delegatecall
  const ftProxy = await ethers.getContractAt("contracts/ft/CosmixProtocolToken.sol:CosmixProtocolToken", proxyAddr);
  const proxyFnNames = ftProxy.interface.fragments.filter(f => f.type === "function").map(f => f.name);
  console.log("🧪 Proxy (via ABI) functions count:", proxyFnNames.length);

  // Check if new functions are callable
  const report = [];
  for (const fn of expectedNewFns) {
    const present = proxyFnNames.includes(fn);
    report.push({ fn, present });
  }
  console.log("🔎 Presence of new functions:");
  report.forEach(r => console.log(`  ${r.present ? "✅" : "❌"} ${r.fn}`));

  // Attempt static calls if present (skip if signer is admin of a Transparent proxy)
  let staticDiagnostics = [];
  let skipStatic = false;
  try {
    const [signer] = await ethers.getSigners();
    if (adminAddr && signer.address.toLowerCase() === adminAddr.toLowerCase()) {
      skipStatic = true;
      console.warn("⚠️ Il signer corrente è il Proxy Admin: le chiamate al proxy in modalità Transparent vengono bloccate e possono revertare.");
    }
  } catch {}
  if (!skipStatic && proxyFnNames.includes("tokensPerEth")) {
    try {
      const val = await ftProxy.tokensPerEth();
      staticDiagnostics.push({ fn: "tokensPerEth()", ok: true, value: val.toString() });
    } catch (e) {
      staticDiagnostics.push({ fn: "tokensPerEth()", ok: false, err: e.message || e });
    }
  }
  if (!skipStatic && proxyFnNames.includes("mintWithEth")) {
    try {
      const [signer] = await ethers.getSigners();
      const testEthStr = process.env.FT_TEST_ETH || "0.0003";
      const out = await ftProxy.mintWithEth.staticCall(signer.address, 0, { value: ethers.parseEther(testEthStr) });
      staticDiagnostics.push({ fn: `mintWithEth(static ${testEthStr} ETH)`, ok: true, value: out.toString() });
    } catch (e) {
      staticDiagnostics.push({ fn: "mintWithEth(static)", ok: false, err: e.message || e });
    }
  }
  console.log("🧪 Static diagnostics:");
  staticDiagnostics.forEach(d => console.log(`  ${d.ok ? "✅" : "❌"} ${d.fn}${d.value ? " → " + d.value : d.err ? " :: " + d.err : ""}`));

  // Function selector presence check inside implementation runtime bytecode
  const iface = ftProxy.interface;
  const selectorReport = [];
  for (const fn of expectedNewFns) {
    if (!proxyFnNames.includes(fn)) {
      selectorReport.push({ fn, present: false, inBytecode: false });
      continue;
    }
    try {
      const fragment = iface.getFunction(fn);
      const signature = fragment.format(); // e.g. tokensPerEth()
      // Compute selector (first 4 bytes of keccak256)
      const selector = ethers.keccak256(Buffer.from(signature)).substring(2, 10); // 8 hex chars
      const inBytecode = codeImpl.toLowerCase().includes(selector.toLowerCase());
      selectorReport.push({ fn, present: true, selector, inBytecode });
    } catch (e) {
      selectorReport.push({ fn, present: true, selector: "<error>", inBytecode: false, err: e.message || e });
    }
  }
  console.log("🔬 Selector scan (implementation bytecode contains selector):");
  selectorReport.forEach(r => console.log(`  ${r.present ? (r.inBytecode ? "✅" : "⚠️") : "❌"} ${r.fn}${r.selector ? ` [${r.selector}]` : ""}${r.err ? " :: " + r.err : ""}`));

  // Determine PASS: require all expected functions present AND all selectors found AND successful static read of tokensPerEth (unless skipped due to admin)
  const tokensPerEthDiag = staticDiagnostics.find(d => d.fn.startsWith("tokensPerEth"));
  const allFnPresent = report.every(r => r.present);
  const allSelectorsPresent = selectorReport.every(r => r.present && r.inBytecode);
  const tokensPerEthStaticOk = skipStatic ? true : (tokensPerEthDiag ? tokensPerEthDiag.ok : false);
  let pass = allFnPresent && allSelectorsPresent && tokensPerEthStaticOk;

  if (!pass) {
    console.log("\n❌ Upgrade verification FAILED (criteri avanzati)");
    if (!allFnPresent) console.log(" - Mancano funzioni nell'ABI proxy.");
    if (!allSelectorsPresent) console.log(" - Uno o più selector non trovati nel bytecode implementation.");
    if (!tokensPerEthStaticOk) console.log(" - Lettura statica tokensPerEth non riuscita (revert o assente)." + (skipStatic ? " (Saltata per admin)" : ""));
  } else {
    console.log("\n✅ Upgrade verification PASS avanzato: funzioni, selector e lettura tokensPerEth validi." + (skipStatic ? " (static skip per admin)" : ""));
  }

  // Qualificatore: se tokensPerEth = 0 (e static ok) avvisa che serve configurazione
  if (pass && !skipStatic && tokensPerEthDiag && tokensPerEthDiag.ok) {
    try {
      const val = await ftProxy.tokensPerEth();
      if (val === 0n) {
        console.log("⚠️ PASS condizionato: tokensPerEth è 0. Imposta un rate > 0 con setTokensPerEth prima di procedere in produzione.");
      }
    } catch {}
  }

  // Root cause analysis
  if (!pass) {
    console.log("Possibili cause aggiuntive:");
    console.log(" - Proxy non aggiornato correttamente o chain non sincronizzata.");
    console.log(" - Artifacts stantii: ricompila (clean + compile) e ripeti.");
    console.log(" - Funzioni presenti nell'ABI ma non nel bytecode: controlla duplicati o naming.");
    console.log(" - Revert su tokensPerEth: se proxy è Transparent ed usi admin, prova con signer non-admin.");
    try {
      const src = fs.readFileSync("contracts/ft/CosmixProtocolToken.sol", "utf8");
      const hasSourceTokensPerEth = /tokensPerEth/.test(src);
      console.log(`Sorgente contiene 'tokensPerEth': ${hasSourceTokensPerEth ? "SI" : "NO"}`);
    } catch {}
  }

  // Exit code for CI
  if (!pass) process.exitCode = 1;
}

main().catch(e => {
  console.error("Verify upgrade error:", e.message || e);
  process.exitCode = 1;
});
