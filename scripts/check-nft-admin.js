require('dotenv').config();
const { ethers } = require('hardhat');

// Configurazione: puoi mettere NFT_ADDRESS e WALLET_ADDRESS nel .env
const NFT_ADDRESS = process.env.NFT_ADDRESS || "0x729f6225ED8fec69CdA7F98C2B5405C4Ce524b03";
const WALLET_ADDRESS = process.env.WALLET_ADDRESS || null;

async function main() {
  const signers = await ethers.getSigners();
  const signer = signers[0];
  const wallet = WALLET_ADDRESS || signer.address;

  console.log('📍 Network provider:', (await signer.provider.getNetwork()).name || await signer.provider.getNetwork());
  console.log('🔎 Controllo ruolo DEFAULT_ADMIN_ROLE sul contratto NFT');
  console.log('   Contract:', NFT_ADDRESS);
  console.log('   Wallet:', wallet);

  // Usa il fully-qualified name per evitare ambiguità
  const nft = await ethers.getContractAt('contracts/nft/OceanMangaNFT.sol:OceanMangaNFT', NFT_ADDRESS);

  // Legge il valore del ruolo DEFAULT_ADMIN_ROLE
  let defaultAdminRole;
  try {
    defaultAdminRole = await nft.DEFAULT_ADMIN_ROLE();
  } catch (e) {
    console.error('❌ Errore: DEFAULT_ADMIN_ROLE() non disponibile sul contratto NFT', e);
    process.exit(1);
  }

  // Verifica hasRole
  try {
    const isAdmin = await nft.hasRole(defaultAdminRole, wallet);
    console.log(`➡️  Il wallet ${wallet} ha DEFAULT_ADMIN_ROLE sul contratto NFT?`, isAdmin ? '✅ SÌ' : '❌ NO');
  } catch (e) {
    console.error('❌ Errore durante la chiamata hasRole:', e);
    process.exit(1);
  }
}

main().catch((err) => {
  console.error('Script fallito:', err);
  process.exit(1);
});
