// Script per automatizzare il passaggio di ownership/ruoli a un multisig
// Esegui con: npx hardhat run scripts/transfer-ownership-multisig.js --network <network>

const { ethers } = require("hardhat");

// Inserisci qui l'indirizzo del multisig
const MULTISIG = "0xbe5405162EA2284F5890326E83ECb831d88B32f7";

// Inserisci qui gli indirizzi dei contratti da aggiornare
const CONTRACTS = [
  { name: "AirdropWhitelist", address: "<AIRDROP_CONTRACT_ADDRESS>", type: "ownable" },
  { name: "TimelockNFTVault", address: "<TIMELOCK_CONTRACT_ADDRESS>", type: "ownable" },
  { name: "COSMIX Protocol Token", address: "<COSMIX_CONTRACT_ADDRESS>", type: "accesscontrol" },
  // Aggiungi altri moduli se necessario
];

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  for (const c of CONTRACTS) {
    if (c.type === "ownable") {
      const Contract = await ethers.getContractAt(c.name, c.address);
      const owner = await Contract.owner();
      if (owner.toLowerCase() !== MULTISIG.toLowerCase()) {
        const tx = await Contract.transferOwnership(MULTISIG);
        await tx.wait();
        console.log(`Ownership di ${c.name} trasferita a multisig:`, MULTISIG);
      } else {
        console.log(`${c.name} ha già il multisig come owner.`);
      }
    } else if (c.type === "accesscontrol") {
      const Contract = await ethers.getContractAt(c.name, c.address);
      const DEFAULT_ADMIN_ROLE = await Contract.DEFAULT_ADMIN_ROLE();
      const hasRole = await Contract.hasRole(DEFAULT_ADMIN_ROLE, MULTISIG);
      if (!hasRole) {
        const tx = await Contract.grantRole(DEFAULT_ADMIN_ROLE, MULTISIG);
        await tx.wait();
        console.log(`DEFAULT_ADMIN_ROLE di ${c.name} assegnato al multisig:`, MULTISIG);
      } else {
        console.log(`${c.name} ha già il multisig come admin.`);
      }
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
