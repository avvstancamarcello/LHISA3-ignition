const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  const provider = deployer.provider;
  
  console.log("Monitoring pending transactions for:", deployer.address);
  console.log("Waiting for 5 confirmations...\n");
  
  let intervalCount = 0;
  const maxWaitMinutes = 10;
  const checkInterval = 15; // seconds
  
  const monitorInterval = setInterval(async () => {
    try {
      intervalCount++;
      const elapsedMinutes = (intervalCount * checkInterval) / 60;
      
      const nonce = await provider.getTransactionCount(deployer.address);
      const pendingNonce = await provider.getTransactionCount(deployer.address, "pending");
      const pendingTxs = pendingNonce - nonce;
      
      const latestBlock = await provider.getBlock("latest");
      
      console.log(`⏰ ${elapsedMinutes.toFixed(1)}min | Block: ${latestBlock.number} | Pending: ${pendingTxs} tx`);
      
      if (pendingTxs === 0) {
        console.log("✅ No more pending transactions! Ready for deployment.");
        clearInterval(monitorInterval);
        process.exit(0);
      }
      
      if (elapsedMinutes >= maxWaitMinutes) {
        console.log("⏰ Max wait time reached. You may try deployment anyway.");
        clearInterval(monitorInterval);
        process.exit(0);
      }
      
    } catch (error) {
      console.error("Error checking status:", error.message);
    }
  }, checkInterval * 1000);
  
  // Handle process termination
  process.on('SIGINT', () => {
    console.log("\n🛑 Monitoring stopped by user");
    clearInterval(monitorInterval);
    process.exit(0);
  });
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});