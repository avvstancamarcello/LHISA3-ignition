// scripts/check-upgradeability-detailed.cjs
const { ethers, upgrades } = require("hardhat");

async function checkUpgradeability(contractAddress, name) {
  try {
    console.log(`\n🔍 Analisi ${name} (${contractAddress})...`);
    
    // 1. Verifica se è proxy UUPS
    const implementation = await upgrades.erc1967.getImplementationAddress(contractAddress);
    console.log(`   ✅ Implementation: ${implementation}`);
    
    // 2. Verifica se è contratto valido
    const code = await ethers.provider.getCode(contractAddress);
    console.log(`   📦 Code length: ${code.length} bytes`);
    
    // 3. Verifica admin slot
    try {
      const admin = await upgrades.erc1967.getAdminAddress(contractAddress);
      console.log(`   👑 Admin: ${admin}`);
    } catch (e) {
      console.log(`   ⚠️  Admin non disponibile: ${e.message}`);
    }
    
    return { upgradeable: true, implementation };
  } catch (error) {
    console.log(`   ❌ NON upgradeable: ${error.message}`);
    return { upgradeable: false, error: error.message };
  }
}

async function main() {
  console.log("🎯 VERIFICA COMPLETA UPGRADEABILITY ECOSYSTEM");
  
  const contracts = [
    { address: "0xa0DA23b54D9D435acD1c7dD01E36CA2f1eAc4F8A", name: "SolidaryComix NFT" },
    { address: "0xC3b8B00a45F66821b885a1372434D1072D6b6B77", name: "RefundManager Solidary" },
    { address: "0x4879570a9268a94BCcb8731ecb95E39bdb5EBC0C", name: "Comix Token" }
  ];

  const results = {};
  
  for (const contract of contracts) {
    results[contract.name] = await checkUpgradeability(contract.address, contract.name);
  }
  
  console.log("\n📊 RIEPILOGO UPGRADEABILITY:");
  console.log("============================");
  
  let allUpgradeable = true;
  for (const [name, result] of Object.entries(results)) {
    const status = result.upgradeable ? "✅ UPGRADEABLE" : "❌ NOT UPGRADEABLE";
    console.log(`   ${name}: ${status}`);
    if (!result.upgradeable) allUpgradeable = false;
  }
  
  if (allUpgradeable) {
    console.log("\n🎉 TUTTI I CONTRATTI SONO UPGRADEABLE!");
    console.log("🚀 Puoi procedere con gli upgrade");
  } else {
    console.log("\n⚠️  ALCUNI CONTRATTI NON SONO UPGRADEABLE");
    console.log("📋 Necessaria strategia di migrazione");
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
