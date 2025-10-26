// ⚡ CONFIG SEMPLIFICATA PER TEST
require("@nomicfoundation/hardhat-toolbox");

// ✅ PRIVATE KEY DIRETTA (per test)
const PRIVATE_KEY = "4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1a";

console.log("🔧 Config semplice - PRIVATE_KEY length:", PRIVATE_KEY.length);

module.exports = {
  solidity: {
    version: "0.8.29",
    settings: {
      optimizer: { enabled: true, runs: 200 },
      viaIR: true
    }
  },
  networks: {
    polygon: {
      url: "https://polygon-rpc.com",
      accounts: [PRIVATE_KEY], // ✅ DIRETTA
      chainId: 137,
      gas: 5000000,
    }
  }
};
