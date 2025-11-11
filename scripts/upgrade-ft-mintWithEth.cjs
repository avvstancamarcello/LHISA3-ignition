"use strict";
require("dotenv").config();
const { ethers, upgrades, run } = require("hardhat");
const fs = require("fs");

async function resolveFTAddress() {
  // Priority: ENV -> BASE_COMPLETE_ECOSYSTEM.json
  if (process.env.FT_ADDRESS) return process.env.FT_ADDRESS;
  if (fs.existsSync("BASE_COMPLETE_ECOSYSTEM.json")) {
    try {
      const info = JSON.parse(fs.readFileSync("BASE_COMPLETE_ECOSYSTEM.json", "utf8"));
      const ft = info?.contracts?.LunaComicsFT;
      if (ft) return ft;
    } catch {}
  }
  throw new Error("FT proxy address not found. Set FT_ADDRESS env or update BASE_COMPLETE_ECOSYSTEM.json");
}

async function main() {
  const net = await ethers.provider.getNetwork();
  const networkName = process.env.HARDHAT_NETWORK || net.name || `${net.chainId}`;
  console.log("🔧 UUPS Upgrade • network:", networkName, `(chainId=${net.chainId})`);

  // Force a fresh compile to ensure ABI and bytecode are up-to-date
  try {
    console.log("🧼 Cleaning & compiling project...");
    await run("clean");
    await run("compile");
  } catch (e) {
    console.warn("⚠️  Clean/compile step failed or not needed:", e?.message || e);
  }

  const ftProxy = await resolveFTAddress();
  console.log("📍 FT (proxy):", ftProxy);

  // Ensure address has code
  const code = await ethers.provider.getCode(ftProxy);
  if (!code || code === "0x") {
    throw new Error(`No contract at FT address on this network (${networkName}).`);
  }

  // Prepare new implementation
  const FT = await ethers.getContractFactory("contracts/ft/CosmixProtocolToken.sol:CosmixProtocolToken");
  console.log("⏫ Upgrading proxy...");
  const upgraded = await upgrades.upgradeProxy(ftProxy, FT);
  await upgraded.waitForDeployment?.();
  console.log("✅ Proxy upgraded.");

  const implAddr = await upgrades.erc1967.getImplementationAddress(ftProxy);
  console.log("🧠 New implementation:", implAddr);

  // Post-upgrade sanity: set tokensPerEth if unset
  const ft = await ethers.getContractAt("contracts/ft/CosmixProtocolToken.sol:CosmixProtocolToken", ftProxy);
  const fnNames = ft.interface.fragments.filter(f => f.type === "function").map(f => f.name);
  console.log("🧪 ABI functions:", fnNames.join(", "));
  if (!fnNames.includes("tokensPerEth")) {
    throw new Error("tokensPerEth assente nell'ABI. Esegui 'npx hardhat clean && npx hardhat compile' prima dell'upgrade, oppure verifica il percorso del contratto.");
  }
  let current = await ft.tokensPerEth();
  console.log("ℹ️  tokensPerEth current:", current.toString());
  if (current === 0n) {
    const rateStr = process.env.FT_TOKENS_PER_ETH || "1000"; // default 1000 tokens per 1 ETH
    const rate = ethers.parseEther(rateStr);
    console.log(`🛠️  Setting tokensPerEth to ${rateStr}e18 ...`);
    const tx = await ft.setTokensPerEth(rate);
    const rc = await tx.wait();
    console.log("✅ tokensPerEth set. tx:", rc?.hash || tx.hash);
  }

  // Optional dry-run (static) for mintWithEth
  try {
    const [signer] = await ethers.getSigners();
    const sampleEthStr = process.env.FT_TEST_ETH || "0.001";
    const sampleEth = ethers.parseEther(sampleEthStr);
    console.log(`🔎 Dry-run mintWithEth.staticCall with ${sampleEthStr} ETH ...`);
    if (!fnNames.includes("mintWithEth")) {
      console.warn("⚠️  mintWithEth non presente nell'ABI (upgrade non include la funzione?). Saltando dry-run.");
    } else {
      const out = await ft.mintWithEth.staticCall(signer.address, 0, { value: sampleEth });
      console.log("✅ mintWithEth.staticCall OK, out:", out.toString());
    }
  } catch (e) {
    const msg = e?.reason || e?.message || String(e);
    if (/missing role|AccessControl/i.test(msg)) {
      console.warn("⚠️  mintWithEth.staticCall non eseguibile con il signer corrente (MINTER_ROLE mancante). La funzione è presente e protetta.");
    } else {
      console.warn("⚠️  mintWithEth.staticCall non disponibile:", msg);
    }
  }

  console.log("—— Summary ——");
  console.log("PASS");
}

main().catch((e) => {
  console.error("Upgrade error:", e?.message || e);
  process.exitCode = 1;
});
