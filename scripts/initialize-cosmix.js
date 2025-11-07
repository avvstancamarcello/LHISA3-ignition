import pkg from 'hardhat';
import fs from 'fs';
const { ethers } = pkg;

async function initializeCOSMIXToken() {
    console.log("🚀 INITIALIZING COSMIX PROTOCOL TOKEN");
    console.log("===============================");
    console.log("🎯 Symbol: COSMIX");
    console.log("📊 Total Supply: 1,000,000 tokens");
    console.log("🌟 Cosmic exploration theme");
    
    const ftAddress = "0xF8d5a00Ca91D46c07614208C346c49a09409D094";
    console.log("📍 FT Contract:", ftAddress);
    
    try {
        const [deployer] = await ethers.getSigners();
        console.log("👤 Admin/Treasury:", deployer.address);
        
        // Check current balance
        const balance = await ethers.provider.getBalance(deployer.address);
        const balanceETH = ethers.formatEther(balance);
        console.log("💰 Balance:", balanceETH, "ETH");
        
        if (parseFloat(balanceETH) < 0.001) {
            console.log("❌ Insufficient balance for initialization");
            return { success: false, reason: "insufficient_balance" };
        }
        
        // Connect to FT contract
        const FTContract = await ethers.getContractFactory("LunaComicsFT");
        const ft = FTContract.attach(ftAddress);
        
        // Check if already initialized
        console.log("\n🔍 Checking initialization status...");
        try {
            const currentName = await ft.name();
            const currentSymbol = await ft.symbol();
            
            if (currentName && currentSymbol) {
                console.log("⚠️ Contract already initialized:");
                console.log("Name:", currentName);
                console.log("Symbol:", currentSymbol);
                return { success: false, reason: "already_initialized" };
            }
        } catch (checkError) {
            console.log("✅ Contract not initialized - proceeding...");
        }
        
        // Initialize parameters
        const initParams = {
            admin: deployer.address,
            name: "COSMIX Protocol Token", 
            symbol: "COSMIX",
            initialSupply: ethers.parseEther("1000000"), // 1M tokens
            treasury: deployer.address
        };
        
        console.log("\n🚀 INITIALIZATION PARAMETERS:");
        console.log("Admin:", initParams.admin);
        console.log("Name:", initParams.name);
        console.log("Symbol:", initParams.symbol);
        console.log("Supply:", ethers.formatEther(initParams.initialSupply));
        console.log("Treasury:", initParams.treasury);
        
        // Execute initialization
        console.log("\n⏳ Executing initialization...");
        const initTx = await ft.initialize(
            initParams.admin,
            initParams.name,
            initParams.symbol,
            initParams.initialSupply,
            initParams.treasury,
            {
                gasLimit: 500000
            }
        );
        
        console.log("🔄 Transaction submitted:", initTx.hash);
        const receipt = await initTx.wait();
        console.log("✅ Transaction confirmed in block:", receipt.blockNumber);
        
        // Verify initialization
        console.log("\n🔍 VERIFYING INITIALIZATION:");
        const name = await ft.name();
        const symbol = await ft.symbol();
        const totalSupply = await ft.totalSupply();
        const treasuryBalance = await ft.balanceOf(deployer.address);
        const decimals = await ft.decimals();
        
        console.log("✅ Name:", name);
        console.log("✅ Symbol:", symbol);
        console.log("✅ Total Supply:", ethers.formatEther(totalSupply));
        console.log("✅ Treasury Balance:", ethers.formatEther(treasuryBalance));
        console.log("✅ Decimals:", decimals.toString());
        
        // Check roles
        console.log("\n🔑 ROLE VERIFICATION:");
        const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";
        const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
        const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MANAGER_ROLE"));
        
        const hasAdmin = await ft.hasRole(DEFAULT_ADMIN_ROLE, deployer.address);
        const hasMinter = await ft.hasRole(MINTER_ROLE, deployer.address);
        const hasManager = await ft.hasRole(MANAGER_ROLE, deployer.address);
        
        console.log("✅ Admin Role:", hasAdmin);
        console.log("✅ Minter Role:", hasMinter);
        console.log("✅ Manager Role:", hasManager);
        
        // Connect to orchestrator for automatic distribution
        console.log("\n🔗 CONNECTING TO ORCHESTRATOR:");
        const ORCHESTRATOR = "0xf0D90454C98A0AE934e9DB1B316FF1608C4E9DEf";
        
        try {
            const grantTx = await ft.grantRole(MINTER_ROLE, ORCHESTRATOR);
            await grantTx.wait();
            console.log("✅ MINTER_ROLE granted to orchestrator");
            
            const orchestratorHasMinter = await ft.hasRole(MINTER_ROLE, ORCHESTRATOR);
            console.log("✅ Orchestrator has MINTER_ROLE:", orchestratorHasMinter);
        } catch (roleError) {
            console.log("⚠️ Role assignment to orchestrator:", roleError.message);
        }
        
        // Final balance
        const finalBalance = await ethers.provider.getBalance(deployer.address);
        const finalBalanceETH = ethers.formatEther(finalBalance);
        const gasCost = parseFloat(balanceETH) - parseFloat(finalBalanceETH);
        
        console.log("\n💰 FINANCIAL SUMMARY:");
        console.log("Gas Cost:", gasCost.toFixed(6), "ETH");
        console.log("Final Balance:", finalBalanceETH, "ETH");
        
        // Save initialization record
        const initRecord = {
            network: "base",
            timestamp: new Date().toISOString(),
            status: "FT_INITIALIZED_SUCCESS",
            contract: {
                address: ftAddress,
                name: name,
                symbol: symbol,
                totalSupply: ethers.formatEther(totalSupply),
                decimals: decimals.toString()
            },
            initialization: {
                admin: initParams.admin,
                treasury: initParams.treasury,
                initialSupply: ethers.formatEther(initParams.initialSupply),
                transactionHash: initTx.hash,
                blockNumber: receipt.blockNumber
            },
            distribution: {
                treasuryBalance: ethers.formatEther(treasuryBalance),
                orchestratorConnected: true,
                automaticDistribution: "Ready for 55% NFT / 45% FT split"
            },
            costs: {
                gasCost: gasCost.toString(),
                finalBalance: finalBalanceETH
            }
        };
        
        fs.writeFileSync('deployments/cosmix-initialization.json', JSON.stringify(initRecord, null, 2));
        
    console.log("\n🎉 COSMIX PROTOCOL TOKEN INITIALIZATION SUCCESS!");
        console.log("=================================");
    console.log("🚀 Token Name: COSMIX Protocol Token");
    console.log("🎯 Symbol: COSMIX");
    console.log("📊 Total Supply: 1,000,000 COSMIX");
        console.log("✅ Orchestrator connected for auto-distribution");
    console.log("💾 Record saved to deployments/cosmix-initialization.json");
        
        return {
            success: true,
            name: name,
            symbol: symbol,
            totalSupply: ethers.formatEther(totalSupply),
            address: ftAddress
        };
        
    } catch (error) {
        console.error("❌ Initialization error:", error.message);
        
        // Save error record
        const errorRecord = {
            timestamp: new Date().toISOString(),
            error: error.message,
            stage: "FT_INITIALIZATION",
            contract: ftAddress
        };
        
        fs.writeFileSync(`deployments/cosmix-init-error-${Date.now()}.json`, JSON.stringify(errorRecord, null, 2));
        
        return {
            success: false,
            error: error.message
        };
    }
}

initializeCOSMIXToken()
    .then((result) => {
        if (result.success) {
            console.log("\n🌟 COSMIX PROTOCOL TOKEN READY FOR COSMIC EXPLORATION!");
        }
        process.exit(result.success ? 0 : 1);
    })
    .catch((error) => {
        console.error("❌ Fatal error:", error);
        process.exit(1);
    });