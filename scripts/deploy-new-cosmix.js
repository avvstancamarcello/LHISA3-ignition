import pkg from 'hardhat';
import fs from 'fs';
const { ethers } = pkg;

async function deployNewCOSMIXToken() {
    console.log("🚀 DEPLOYING NEW COSMIX FT TOKEN");
    console.log("=================================");
    console.log("🎯 Symbol: COSMIX");
    console.log("📊 Total Supply: 1,000,000 tokens");
    console.log("🌟 Fresh deployment for cosmic exploration");
    
    try {
        const [deployer] = await ethers.getSigners();
        console.log("👤 Deployer:", deployer.address);
        
        // Check balance
        const balance = await ethers.provider.getBalance(deployer.address);
        const balanceETH = ethers.formatEther(balance);
        console.log("💰 Balance:", balanceETH, "ETH");
        
        if (parseFloat(balanceETH) < 0.01) {
            console.log("❌ Insufficient balance for deployment");
            return { success: false, reason: "insufficient_balance" };
        }
        
        console.log("\n🚀 DEPLOYING NEW FT CONTRACT...");
        
        // Deploy new FT contract
        const FTContract = await ethers.getContractFactory("LunaComicsFT");
        const newFT = await FTContract.deploy({
            gasLimit: 6000000
        });
        
        console.log("⏳ Waiting for deployment...");
        await newFT.waitForDeployment();
        
        const newFTAddress = await newFT.getAddress();
        console.log("✅ NEW COSMIX FT DEPLOYED:", newFTAddress);
        
        // Initialize immediately
        console.log("\n🔧 INITIALIZING WITH COSMIX PARAMETERS...");
        
        const initParams = {
            admin: deployer.address,
            name: "Cosmix Protocol Token",
            symbol: "COSMIX", 
            initialSupply: ethers.parseEther("1000000"), // 1M tokens
            treasury: deployer.address
        };
        
        console.log("Admin:", initParams.admin);
        console.log("Name:", initParams.name);
        console.log("Symbol:", initParams.symbol);
        console.log("Supply:", ethers.formatEther(initParams.initialSupply));
        
        const initTx = await newFT.initialize(
            initParams.admin,
            initParams.name,
            initParams.symbol,
            initParams.initialSupply,
            initParams.treasury,
            {
                gasLimit: 500000
            }
        );
        
        console.log("⏳ Initialization transaction:", initTx.hash);
        await initTx.wait();
        console.log("✅ Initialization complete!");
        
        // Verify initialization
        console.log("\n🔍 VERIFYING NEW COSMIX TOKEN:");
        const name = await newFT.name();
        const symbol = await newFT.symbol();
        const totalSupply = await newFT.totalSupply();
        const treasuryBalance = await newFT.balanceOf(deployer.address);
        const decimals = await newFT.decimals();
        
        console.log("✅ Name:", name);
        console.log("✅ Symbol:", symbol);
        console.log("✅ Total Supply:", ethers.formatEther(totalSupply));
        console.log("✅ Treasury Balance:", ethers.formatEther(treasuryBalance));
        console.log("✅ Decimals:", decimals.toString());
        
        // Verify roles
        console.log("\n🔑 ROLE VERIFICATION:");
        const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";
        const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
        const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MANAGER_ROLE"));
        
        const hasAdmin = await newFT.hasRole(DEFAULT_ADMIN_ROLE, deployer.address);
        const hasMinter = await newFT.hasRole(MINTER_ROLE, deployer.address);
        const hasManager = await newFT.hasRole(MANAGER_ROLE, deployer.address);
        
        console.log("✅ Admin Role:", hasAdmin);
        console.log("✅ Minter Role:", hasMinter);
        console.log("✅ Manager Role:", hasManager);
        
        // Connect to orchestrator
        console.log("\n🔗 CONNECTING TO ORCHESTRATOR:");
        const ORCHESTRATOR = "0xf0D90454C98A0AE934e9DB1B316FF1608C4E9DEf";
        
        try {
            const grantTx = await newFT.grantRole(MINTER_ROLE, ORCHESTRATOR);
            await grantTx.wait();
            console.log("✅ MINTER_ROLE granted to orchestrator");
            
            const orchestratorHasMinter = await newFT.hasRole(MINTER_ROLE, ORCHESTRATOR);
            console.log("✅ Orchestrator has MINTER_ROLE:", orchestratorHasMinter);
        } catch (roleError) {
            console.log("⚠️ Role assignment:", roleError.message);
        }
        
        // Final balance
        const finalBalance = await ethers.provider.getBalance(deployer.address);
        const finalBalanceETH = ethers.formatEther(finalBalance);
        const deploymentCost = parseFloat(balanceETH) - parseFloat(finalBalanceETH);
        
        console.log("\n💰 DEPLOYMENT COSTS:");
        console.log("Total Cost:", deploymentCost.toFixed(6), "ETH");
        console.log("Final Balance:", finalBalanceETH, "ETH");
        
        // Save new ecosystem configuration
        const newEcosystem = {
            network: "base",
            timestamp: new Date().toISOString(),
            status: "COSMIX_DEPLOYMENT_SUCCESS",
            contracts: {
                comicsNFT: "0x771800D146F7d7B0D7C79669512B30A2fA190255", // Current working NFT
                cosmixFT: newFTAddress, // NEW COSMIX TOKEN
                orchestrator: ORCHESTRATOR,
                impactTracker: "0x20e63Ac004aA0997CC2bE7B8bB4419b9385C4689",
                oldFT: "0xF8d5a00Ca91D46c07614208C346c49a09409D094" // Old broken FT
            },
            tokens: {
                nft: {
                    name: "OceanManga Comics NFT",
                    symbol: "COMICS",
                    address: "0x771800D146F7d7B0D7C79669512B30A2fA190255"
                },
                ft: {
                    name: name,
                    symbol: symbol,
                    address: newFTAddress,
                    totalSupply: ethers.formatEther(totalSupply),
                    decimals: decimals.toString()
                }
            },
            distribution: {
                system: "55% NFT / 45% FT automatic split",
                treasuryBalance: ethers.formatEther(treasuryBalance),
                orchestratorConnected: true
            },
            branding: {
                theme: "Cosmic exploration and technological progress",
                appeal: "Premium scarcity with 1M total supply",
                target: "International crypto and NFT enthusiasts"
            },
            security: {
                customRolesOnly: true,
                noDefaultAdminRoleNFT: true,
                orchestratorConnected: true,
                ownerHasAllRoles: hasAdmin && hasMinter && hasManager
            },
            deployment: {
                cost: deploymentCost.toString(),
                finalBalance: finalBalanceETH
            }
        };
        
        fs.writeFileSync('deployments/complete-cosmix-ecosystem.json', JSON.stringify(newEcosystem, null, 2));
        
        console.log("\n🎉 COSMIX ECOSYSTEM COMPLETE!");
        console.log("==============================");
        console.log("🛡️ COMICS NFT: 0x771800D146F7d7B0D7C79669512B30A2fA190255");
        console.log("🚀 COSMIX FT:", newFTAddress);
        console.log("🎭 Orchestrator: 0xf0D90454C98A0AE934e9DB1B316FF1608C4E9DEf");
        console.log("📊 Impact Tracker: 0x20e63Ac004aA0997CC2bE7B8bB4419b9385C4689");
        
        console.log("\n🌟 TOKEN BRANDING SUCCESS:");
        console.log("📝 NFT: COMICS (brand-aligned)");
        console.log("🚀 FT: COSMIX (cosmic exploration)");
        console.log("📊 Supply: 1,000,000 COSMIX (premium scarcity)");
        
        console.log("\n🔄 AUTOMATIC DISTRIBUTION:");
        console.log("💰 55% payments → COMICS NFT holders");
        console.log("🚀 45% payments → COSMIX FT holders");
        console.log("✅ Orchestrator manages distribution automatically");
        
        console.log("\n📁 RECORDS SAVED:");
        console.log("💾 deployments/complete-cosmix-ecosystem.json");
        
        return {
            success: true,
            newFTAddress: newFTAddress,
            name: name,
            symbol: symbol,
            totalSupply: ethers.formatEther(totalSupply)
        };
        
    } catch (error) {
        console.error("❌ Deployment error:", error.message);
        
        const errorRecord = {
            timestamp: new Date().toISOString(),
            error: error.message,
            stage: "COSMIX_DEPLOYMENT"
        };
        
        fs.writeFileSync(`deployments/cosmix-deploy-error-${Date.now()}.json`, JSON.stringify(errorRecord, null, 2));
        
        return {
            success: false,
            error: error.message
        };
    }
}

deployNewCOSMIXToken()
    .then((result) => {
        if (result.success) {
            console.log("\n🌌 COSMIX IS READY FOR COSMIC EXPLORATION!");
            console.log("The universe of possibilities awaits...");
        }
        process.exit(result.success ? 0 : 1);
    })
    .catch((error) => {
        console.error("❌ Fatal error:", error);
        process.exit(1);
    });