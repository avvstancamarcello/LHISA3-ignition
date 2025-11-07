#!/usr/bin/env node
// Esempio: node generate_deploy_report.js ./deploy_extraction_output.json
const fs = require('fs');
const { ethers } = require('ethers');

async function main() {
  const path = process.argv[2];
  if (!path) {
    console.error("Usage: node generate_deploy_report.js ./deploy_extraction_output.json");
    process.exit(1);
  }
  const content = JSON.parse(fs.readFileSync(path));
  // Mostra contratti rilevati
  console.log("Contracts detected:", content.contracts_deployed.length);
  for (const c of content.contracts_deployed) {
    console.log("-", c.name, c.address || "(no address)");
  }
  // Se vuoi verificare bytecode sulla rete, fornisci RPC_URL_BASE e RPC_URL_POLYGON come env
  const networks = [
    { name: 'base', url: process.env.RPC_URL_BASE },
    { name: 'polygon', url: process.env.RPC_URL_POLYGON }
  ];
  for (const net of networks) {
    if (!net.url) continue;
    const provider = new ethers.providers.JsonRpcProvider(net.url);
    console.log(`\nChecking on ${net.name}...`);
    for (const c of content.contracts_deployed) {
      if (!c.address) continue;
      try {
        const code = await provider.getCode(c.address);
        if (code && code !== '0x') {
          console.log(`Found bytecode at ${c.address} on ${net.name}`);
        } else {
          console.log(`No code at ${c.address} on ${net.name}`);
        }
      } catch (e) {
        console.log(`Error checking ${c.address} on ${net.name}: ${e.message}`);
      }
    }
  }
}

main();
