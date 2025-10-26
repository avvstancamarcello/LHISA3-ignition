require("dotenv").config({ path: require("path").resolve(__dirname, "..", ".env") });

const { ethers } = require("ethers"); // ✅ USA 'ethers' invece di 'hardhat'

async function main() {
    console.log("💰 CHECKING WALLET BALANCE");
    console.log("==========================");

    const PRIVATE_KEY = process.env.PRIVATE_KEY;
    
    if (!PRIVATE_KEY) {
        console.error("❌ PRIVATE_KEY not found in .env");
        process.exit(1);
    }

    // ✅ CORRETTO PER ETHERS v5/v6
    const provider = new ethers.providers.JsonRpcProvider("https://mainnet.base.org");
    const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
    
    console.log(`👛 Wallet Address: ${wallet.address}`);

    try {
        // Ottieni il balance
        const balance = await provider.getBalance(wallet.address);
        const balanceInEth = ethers.utils.formatEther(balance);

        console.log(`📊 Balance on Base: ${balanceInEth} ETH`);
        console.log(`🔢 Balance in Wei: ${balance.toString()}`);

        // Verifica se sufficiente per deploy
        const minRequired = ethers.utils.parseEther("0.05"); // 0.05 ETH
        if (balance.lt(minRequired)) {
            console.log("❌ INSUFFICIENT BALANCE FOR DEPLOYMENT");
            console.log(`💡 You need at least 0.05 ETH on Base Network`);
            console.log(`🌉 Bridge ETH from Ethereum: https://bridge.base.org`);
        } else {
            console.log("✅ SUFFICIENT BALANCE FOR DEPLOYMENT");
        }

    } catch (error) {
        console.error("❌ Error checking balance:", error.message);
    }
}

main().catch(console.error);
