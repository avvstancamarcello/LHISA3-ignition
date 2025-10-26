require("dotenv").config({ path: require("path").resolve(__dirname, "..", ".env") });

const { ethers } = require("ethers");

async function main() {
    console.log("💰 CHECKING WALLET BALANCE ON POLYGON");
    console.log("======================================");

    const PRIVATE_KEY = process.env.PRIVATE_KEY;
    
    if (!PRIVATE_KEY) {
        console.error("❌ PRIVATE_KEY not found in .env");
        process.exit(1);
    }

    // Provider per Polygon Mainnet
    const provider = new ethers.providers.JsonRpcProvider("https://polygon-rpc.com");
    const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
    
    console.log(`👛 Wallet Address: ${wallet.address}`);

    try {
        // Ottieni il balance in MATIC (POL per gas)
        const balance = await provider.getBalance(wallet.address);
        const balanceInMatic = ethers.utils.formatEther(balance);

        console.log(`📊 Balance on Polygon: ${balanceInMatic} MATIC (POL)`);
        console.log(`🔢 Balance in Wei: ${balance.toString()}`);

        // Verifica se sufficiente per deploy
        const minRequired = ethers.utils.parseEther("2"); // 2 MATIC
        if (balance.lt(minRequired)) {
            console.log("\n❌ INSUFFICIENT BALANCE FOR DEPLOYMENT");
            console.log(`💡 You need at least 2 MATIC (POL) on Polygon Network`);
            console.log(`🔗 Buy MATIC on: Binance, Coinbase, Crypto.com`);
            console.log(`🔄 Bridge from Ethereum: https://wallet.polygon.technology/bridge`);
            console.log(`🎯 Faucet (testnet): https://faucet.polygon.technology/`);
        } else {
            console.log("\n✅ SUFFICIENT BALANCE FOR DEPLOYMENT");
            const estimatedCost = ethers.utils.parseEther("0.5"); // ~0.5 MATIC per deploy
            if (balance.gt(estimatedCost)) {
                console.log(`🎯 Estimated deploy cost: ~0.5 MATIC (POL)`);
                console.log(`💎 You have enough for multiple deployments`);
            }
        }

    } catch (error) {
        console.error("❌ Error checking balance:", error.message);
    }
}

main().catch(console.error);
