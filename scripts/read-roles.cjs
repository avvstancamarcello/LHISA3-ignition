"use strict";
require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");

const AC_ABI = [
  "function getRoleAdmin(bytes32 role) view returns (bytes32)",
  "function hasRole(bytes32 role, address account) view returns (bool)",
  "function DEFAULT_ADMIN_ROLE() view returns (bytes32)",
  "function MINTER_ROLE() view returns (bytes32)",
  "function MANAGER_ROLE() view returns (bytes32)",
  "function UPGRADER_ROLE() view returns (bytes32)",
  "function EMERGENCY_ROLE() view returns (bytes32)",
];

const EVENTS_ABI = [
  "event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)",
  "event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)",
  "event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)",
];

const EVENTS_IFACE = new ethers.Interface(EVENTS_ABI);
const SIG = {
  RoleGranted: EVENTS_IFACE.getEvent("RoleGranted").topicHash,
  RoleRevoked: EVENTS_IFACE.getEvent("RoleRevoked").topicHash,
  RoleAdminChanged: EVENTS_IFACE.getEvent("RoleAdminChanged").topicHash,
};

const ROLE_NAMES = [
  "DEFAULT_ADMIN_ROLE",
  "MINTER_ROLE",
  "MANAGER_ROLE",
  "UPGRADER_ROLE",
  "EMERGENCY_ROLE",
];

// Runtime options (env)
const VERBOSE = /^(1|true|yes)$/i.test(process.env.VERBOSE || "");
const QUIET = /^(1|true|yes)$/i.test(process.env.QUIET || "");
const DISABLE_LOG_SCAN = /^(1|true|yes)$/i.test(process.env.DISABLE_LOG_SCAN || "");
const PROGRESS_EVERY = Number(process.env.PROGRESS_EVERY || 50); // print progress every N chunks
const MAX_EVENTS = Number(process.env.MAX_EVENTS || 0); // 0 = unlimited
const MAX_CHUNKS = Number(process.env.MAX_CHUNKS || 0); // 0 = unlimited
const DEFAULT_CHUNK_SIZE = Number(process.env.CHUNK_SIZE || 5000);

function loadEcosystem() {
  if (fs.existsSync("BASE_COMPLETE_ECOSYSTEM.json")) {
    try {
      return JSON.parse(fs.readFileSync("BASE_COMPLETE_ECOSYSTEM.json", "utf8"));
    } catch {}
  }
  return null;
}

function resolveAddress(name, envKey, jsonKey, eco) {
  if (process.env[envKey]) return process.env[envKey];
  if (eco && eco.contracts && eco.contracts[jsonKey]) return eco.contracts[jsonKey];
  throw new Error(`Indirizzo ${name} non trovato. Imposta ${envKey} o aggiorna BASE_COMPLETE_ECOSYSTEM.json`);
}

async function getRoleConstants(contract) {
  const out = {};
  for (const n of ROLE_NAMES) {
    try { out[n] = await contract[n](); } catch { /* ignore if missing */ }
  }
  return out;
}

async function scanAccessControlLogs(address, fromBlock, toBlock) {
  const grants = [];
  const revokes = [];
  const admins = [];
  const provider = ethers.provider;

  const CHUNK = DEFAULT_CHUNK_SIZE;
  const start = Number(fromBlock);
  const end = Number(toBlock);

  async function fetchChunk(topic, a, b, depth = 0) {
    try {
      return await provider.getLogs({ address, fromBlock: a, toBlock: b, topics: [topic] });
    } catch (e) {
      // If range too big or provider limit, split recursively.
      const span = b - a;
      if (span <= 100) throw e; // stop splitting when very small
      const mid = Math.floor((a + b) / 2);
      const left = await fetchChunk(topic, a, mid, depth + 1);
      const right = await fetchChunk(topic, mid + 1, b, depth + 1);
      return left.concat(right);
    }
  }

  const totalSpan = end - start;
  if (!QUIET) console.log(`↳ Scansione log ${address} blocchi ${start}-${end} (span=${totalSpan}) CHUNK=${CHUNK}`);

  let chunkIndex = 0;
  for (let a = start; a <= end; a += (CHUNK + 1)) {
    const b = Math.min(a + CHUNK, end);
    chunkIndex += 1;
    if (VERBOSE && !QUIET) {
      process.stdout.write(`  • blocchi ${a}-${b} ... `);
    } else if (!QUIET && (chunkIndex % PROGRESS_EVERY === 0 || a === start)) {
      process.stdout.write(`  • progress: chunk ${chunkIndex} range ${a}-${b}\r`);
    }
    try {
      const [lg, lr, la] = await Promise.all([
        fetchChunk(SIG.RoleGranted, a, b),
        fetchChunk(SIG.RoleRevoked, a, b),
        fetchChunk(SIG.RoleAdminChanged, a, b),
      ]);
      lg.forEach(l => { const ev = EVENTS_IFACE.parseLog(l); grants.push({ blockNumber: l.blockNumber, logIndex: l.logIndex, role: ev.args.role, account: ev.args.account }); });
      lr.forEach(l => { const ev = EVENTS_IFACE.parseLog(l); revokes.push({ blockNumber: l.blockNumber, logIndex: l.logIndex, role: ev.args.role, account: ev.args.account }); });
      la.forEach(l => { const ev = EVENTS_IFACE.parseLog(l); admins.push({ blockNumber: l.blockNumber, logIndex: l.logIndex, role: ev.args.role, prev: ev.args.previousAdminRole, next: ev.args.newAdminRole }); });
      if (VERBOSE && !QUIET) process.stdout.write(`ok (+${lg.length}/${lr.length}/${la.length})\n`);
    } catch (e) {
      if (VERBOSE && !QUIET) process.stdout.write(`errore: ${(e && e.message) || e}\n`);
    }
    if (MAX_CHUNKS > 0 && chunkIndex >= MAX_CHUNKS) break;
    if (MAX_EVENTS > 0 && (grants.length + revokes.length + admins.length) >= MAX_EVENTS) break;
  }
  if (!QUIET && !VERBOSE) process.stdout.write("\n");

  const entries = [];
  grants.forEach(x => entries.push({ type: "grant", ...x }));
  revokes.forEach(x => entries.push({ type: "revoke", ...x }));
  entries.sort((a, b) => a.blockNumber - b.blockNumber || a.logIndex - b.logIndex);

  const roleMembers = new Map();
  for (const e of entries) {
    const key = e.role.toLowerCase();
    if (!roleMembers.has(key)) roleMembers.set(key, new Set());
    const set = roleMembers.get(key);
    if (e.type === "grant") set.add(e.account.toLowerCase());
    else if (e.type === "revoke") set.delete(e.account.toLowerCase());
  }

  return { roleMembers, admins };
}

