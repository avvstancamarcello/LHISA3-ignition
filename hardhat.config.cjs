require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();
// Controllo variabili d'ambiente critiche
const missingVars = [];
if (!process.env.PRIVATE_KEY) missingVars.push("PRIVATE_KEY");
if (!process.env.BASE_RPC_URL) missingVars.push("BASE_RPC_URL");
if (!process.env.BASE_SEPOLIA_RPC) missingVars.push("BASE_SEPOLIA_RPC");
if (!process.env.ETHERSCAN_API_KEY) missingVars.push("ETHERSCAN_API_KEY");
if (!process.env.POLYGON_RPC_URL) missingVars.push("POLYGON_RPC_URL");
if (missingVars.length > 0) {
  console.warn(
    `⚠️  Attenzione: le seguenti variabili d'ambiente non sono definite: ${missingVars.join(", ")}. Il deploy potrebbe fallire.`
  );
}

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.29",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000
          },
          viaIR: true,  // Required to avoid stack too deep
        }
      },
      {
        version: "0.6.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          },
        }
      },
      {
        version: "0.6.2",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          },
        }
      },
      {
        version: "0.5.16",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          },
        }
      }
    ]
  },
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545"
    },
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
      gasPrice: 200000000000, // 200 Gwei legacy gas price
      maxFeePerGas: 500000000000, // 500 Gwei max fee (increased)
      maxPriorityFeePerGas: 100000000000, // 100 Gwei priority fee (increased)
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY || "API_KEY"
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "Polygon Ecosystem Token",
  }
}