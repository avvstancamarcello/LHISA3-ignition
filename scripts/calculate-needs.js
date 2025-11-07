import pkg from 'hardhat';
const { ethers } = pkg;

async function calculateExactNeeds() {
    console.log("🧮 CALCOLO ESATTO FONDI NECESSARI");
    console.log("================================");
    
    const [deployer] = await ethers.getSigners();
    const currentBalance = await ethers.provider.getBalance(deployer.address);
    const currentETH = parseFloat(ethers.formatEther(currentBalance));
    
    console.log("💰 Balance attuale:", currentETH.toFixed(8), "ETH");
    
    try {
        // Stima gas per NFT deployment
        const NFTFactory = await ethers.getContractFactory("OceanMangaNFT_FixedRoles");
        const deployData = NFTFactory.getDeployTransaction();
        const gasEstimate = await ethers.provider.estimateGas(deployData);
        
        // Get current gas price
        const feeData = await ethers.provider.getFeeData();
        const gasPrice = feeData.gasPrice;
        
        // Calculate costs
        const deploymentCost = gasEstimate * gasPrice;
        const initializationCost = 200000n * gasPrice; // Stima per initialize
        const totalCost = deploymentCost + initializationCost;
        
        const costETH = parseFloat(ethers.formatEther(totalCost));
        const bufferCost = costETH * 1.2; // 20% buffer
        
        console.log("\n📊 ANALISI COSTI:");
        console.log("Gas stimato deployment:", gasEstimate.toString());
        console.log("Gas price attuale:", ethers.formatUnits(gasPrice, "gwei"), "gwei");
        console.log("Costo deployment:", costETH.toFixed(6), "ETH");
        console.log("Con buffer 20%:", bufferCost.toFixed(6), "ETH");
        
        const needed = bufferCost - currentETH;
        
        console.log("\n💡 RISULTATO:");
        console.log("Balance attuale:", currentETH.toFixed(6), "ETH");
        console.log("Necessario totale:", bufferCost.toFixed(6), "ETH");
        
        if (needed > 0) {
            console.log("❗ MANCA:", needed.toFixed(6), "ETH");
            console.log("💵 In USD (ETH a $2500):", (needed * 2500).toFixed(2), "USD");
        } else {
            console.log("✅ FONDI SUFFICIENTI!");
        }
        
        // Alternative con gas più basso
        const lowGasPrice = feeData.gasPrice * 70n / 100n; // 70% del gas attuale
        const lowCostTotal = (gasEstimate + 200000n) * lowGasPrice;
        const lowCostETH = parseFloat(ethers.formatEther(lowCostTotal));
        const lowCostBuffer = lowCostETH * 1.15; // 15% buffer
        
        console.log("\n⚡ OPZIONE GAS RIDOTTO:");
        console.log("Gas price ridotto:", ethers.formatUnits(lowGasPrice, "gwei"), "gwei");
        console.log("Costo totale:", lowCostBuffer.toFixed(6), "ETH");
        
        const neededLow = lowCostBuffer - currentETH;
        if (neededLow > 0) {
            console.log("❗ Manca:", neededLow.toFixed(6), "ETH");
        } else {
            console.log("✅ FONDI SUFFICIENTI con gas ridotto!");
        }
        
    } catch (error) {
        console.log("Stima approssimativa: serve circa 0.008-0.012 ETH totali");
        console.log("Manca circa:", (0.008 - currentETH).toFixed(6), "ETH");
    }
}

calculateExactNeeds()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("Error:", error.message);
        process.exit(1);
    });