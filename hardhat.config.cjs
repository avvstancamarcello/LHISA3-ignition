const { HardhatUserConfig } = require("hardhat/config");
require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv/config");

const config = {
  solidity: {
    version: "0.8.29",
    settings: {
      optimizer: {
        enabled: true,
      runs: 777
   },
   viaIR: true
  }
 },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
//  networks: {
//    base: {
//      url: process.env.BASE_RPC_URL || "",
//      accounts: [process.env.PRIVATE_KEY || ""]
//    }

//  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY || ""
  },
  namedAccounts: {
    deployer: {
      default: 0
    },
    liturgicalAdmin: {
      default: 1
    }
  }
};

module.exports = config;