function nameForRole(bytes32, constants) {
  const hex = (bytes32 || "").toLowerCase();
  for (const [n, v] of Object.entries(constants)) {
    if (v && v.toLowerCase && v.toLowerCase() === hex) return `${n}`;
  }
  return hex;
}

async function summarizeContractRoles(label, address, extraCandidates = []) {
  console.log(`\n===== ${label} @ ${address} =====`);
  const ac = new ethers.Contract(address, AC_ABI, ethers.provider);
  const net = await ethers.provider.getNetwork();
  const latest = await ethers.provider.getBlockNumber();
  const fromBlock = Number(process.env.START_BLOCK || 0);
  const toBlock = Number(process.env.END_BLOCK || latest);
  const constants = await getRoleConstants(ac);

  // Scan logs (unless disabled)
  let scan = { roleMembers: new Map(), admins: [] };
  if (!DISABLE_LOG_SCAN) {
    try {
      scan = await scanAccessControlLogs(address, fromBlock, toBlock);
    } catch (e) {
      console.warn(`⚠️ Impossibile leggere i log per ${label}:`, e.message || e);
    }
  } else if (!QUIET) {
    console.log("(log scan disabilitata: DISABLE_LOG_SCAN=1)");
  }

  // Build display per known role names
  const rolesToShow = Object.entries(constants).filter(([n, v]) => v);
  for (const [roleName, roleHash] of rolesToShow) {
    const key = roleHash.toLowerCase();
    const members = new Set(scan.roleMembers.get(key) || []);
    // Probe extra candidates via hasRole
    for (const cand of extraCandidates) {
      if (!cand) continue;
      try {
        const has = await ac.hasRole(roleHash, cand);
        if (has) members.add(cand.toLowerCase());
      } catch {}
    }
    const adminHash = await ac.getRoleAdmin(roleHash).catch(() => null);
    const adminName = adminHash ? nameForRole(adminHash, constants) : "<unknown>";

    const list = [...members].map(a => ethers.getAddress(a));
    console.log(`\n• ${roleName}`);
    console.log(`  admin: ${adminName}`);
    if (list.length === 0) console.log("  members: <none>");
    else {
      console.log("  members:");
      list.forEach(a => console.log(`   - ${a}`));
    }
  }
}

async function main() {
  const net = await ethers.provider.getNetwork();
  const networkName = process.env.HARDHAT_NETWORK || net.name || `${net.chainId}`;
  if (!QUIET) console.log("🔎 Read Roles • network:", networkName, `(chainId=${net.chainId})`);

  const eco = loadEcosystem();
  const ft = resolveAddress("FT (proxy)", "FT_ADDRESS", "LunaComicsFT", eco);
  const orch = resolveAddress("Orchestrator", "ORCHESTRATOR_ADDRESS", "OceanMangaOrchestrator", eco);

  // Candidate addresses to probe via hasRole
  const candidates = new Set();
  const signer = (await ethers.getSigners())[0];
  candidates.add(signer.address);
  candidates.add(ft);
  candidates.add(orch);
  if (eco?.wallets?.deployer) candidates.add(eco.wallets.deployer);
  if (eco?.wallets?.creator) candidates.add(eco.wallets.creator);
  if (eco?.wallets?.charity) candidates.add(eco.wallets.charity);
  if (eco?.contracts?.TokenRouter) candidates.add(eco.contracts.TokenRouter);

  const candList = [...candidates];
  if (!QUIET) {
    console.log("👤 Signer:", signer.address);
    console.log("👥 Probe candidates:", candList.join(", "));
  }

  await summarizeContractRoles("FT (AccessControl via proxy)", ft, candList);
  await summarizeContractRoles("Orchestrator (AccessControl)", orch, candList);
}

main().catch((e) => {
  console.error("Read-roles error:", e?.message || e);
  process.exitCode = 1;
});
