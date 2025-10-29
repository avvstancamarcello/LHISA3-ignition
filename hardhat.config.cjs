require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

// Controllo variabili d'ambiente critiche
const missingVars = [];
if (!process.env.PRIVATE_KEY) missingVars.push("PRIVATE_KEY");
if (!process.env.BASE_RPC_URL) missingVars.push("BASE_RPC_URL");
if (!process.env.BASE_SEPOLIA_RPC) missingVars.push("BASE_SEPOLIA_RPC");
if (!process.env.BASESCAN_API_KEY) missingVars.push("BASESCAN_API_KEY");
if (!process.env.POLYGON_RPC_URL) missingVars.push("POLYGON_RPC_URL");
if (missingVars.length > 0) {
  console.warn(
    `⚠️  Attenzione: le seguenti variabili d'ambiente non sono definite: ${missingVars.join(", ")}. Il deploy potrebbe fallire.`
  );
}

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.29",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
      viaIR: true,  // 🔥 SOLUZIONE PER STACK TOO DEEP
    }
  },
  networks: {
    base: {
      url: process.env.BASE_RPC_URL || "https://mainnet.base.org",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gas: 10000000,
      gasPrice: 2000000000,
    },
    base_sepolia: {
      url: process.env.BASE_SEPOLIA_RPC || "https://sepolia.base.org",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gas: 10000000,
      gasPrice: 2000000000,
    },
    hardhat: {
      chainId: 31337,
      allowUnlimitedContractSize: true
    },
    polygon: {
      url: process.env.POLYGON_RPC_URL || "https://polygon-rpc.com",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 137,
      gas: 10000000,
      gasPrice: 25000000000,
    }
  },
  etherscan: {
    apiKey: {
      base: process.env.BASESCAN_API_KEY || "API_KEY",
      baseSepolia: process.env.BASESCAN_API_KEY || "API_KEY",
      polygon: process.env.POLYGONSCAN_API_KEY || "API_KEY",
      polygonMumbai: process.env.POLYGONSCAN_API_KEY || "API_KEY"
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "Polygon Ecosystem Token",
  },
};
