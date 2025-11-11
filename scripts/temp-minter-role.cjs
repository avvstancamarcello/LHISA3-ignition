"use strict";
require("dotenv").config();
const { ethers } = require("hardhat");
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

async function main() {
  const net = await ethers.provider.getNetwork();
  const networkName = process.env.HARDHAT_NETWORK || net.name || `${net.chainId}`;
  console.log("🔐 Temp MINTER_ROLE • network:", networkName, `(chainId=${net.chainId})`);

  const ftAddress = await resolveFTAddress();
  console.log("📍 FT:", ftAddress);

  const signer = (await ethers.getSigners())[0];
  const signerAddr = signer.address;
  console.log("👤 Signer:", signerAddr);

  // Attach token (fully-qualified name after upgrade)
  const ft = await ethers.getContractAt("contracts/ft/CosmixProtocolToken.sol:CosmixProtocolToken", ftAddress);
  // Diagnostics: elenco funzioni disponibili
  const functionNames = ft.interface.fragments.filter(f => f.type === "function").map(f => f.name);
  console.log("🧪 ABI functions:", functionNames.join(", "));
  const hasMintWithEth = functionNames.includes("mintWithEth");
  const MINTER_ROLE = await ft.MINTER_ROLE();
  const hasAlready = await ft.hasRole(MINTER_ROLE, signerAddr);

  let granted = false;
  if (!hasAlready) {
    console.log("➡️  Granting MINTER_ROLE to signer (temporary)...");
    const tx = await ft.grantRole(MINTER_ROLE, signerAddr);
    await tx.wait();
    granted = true;
    console.log("✅ Granted.");
  } else {
    console.log("ℹ️  Signer already has MINTER_ROLE.");
  }

  // Perform a staticCall to validate mintWithEth
  if (hasMintWithEth) {
    try {
      const testEthStr = process.env.FT_TEST_ETH || "0.0005";
      const testEth = ethers.parseEther(testEthStr);
      console.log(`🔎 Testing mintWithEth.staticCall with ${testEthStr} ETH ...`);
      const out = await ft.mintWithEth.staticCall(signerAddr, 0, { value: testEth });
      console.log("✅ Static mintWithEth OK. Output tokens:", out.toString());
    } catch (e) {
      console.error("❌ Static mintWithEth failed:", e.message || e);
    }
  } else {
    console.warn("⚠️  mintWithEth non presente nell'ABI caricata. Probabile mancata ricompilazione o upgrade non applicato.");
    console.warn("   Suggerimento: esegui 'npx hardhat clean && npx hardhat compile' e poi 'npm run upgrade:ft:base'.");
  }

  // If we granted temporarily, revoke (or renounce) to restore prior state
  if (granted) {
    console.log("↩️  Revoking temporary MINTER_ROLE (via renounceRole)...");
    const tx2 = await ft.renounceRole(MINTER_ROLE, signerAddr);
    await tx2.wait();
    console.log("✅ Role renounced.");
  }

  console.log("—— Summary ——");
  console.log("PASS");
}

main().catch((e) => {
  console.error("Temp role script error:", e.message || e);
  process.exitCode = 1;
});
