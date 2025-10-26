// 🌐 TEST CONNESSIONE POLYGON CON PRIVATE KEY
const { ethers } = require("ethers");

const PRIVATE_KEY = "4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1a";
const POLYGON_RPC = "https://polygon-rpc.com";

async function testConnection() {
    console.log("🌐 TEST CONNESSIONE POLYGON");
    console.log("===========================");
    
    try {
        // 1. Crea provider
        const provider = new ethers.providers.JsonRpcProvider(POLYGON_RPC);
        console.log("✅ Provider Polygon creato");
        
        // 2. Crea wallet
        const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
        console.log("✅ Wallet creato:", wallet.address);
        
        // 3. Testa connessione
        const network = await provider.getNetwork();
        console.log("✅ Connesso a network:", network.name, "(Chain ID:", network.chainId + ")");
        
        // 4. Testa balance
        const balance = await provider.getBalance(wallet.address);
        console.log("✅ Balance letto:", ethers.utils.formatEther(balance), "MATIC");
        
        console.log("\n🎯 TUTTI I TEST SUPERATI!");
        console.log("La private key e la connessione funzionano correttamente");
        
    } catch (error) {
        console.log("❌ ERRORE durante il test:");
        console.log("Messaggio:", error.message);
    }
}

testConnection().catch(console.error);
