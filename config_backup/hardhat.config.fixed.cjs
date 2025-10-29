require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.29",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    // SOLO reti essenziali - niente 'base'
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    hardhat: {
      // Configurazione base di Hardhat
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test", 
    cache: "./cache",
    artifacts: "./artifacts"
  }
};
