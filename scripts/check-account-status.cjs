const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  const provider = deployer.provider;
  
  console.log("Checking account status for:", deployer.address);
  
  // Get current nonce
  const nonce = await provider.getTransactionCount(deployer.address);
  const pendingNonce = await provider.getTransactionCount(deployer.address, "pending");
  
  console.log("Current nonce:", nonce);
  console.log("Pending nonce:", pendingNonce);
  console.log("Pending transactions:", pendingNonce - nonce);
  
  // Get balance
  const balance = await provider.getBalance(deployer.address);
  console.log("Balance:", ethers.formatEther(balance), "MATIC");
  
  // Get latest block info
  const latestBlock = await provider.getBlock("latest");
  console.log("Latest block:", latestBlock.number);
  console.log("Block timestamp:", new Date(latestBlock.timestamp * 1000).toLocaleString());
  
  // Check gas price using getFeeData (new method)
  try {
    const feeData = await provider.getFeeData();
    console.log("Current gas price:", ethers.formatUnits(feeData.gasPrice, "gwei"), "gwei");
  } catch (error) {
    console.log("Gas price info not available:", error.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });