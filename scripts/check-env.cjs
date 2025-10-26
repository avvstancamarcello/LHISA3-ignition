require("dotenv").config();

console.log("🔍 ENVIRONMENT VARIABLES CHECK:");
console.log("PRIVATE_KEY length:", process.env.PRIVATE_KEY?.length || "MISSING");
console.log("PRIVATE_KEY starts with 0x?", process.env.PRIVATE_KEY?.startsWith("0x"));
console.log("BASESCAN_API_KEY exists:", !!process.env.BASESCAN_API_KEY);
console.log("NFT_STORAGE_API_KEY exists:", !!process.env.NFT_STORAGE_API_KEY);

// Verifica formato corretto
if (process.env.PRIVATE_KEY) {
  if (process.env.PRIVATE_KEY.startsWith("0x")) {
    console.log("❌ ERRORE: PRIVATE_KEY non deve iniziare con 0x");
  } else {
    console.log("✅ PRIVATE_KEY formato corretto");
  }
}
