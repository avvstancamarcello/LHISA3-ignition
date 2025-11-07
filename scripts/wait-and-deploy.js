import pkg from 'hardhat';
const { ethers } = pkg;

async function waitForFundsAndDeploy() {
    console.log("⏳ WAITING FOR 0.0026 ETH TO ARRIVE");
    console.log("=================================");
    
    const [deployer] = await ethers.getSigners();
    const targetBalance = ethers.parseEther("0.008"); // 0.008 ETH minimum
    const expectedBalance = ethers.parseEther("0.00867"); // Expected with incoming funds
    
    let checkCount = 0;
    const maxChecks = 60; // 10 minutes max (check every 10 seconds)
    
    while (checkCount < maxChecks) {
        const currentBalance = await ethers.provider.getBalance(deployer.address);
        const balanceEth = parseFloat(ethers.formatEther(currentBalance));
        
        console.clear();
        console.log("💰 FUND ARRIVAL MONITOR");
        console.log("=======================");
        console.log("⏰ Time:", new Date().toLocaleTimeString());
        console.log("📊 Current Balance:", balanceEth.toFixed(6), "ETH");
        console.log("🎯 Target Balance: 0.008000 ETH");
        console.log("📈 Expected Final: 0.008670 ETH");
        console.log("🔄 Check #" + (checkCount + 1) + "/" + maxChecks);
        
        if (currentBalance >= targetBalance) {
            console.log("\n🚀 SUFFICIENT FUNDS DETECTED!");
            console.log("💎 Final Balance:", balanceEth.toFixed(6), "ETH");
            console.log("✅ READY FOR SECURE DEPLOYMENT!");
            
            // Trigger deployment
            console.log("\n⚡ STARTING SECURE NFT DEPLOYMENT...");
            return true;
            
        } else {
            const needed = parseFloat(ethers.formatEther(targetBalance - currentBalance));
            console.log("⏳ Still waiting... Need", needed.toFixed(6), "ETH more");
            
            // Show progress bar
            const progress = (balanceEth / 0.008) * 100;
            const progressBar = "█".repeat(Math.floor(progress / 5)) + "░".repeat(20 - Math.floor(progress / 5));
            console.log("📊 Progress: [" + progressBar + "] " + progress.toFixed(1) + "%");
        }
        
        checkCount++;
        await new Promise(resolve => setTimeout(resolve, 10000)); // Check every 10 seconds
    }
    
    console.log("\n⏰ Monitoring timeout. Please check manually.");
    return false;
}

waitForFundsAndDeploy()
    .then((ready) => {
        if (ready) {
            console.log("🎯 FUNDS CONFIRMED - EXECUTE DEPLOYMENT!");
        }
        process.exit(0);
    })
    .catch((error) => {
        console.error("❌ Monitoring error:", error);
        process.exit(1);
    });