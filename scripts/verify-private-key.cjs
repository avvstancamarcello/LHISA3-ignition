// 🎯 VERIFICA INDIPENDENTE DELLA PRIVATE KEY
const { ethers } = require("ethers");

// ✅ PRIVATE KEY DI TEST
const PRIVATE_KEY = "8f2a46c1eb83a1fcec604207c4c0e34c2b46b2d045883311509cb592b282dfb1";

console.log("🔍 VERIFICA PRIVATE KEY INDIPENDENTE");
console.log("====================================");

// 1. Verifica lunghezza
console.log("📏 Lunghezza:", PRIVATE_KEY.length, "caratteri");

// 2. Verifica formato esadecimale
const isHex = /^[0-9a-fA-F]{64}$/.test(PRIVATE_KEY);
console.log("🔢 Formato esadecimale:", isHex ? "✅ VALIDO" : "❌ INVALIDO");

// 3. Verifica che non inizi con 0x
const startsWith0x = PRIVATE_KEY.startsWith("0x");
console.log("🚫 Inizia con 0x:", startsWith0x ? "❌ ERRATO" : "✅ CORRETTO");

// 4. Prova a creare un wallet
try {
    const wallet = new ethers.Wallet(PRIVATE_KEY);
    console.log("👛 Indirizzo wallet derivato:", wallet.address);
    console.log("✅ PRIVATE KEY VALIDA - Wallet creato con successo");
} catch (error) {
    console.log("❌ PRIVATE KEY INVALIDA - Errore:", error.message);
}

// 5. Verifica caratteri speciali
console.log("\n🔎 ANALISI CARATTERI:");
console.log("Primi 10 caratteri:", PRIVATE_KEY.substring(0, 10));
console.log("Ultimi 10 caratteri:", PRIVATE_KEY.substring(PRIVATE_KEY.length - 10));
console.log("Contiene spazi?", PRIVATE_KEY.includes(" ") ? "❌ SI" : "✅ NO");
console.log("Contiene newline?", PRIVATE_KEY.includes("\n") ? "❌ SI" : "✅ NO");
