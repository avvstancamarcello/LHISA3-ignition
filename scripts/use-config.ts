import { DOUBLE_STAR_ECOSYSTEM } from "../config/double-star-ecosystem-complete";

async function main() {
  console.log("🌌 DoubleStar Ecosystem Info:");
  console.log("Network:", DOUBLE_STAR_ECOSYSTEM.NETWORK);
  console.log("Status:", DOUBLE_STAR_ECOSYSTEM.STATUS);
  
  console.log("\n🏗️ Deployed Contracts:");
  Object.entries(DOUBLE_STAR_ECOSYSTEM.TRIPLE_LAYER_ARCHITECTURE).forEach(([layer, info]) => {
    console.log(`- ${layer}: ${info.contract} (${info.address})`);
  });
}

main().catch(console.error);
