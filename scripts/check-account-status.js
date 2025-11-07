import { ethers } from "hardhat";

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
  
  // Check gas price
  const gasPrice = await provider.getGasPrice();
  console.log("Current gas price:", ethers.formatUnits(gasPrice, "gwei"), "gwei");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });