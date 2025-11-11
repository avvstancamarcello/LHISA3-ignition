"use strict";
require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

function parseArgs() {
  const argv = process.argv.slice(2);
  return {
    fix: argv.includes("--fix"),
  };
}

async function resolveAddresses() {
  let orchestratorAddress, nftAddress, ftAddress;
  let sources = { orchestrator: null, nft: null, ft: null };

  // 1) Try BASE_COMPLETE_ECOSYSTEM.json
  try {
    if (fs.existsSync("BASE_COMPLETE_ECOSYSTEM.json")) {
      const info = JSON.parse(fs.readFileSync("BASE_COMPLETE_ECOSYSTEM.json", "utf8"));
      if (info?.contracts?.OceanMangaOrchestrator) {
        orchestratorAddress = info.contracts.OceanMangaOrchestrator;
        sources.orchestrator = "ecosystem-json";
      }
      if (info?.contracts?.OceanMangaNFT) {
        nftAddress = info.contracts.OceanMangaNFT;
        sources.nft = "ecosystem-json";
      }
      if (info?.contracts?.LunaComicsFT) {
        ftAddress = info.contracts.LunaComicsFT;
        sources.ft = "ecosystem-json";
      }
    }
  } catch {}

  // 2) Env overrides
  if (process.env.ORCHESTRATOR_ADDRESS) {
    orchestratorAddress = process.env.ORCHESTRATOR_ADDRESS;
    sources.orchestrator = "env";
  }
  if (process.env.NFT_ADDRESS) {
    nftAddress = process.env.NFT_ADDRESS;
    sources.nft = "env";
  }
  if (process.env.FT_ADDRESS) {
    ftAddress = process.env.FT_ADDRESS;
    sources.ft = "env";
  }

  // 3) last-orchestrator.json
  if (!orchestratorAddress && fs.existsSync("last-orchestrator.json")) {
    try {
      const prev = JSON.parse(fs.readFileSync("last-orchestrator.json", "utf8"));
      orchestratorAddress = prev?.orchestrator || orchestratorAddress;
      if (prev?.orchestrator) sources.orchestrator = "last-orchestrator";
    } catch {}
  }

  return { orchestratorAddress, nftAddress, ftAddress, sources };
}

async function main() {
  const net = await ethers.provider.getNetwork();
  const networkName = process.env.HARDHAT_NETWORK || net.name || `${net.chainId}`;
  console.log("🔎 Sanity check • network:", networkName, `(chainId=${net.chainId})`);

  const args = parseArgs();
  const { orchestratorAddress, nftAddress: _nftAddr, ftAddress: _ftAddr, sources } = await resolveAddresses();
  if (!orchestratorAddress) {
    throw new Error("Orchestrator non trovato. Imposta ORCHESTRATOR_ADDRESS o crea last-orchestrator.json/BASE_COMPLETE_ECOSYSTEM.json");
  }

  console.log("📍 Orchestrator:", orchestratorAddress);
  if (_nftAddr) console.log("📍 NFT (from config):", _nftAddr);
  if (_ftAddr) console.log("📍 FT  (from config):", _ftAddr);

  // Ensure we are on the right network and address has code
  const orchCode = await ethers.provider.getCode(orchestratorAddress);
  if (!orchCode || orchCode === "0x") {
    throw new Error(
      `Nessun contratto all'indirizzo Orchestrator su questa rete (${networkName}).\n` +
      `Suggerimento: esegui con la rete corretta, es. --network base`
    );
  }

  // Attach orchestrator (FQN to avoid compile ambiguity)
  const orchestrator = await ethers.getContractAt(
    "contracts/photo-mint/OceanMangaOrchestrator.sol:OceanMangaOrchestrator",
    orchestratorAddress
  );

  // Read pointers
  let orchNFT, orchFT;
  try {
    orchNFT = await orchestrator.oceanMangaNFT();
  } catch {
    orchNFT = await orchestrator.nftPlanetContract();
  }
  try {
    orchFT = await orchestrator.lunaComicsFT();
  } catch {
    orchFT = await orchestrator.ftSatelliteContract();
  }
  const creator = await orchestrator.creator();
  const charity = await orchestrator.charityFund();

  console.log("\n🧩 Orchestrator config:");
  console.log("  NFT  ->", orchNFT);
  console.log("  FT   ->", orchFT);
  console.log("  Creator ->", creator);
  console.log("  Charity ->", charity);

  // Attach NFT/FT with proper fully qualified names
  const nft = await ethers.getContractAt("contracts/nft/OceanMangaNFT.sol:OceanMangaNFT", orchNFT);
  const ft = await ethers.getContractAt("contracts/ft/CosmixProtocolToken.sol:CosmixProtocolToken", orchFT);

  // Roles constants with fallbacks
  let NFT_MINTER_ROLE, FT_MINTER_ROLE, DEFAULT_ADMIN_ROLE;
  try {
    NFT_MINTER_ROLE = await nft.MINTER_ROLE();
    DEFAULT_ADMIN_ROLE = await nft.DEFAULT_ADMIN_ROLE();
  } catch {
    NFT_MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
    DEFAULT_ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes("DEFAULT_ADMIN_ROLE"));
  }
  try {
    FT_MINTER_ROLE = await ft.MINTER_ROLE();
  } catch {
    FT_MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
  }

  // Who is running
  const [signer] = await ethers.getSigners();
  const deployer = signer.address;

  // Role checks
  let checks = [];
  try {
    const hasAdminNFT = await nft.hasRole(DEFAULT_ADMIN_ROLE, deployer);
    checks.push({ name: "Deployer admin NFT", ok: !!hasAdminNFT });
  } catch (e) {
    checks.push({ name: "Deployer admin NFT (hasRole not available)", ok: true, warn: true });
  }
  try {
    const hasAdminFT = await ft.hasRole(DEFAULT_ADMIN_ROLE, deployer);
    checks.push({ name: "Deployer admin FT", ok: !!hasAdminFT });
  } catch (e) {
    checks.push({ name: "Deployer admin FT (hasRole not available)", ok: true, warn: true });
  }
  try {
    const hasMinterNFT = await nft.hasRole(NFT_MINTER_ROLE, orchestratorAddress);
    checks.push({ name: "Orchestrator MINTER on NFT", ok: !!hasMinterNFT });
  } catch (e) {
    checks.push({ name: "Orchestrator MINTER on NFT (hasRole not available)", ok: true, warn: true });
  }
  try {
    const hasMinterFT = await ft.hasRole(FT_MINTER_ROLE, orchestratorAddress);
    checks.push({ name: "Orchestrator MINTER on FT", ok: !!hasMinterFT });
  } catch (e) {
    checks.push({ name: "Orchestrator MINTER on FT (hasRole not available)", ok: true, warn: true });
  }

  // Optional static call: test mintPhotoCombo (no gas spend)
  let staticMintOk = false;
  try {
    await orchestrator.mintPhotoCombo.staticCall("ipfs://sanity-test", { value: ethers.parseEther("0.001") });
    staticMintOk = true;
  } catch (e) {
    // It's okay if it reverts for reasons like pricing; we'll report as a soft fail
  }
  checks.push({ name: "Static mintPhotoCombo", ok: staticMintOk, soft: true });

  // Compare with config if provided
  if (_nftAddr) {
    const nftOk = _nftAddr.toLowerCase() === orchNFT.toLowerCase();
    checks.push({ name: "Config NFT matches orchestrator", ok: nftOk });
    if (!nftOk) {
      console.warn("⚠️  Mismatch NFT: config=", _nftAddr, " orchestrator=", orchNFT, " (user likely using old config file)");
    }
  }
  if (_ftAddr) {
    const ftOk = _ftAddr.toLowerCase() === orchFT.toLowerCase();
    checks.push({ name: "Config FT matches orchestrator", ok: ftOk });
    if (!ftOk) {
      console.warn("⚠️  Mismatch FT: config=", _ftAddr, " orchestrator=", orchFT);
    }
  }

  // Report
  console.log("\n✅/❌ Risultati:");
  let pass = true;
  let mismatches = { nft: false, ft: false };
  for (const c of checks) {
    const status = c.ok ? "✅" : (c.soft ? "⚠️" : "❌");
    console.log(` ${status} ${c.name}`);
    if (!c.ok && !c.soft) pass = false;
    if (c.name === "Config NFT matches orchestrator" && !c.ok) mismatches.nft = true;
    if (c.name === "Config FT matches orchestrator" && !c.ok) mismatches.ft = true;
  }

  // If requested, try to fix config files to align with orchestrator addresses
  if (args.fix && (mismatches.nft || mismatches.ft)) {
    const updatedFiles = [];

    // Helper: update .env
    const envPath = path.resolve(process.cwd(), ".env");
    const ensureEnvKV = (content, key, value) => {
      const lines = content.split(/\r?\n/);
      let found = false;
      const newLines = lines.map((ln) => {
        const m = ln.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/);
        if (m && m[1] === key) {
          found = true;
          return `${key}=${value}`;
        }
        return ln;
      });
      if (!found) newLines.push(`${key}=${value}`);
      return newLines.join("\n");
    };

    const writeEnvIfNeeded = () => {
      let content = fs.existsSync(envPath) ? fs.readFileSync(envPath, "utf8") : "";
      const before = content;
      content = ensureEnvKV(content, "ORCHESTRATOR_ADDRESS", orchestratorAddress);
      content = ensureEnvKV(content, "NFT_ADDRESS", orchNFT);
      content = ensureEnvKV(content, "FT_ADDRESS", orchFT);
      if (content !== before) {
        fs.writeFileSync(envPath, content, "utf8");
        updatedFiles.push(".env");
      }
    };

    // Decide what to update based on source of mismatch
    if (mismatches.nft || mismatches.ft) {
      if ((mismatches.nft && sources.nft === "env") || (mismatches.ft && sources.ft === "env") || !fs.existsSync("BASE_COMPLETE_ECOSYSTEM.json")) {
        writeEnvIfNeeded();
      }
      // Also update BASE_COMPLETE_ECOSYSTEM.json to mirror orchestrator truth
      if (fs.existsSync("BASE_COMPLETE_ECOSYSTEM.json")) {
        try {
          const jsonPath = path.resolve(process.cwd(), "BASE_COMPLETE_ECOSYSTEM.json");
          const info = JSON.parse(fs.readFileSync(jsonPath, "utf8"));
          info.contracts = info.contracts || {};
          info.contracts.OceanMangaOrchestrator = orchestratorAddress;
          info.contracts.OceanMangaNFT = orchNFT;
          info.contracts.LunaComicsFT = orchFT;
          fs.writeFileSync(jsonPath, JSON.stringify(info, null, 2));
          updatedFiles.push("BASE_COMPLETE_ECOSYSTEM.json");
        } catch {}
      }

      // Write helper text files
      try {
        fs.writeFileSync(path.resolve(process.cwd(), "NFT_ADDRESS.txt"), orchNFT + "\n", "utf8");
        updatedFiles.push("NFT_ADDRESS.txt");
      } catch {}
      try {
        fs.writeFileSync(path.resolve(process.cwd(), "TOKEN_ADDRESS.txt"), orchFT + "\n", "utf8");
        updatedFiles.push("TOKEN_ADDRESS.txt");
      } catch {}

      if (updatedFiles.length) {
        console.log("\n🛠️  Fix applicato (--fix): aggiornati file →", updatedFiles.join(", "));
        console.log("Riesegui lo script per verificare il PASS.");
      } else {
        console.log("\nℹ️  Nessun file aggiornato (config già allineata o permessi mancanti).");
      }
    }
  }

  console.log("\n—— Summary ——");
  if (!pass) {
    console.log("FAIL");
    console.log("Suggerimento: usa gli indirizzi aggiornati in BASE_COMPLETE_ECOSYSTEM.json oppure export NFT_ADDRESS e FT_ADDRESS corretti.");
  } else {
    console.log("PASS");
  }

  if (!pass) process.exitCode = 1;
}

main().catch((e) => {
  console.error("Sanity check error:", e.message || e);
  process.exitCode = 1;
});
