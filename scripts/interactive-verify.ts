// scripts/interactive-verify.ts
import { ethers } from "hardhat";

async function main() {
  console.log("🔍 Interactive Contract Verification");
  
  // Lista di possibili nomi di contratti
  const possibleNames = {
    hub: ["SolidaryHub", "Solidary_Hub", "Hub", "InfrastructureHub"],
    oraculum: ["OraculumCaritatis", "Oraculum", "CharityOracle", "JusticeSystem"]
  };

  const addresses = {
    hub: "0xE9458CdA8e3dA88E1b1588EeCd6b1CFE2A398602",
    oraculum: "0xcc516a4374021d4a959A6887F2b1501F372f27F6"
  };

  // Prova diversi nomi di contratto
  for (const [type, address] of Object.entries(addresses)) {
    console.log(`\n🔎 Testing ${type} at ${address}`);
    
    for (const contractName of possibleNames[type]) {
      try {
        const factory = await ethers.getContractFactory(contractName);
        const contract = factory.attach(address);
        const owner = await contract.owner();
        console.log(`✅ FOUND: ${contractName} - Owner: ${owner}`);
        break;
      } catch (error) {
        console.log(`   ❌ ${contractName}: ${error.message}`);
      }
    }
  }
}

main().catch(console.error);
