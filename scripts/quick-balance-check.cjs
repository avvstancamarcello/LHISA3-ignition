async function main() {
  console.log("💰 BASE BALANCE CHECK");
  console.log("═══════════════════════");

  try {
    const [deployer] = await ethers.getSigners();
    console.log("📍 Account:", deployer.address);
    
    const balance = await deployer.provider.getBalance(deployer.address);
    const balanceETH = ethers.formatEther(balance);
    
    console.log("💰 Current Balance:", balanceETH, "ETH");
    console.log("💵 USD Value (≈$2,500/ETH):", "$" + (parseFloat(balanceETH) * 2500).toFixed(2));
    
    const requiredETH = 0.008;
    console.log("\n🎯 DEPLOY REQUIREMENTS:");
    console.log("═══════════════════════");
    console.log("Required for complete ecosystem:", requiredETH, "ETH");
    console.log("Required in USD (≈$2,500/ETH):", "$" + (requiredETH * 2500).toFixed(2));
    
    if (parseFloat(balanceETH) >= requiredETH) {
      console.log("\n✅ SUFFICIENT BALANCE!");
      console.log("🚀 Ready to deploy complete ecosystem");
      console.log("💡 Run: npx hardhat run scripts/deploy-minimal-base-ecosystem.cjs --network base");
    } else {
      const needed = requiredETH - parseFloat(balanceETH);
      console.log("\n❌ INSUFFICIENT BALANCE");
      console.log("💸 Need additional:", needed.toFixed(6), "ETH");
      console.log("💵 Need additional USD:", "$" + (needed * 2500).toFixed(2));
      console.log("\n💡 OPTIONS:");
      console.log("1. 🏦 Fund wallet with", needed.toFixed(6), "ETH");
      console.log("2. 🎭 Continue using demo mode");
      console.log("3. 📱 Use faucet (if testnet)");
    }
    
    console.log("\n📊 NETWORK INFO:");
    console.log("═══════════════════");
    const network = await deployer.provider.getNetwork();
    console.log("Network:", network.name);
    console.log("Chain ID:", network.chainId.toString());
    
  } catch (error) {
    console.error("❌ Error:", error.message);
  }
}

main().catch(console.error);