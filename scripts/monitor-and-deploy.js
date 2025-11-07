import pkg from 'hardhat';
const { ethers } = pkg;

async function monitorFundsAndDeploy() {
    const [deployer] = await ethers.getSigners();
    
    let attempts = 0;
    const maxAttempts = 20; // 10 minutes max
    
    while (attempts < maxAttempts) {
        const balance = await ethers.provider.getBalance(deployer.address);
        const balanceEth = parseFloat(ethers.formatEther(balance));
        
        console.clear();
        console.log("⏰ MONITORING FUNDS FOR SECURE DEPLOYMENT");
        console.log("=======================================");
        console.log("Time:", new Date().toLocaleTimeString());
        console.log("Balance:", balanceEth.toFixed(6), "ETH");
        console.log("Required: 0.008000 ETH");
        console.log("Progress:", (balanceEth/0.008*100).toFixed(1) + "%");
        
        if (balanceEth >= 0.008) {
            console.log("\n🚀 SUFFICIENT FUNDS! DEPLOYING NOW...");
            
            // Import and execute secure deployment
            const { exec } = await import('child_process');
            exec('npx hardhat run scripts/deploy-secure-nft.js --network base', (error, stdout, stderr) => {
                if (error) {
                    console.error('Deployment error:', error);
                    return;
                }
                console.log(stdout);
                if (stderr) console.error(stderr);
            });
            
            break;
        } else {
            const needed = (0.008 - balanceEth).toFixed(6);
            console.log("⏳ Waiting... Need", needed, "ETH more");
            console.log("Attempt:", attempts + 1, "/", maxAttempts);
        }
        
        attempts++;
        await new Promise(resolve => setTimeout(resolve, 30000)); // Wait 30 seconds
    }
    
    if (attempts >= maxAttempts) {
        console.log("⏰ Timeout reached. Please add more funds and run deployment manually.");
    }
}

monitorFundsAndDeploy();