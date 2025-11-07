import pkg from 'hardhat';
const { ethers } = pkg;

async function monitorFunds() {
    const [deployer] = await ethers.getSigners();
    
    while (true) {
        const balance = await ethers.provider.getBalance(deployer.address);
        const balanceEth = parseFloat(ethers.formatEther(balance));
        
        console.clear();
        console.log("💰 FUND MONITOR - BASE NETWORK");
        console.log("===============================");
        console.log("⏰ Time:", new Date().toLocaleTimeString());
        console.log("📧 Wallet:", deployer.address);
        console.log("💎 Balance:", balanceEth.toFixed(6), "ETH");
        
        if (balanceEth >= 0.015) {
            console.log("🚀 READY TO DEPLOY! Sufficient funds detected!");
            console.log("▶️  Run: npx hardhat run scripts/quick-deploy.js --network base");
            break;
        } else {
            const needed = (0.015 - balanceEth).toFixed(6);
            console.log("⏳ Waiting for funds...");
            console.log("💡 Need:", needed, "ETH more");
            console.log("📊 Progress:", (balanceEth/0.015*100).toFixed(1) + "%");
        }
        
        await new Promise(resolve => setTimeout(resolve, 5000)); // Check every 5 seconds
    }
}

monitorFunds();