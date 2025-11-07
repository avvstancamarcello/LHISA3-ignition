const { ethers } = require("hardhat");

async function main() {
  console.log("🔍 Controllo Saldo per Deploy su Base Network");
  console.log("=" * 50);
  
  try {
    // Get signer for Base network
    const [deployer] = await ethers.getSigners();
    const provider = deployer.provider;
    
    console.log("📍 Account:", deployer.address);
    console.log("🌐 Network: Base Mainnet");
    
    // Get balance
    const balance = await provider.getBalance(deployer.address);
    console.log("\n💰 Balance Info:");
    console.log("  ETH Balance:", ethers.formatEther(balance), "ETH");
    
    // Get current gas conditions on Base
    console.log("\n⛽ Gas Conditions:");
    try {
      const feeData = await provider.getFeeData();
      console.log("  Gas Price:", ethers.formatUnits(feeData.gasPrice, "gwei"), "gwei");
      console.log("  Max Fee Per Gas:", ethers.formatUnits(feeData.maxFeePerGas || "0", "gwei"), "gwei");
      console.log("  Max Priority Fee:", ethers.formatUnits(feeData.maxPriorityFeePerGas || "0", "gwei"), "gwei");
    } catch (error) {
      console.log("  Gas info not available:", error.message);
    }
    
    // Get latest block
    const latestBlock = await provider.getBlock("latest");
    console.log("\n📊 Network Info:");
    console.log("  Latest Block:", latestBlock.number);
    console.log("  Block Time:", new Date(latestBlock.timestamp * 1000).toLocaleString());
    
    // Estimate deployment cost
    console.log("\n💸 Deploy Cost Estimation:");
    
    // Typical deploy gas estimates
    const estimatedGasLimit = BigInt(3000000); // 3M gas units
    const currentGasPrice = await provider.getFeeData().then(data => data.gasPrice);
    
    const estimatedCost = estimatedGasLimit * currentGasPrice;
    const estimatedCostETH = ethers.formatEther(estimatedCost);
    
    console.log("  Estimated Gas Limit:", estimatedGasLimit.toString(), "units");
    console.log("  Current Gas Price:", ethers.formatUnits(currentGasPrice, "gwei"), "gwei");
    console.log("  Estimated Cost:", estimatedCostETH, "ETH");
    
    // Check if balance is sufficient
    const balanceWei = balance;
    const hasEnoughBalance = balanceWei >= estimatedCost;
    const safetyMargin = balanceWei >= (estimatedCost * BigInt(2)); // 2x safety margin
    
    console.log("\n✅ Balance Check:");
    console.log("  Sufficient for deploy:", hasEnoughBalance ? "✅ YES" : "❌ NO");
    console.log("  Has safety margin (2x):", safetyMargin ? "✅ YES" : "⚠️  NO");
    
    if (!hasEnoughBalance) {
      console.log("\n❌ INSUFFICIENT BALANCE!");
      console.log("  Need at least:", estimatedCostETH, "ETH");
      console.log("  Current balance:", ethers.formatEther(balance), "ETH");
      const needed = estimatedCost - balanceWei;
      console.log("  Need to add:", ethers.formatEther(needed), "ETH");
    } else if (!safetyMargin) {
      console.log("\n⚠️  BALANCE OK BUT LOW SAFETY MARGIN");
      console.log("  Consider adding more ETH for safety");
    } else {
      console.log("\n🎉 BALANCE SUFFICIENT FOR DEPLOY!");
      console.log("  You can proceed with deployment on Base");
    }
    
    // Show deployed contracts from other networks for reference
    console.log("\n📋 Reference - Deployed on Polygon:");
    console.log("  OceanMangaNFT:", "0xBeC80BF2ef21597c0b40106D8eF70d03fEE44C79");
    console.log("  LunaComicsFT:", "0xE82CCA2448C87c4B07e489714eC16684209D7D58");
    console.log("  SponsorVault:", "0xB19Ee3A16554d339111028fe3a76fEE5AE45E8A3");
    
    console.log("\n" + "=" * 50);
    
  } catch (error) {
    console.error("❌ Error checking Base balance:", error.message);
    
    if (error.code === 'NETWORK_ERROR') {
      console.error("🌐 Network connection issue - check Base RPC URL");
    } else if (error.code === 'INVALID_ARGUMENT') {
      console.error("🔑 Private key or account issue");
    }
    
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });