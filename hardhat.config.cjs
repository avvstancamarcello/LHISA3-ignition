// hardhat.config.ts

require('ts-node/register'); // Necessario per eseguire la configurazione come TypeScript
require("@nomicfoundation/hardhat-ignition"); // Carica il modulo Ignition

require("@nomicfoundation/hardhat-toolbox"); // Già presente

// ✅ CARICAMENTO .env O KEYS TEMPORANEE
const dotenv = require("dotenv");
const result = dotenv.config();

// ✅ SE .env NON CARICA, PROVA CON KEYS TEMPORANEE
let PRIVATE_KEY = process.env.PRIVATE_KEY;
let POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY;
let POLYGON_RPC_URL = process.env.POLYGON_RPC_URL;

if (!PRIVATE_KEY) {
    try {
        const tempKeys = require("./deploy-keys.temp.js");
        PRIVATE_KEY = tempKeys.PRIVATE_KEY;
        POLYGONSCAN_API_KEY = tempKeys.POLYGONSCAN_API_KEY;
        POLYGON_RPC_URL = tempKeys.POLYGON_RPC_URL;
        console.log("🔑 Loaded keys from temporary file");
    } catch (error) {
        console.log("⚠️  No temporary keys file found");
    }
}

if (!PRIVATE_KEY) {
    throw new Error("❌ PRIVATE_KEY not found in .env or temp file");
}

console.log("🔧 Environment loaded successfully:");
console.log("PRIVATE_KEY length:", PRIVATE_KEY?.length);
console.log("POLYGONSCAN_API_KEY:", POLYGONSCAN_API_KEY ? "LOADED" : "MISSING");
console.log("POLYGON_RPC_URL:", POLYGON_RPC_URL ? "LOADED" : "USING DEFAULT");

module.exports = {
    solidity: {
        version: "0.8.29",
        settings: {
            optimizer: {
                enabled: true,
                runs: 20000 // ⬅️ LA CONFIGURAZIONE CORRETTA E UNICA
            },
            viaIR: true
        }
    },
    networks: {
        // ✅ POLYGON NETWORK - CONFIGURAZIONE PRINCIPALE
        polygon: {
            url: POLYGON_RPC_URL || "https://aged-tiniest-frost.matic.quiknode.pro/b50bb4625032afb94b57bf5efd608270059e0da8",
            accounts: [PRIVATE_KEY],
            chainId: 137,
            gas: 5000000,
            gasPrice: 40000000000, // 40 Gwei
        },
        // ... (Resto delle configurazioni networks, etherscan, paths, gasReporter)
    },
    // ... (Il resto delle sezioni etherscan, paths, gasReporter)
    etherscan: {
        apiKey: {
            polygon: POLYGONSCAN_API_KEY || "your-polygonscan-api-key",
            polygonMumbai: POLYGONSCAN_API_KEY || "your-polygonscan-api-key",
        }
    },
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./artifacts"
    },
    gasReporter: {
        enabled: process.env.REPORT_GAS !== undefined,
        currency: "USD",
    },
};
