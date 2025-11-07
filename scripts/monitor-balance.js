import pkg from 'hardhat';
const { ethers } = pkg;

/**
 * Balance monitoring script - waits for fund addition
 */
async function monitorBalance() {
    console.log("⏳ MONITORING BALANCE FOR FUND ADDITION");
    console.log("=======================================");
    
    const [deployer] = await ethers.getSigners();
    const targetBalance = 0.006; // Minimum required
    const initialBalance = await ethers.provider.getBalance(deployer.address);
    const initialETH = parseFloat(ethers.formatEther(initialBalance));
    
    console.log("👤 Wallet:", deployer.address);
    console.log("💰 Current Balance:", initialETH.toFixed(6), "ETH");
    console.log("🎯 Target Balance:", targetBalance, "ETH");
    console.log("📈 Need to Add:", (targetBalance - initialETH).toFixed(6), "ETH");
    
    console.log("\n⏳ Waiting for funds to be added...");
    console.log("(Checking every 10 seconds)");
    
    let checkCount = 0;
    const maxChecks = 60; // 10 minutes maximum wait
    
    while (checkCount < maxChecks) {
        await new Promise(resolve => setTimeout(resolve, 10000)); // Wait 10 seconds
        
        const currentBalance = await ethers.provider.getBalance(deployer.address);
        const currentETH = parseFloat(ethers.formatEther(currentBalance));
        
        checkCount++;
        console.log(`Check ${checkCount}: ${currentETH.toFixed(6)} ETH`);
        
        if (currentETH >= targetBalance) {
            console.log("\n🎉 SUFFICIENT FUNDS DETECTED!");
            console.log("✅ Balance:", currentETH.toFixed(6), "ETH");
            console.log("✅ Target:", targetBalance, "ETH");
            console.log("✅ Excess:", (currentETH - targetBalance).toFixed(6), "ETH");
            
            console.log("\n🚀 PROCEEDING TO DEPLOYMENT APPROVAL...");
            return {
                success: true,
                balance: currentETH,
                fundsAdded: currentETH - initialETH
            };
        }
    }
    
    console.log("\n⏰ TIMEOUT: Maximum wait time reached");
    console.log("Please add funds and run the deployment script manually");
    return {
        success: false,
        reason: "timeout",
        currentBalance: await ethers.provider.getBalance(deployer.address)
    };
}

// Run monitoring
monitorBalance()
    .then((result) => {
        if (result.success) {
            console.log("\n🎯 READY FOR DEPLOYMENT!");
            console.log("Run: npx hardhat run scripts/secure-comics-deployment.js --network base");
        }
        process.exit(result.success ? 0 : 1);
    })
    .catch((error) => {
        console.error("❌ Monitoring error:", error);
        process.exit(1);
    });