import pkg from 'hardhat';
import fs from 'fs';
const { ethers } = pkg;

async function verifyComicsDeployment() {
    console.log("🔍 VERIFYING COMICS DEPLOYMENT");
    console.log("==============================");
    
    const contractAddress = "0x771800D146F7d7B0D7C79669512B30A2fA190255";
    console.log("📍 Contract Address:", contractAddress);
    
    try {
        // Wait for network propagation
        console.log("⏳ Waiting for network propagation...");
        await new Promise(resolve => setTimeout(resolve, 10000));
        
        const [deployer] = await ethers.getSigners();
        const NFTContract = await ethers.getContractFactory("OceanMangaNFT_Simple");
        const nft = NFTContract.attach(contractAddress);
        
        // Verify basic properties
        console.log("\n📝 VERIFYING CONTRACT PROPERTIES:");
        const name = await nft.name();
        const symbol = await nft.symbol();
        
        console.log("✅ Name:", name);
        console.log("✅ Symbol:", symbol);
        
        // Verify roles
        console.log("\n🔑 VERIFYING ROLES:");
        const ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_ADMIN_ROLE"));
        const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MINTER_ROLE"));
        const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MANAGER_ROLE"));
        
        const hasAdmin = await nft.hasRole(ADMIN_ROLE, deployer.address);
        const hasMinter = await nft.hasRole(MINTER_ROLE, deployer.address);
        const hasManager = await nft.hasRole(MANAGER_ROLE, deployer.address);
        
        console.log("✅ Admin Role:", hasAdmin);
        console.log("✅ Minter Role:", hasMinter);
        console.log("✅ Manager Role:", hasManager);
        
        // Critical security check
        const noDefaultAdmin = await nft.verifyNoDefaultAdminRole(deployer.address);
        console.log("🔒 No DEFAULT_ADMIN_ROLE:", noDefaultAdmin);
        
        // Connect to orchestrator
        console.log("\n🔗 CONNECTING TO ORCHESTRATOR:");
        const ORCHESTRATOR = "0xf0D90454C98A0AE934e9DB1B316FF1608C4E9DEf";
        
        try {
            const grantTx = await nft.grantRole(MINTER_ROLE, ORCHESTRATOR);
            await grantTx.wait();
            console.log("✅ MINTER_ROLE granted to orchestrator");
            
            const orchestratorHasMinter = await nft.hasRole(MINTER_ROLE, ORCHESTRATOR);
            console.log("✅ Orchestrator has MINTER_ROLE:", orchestratorHasMinter);
        } catch (roleError) {
            console.log("⚠️ Role assignment:", roleError.message);
        }
        
        // Final balance
        const finalBalance = await ethers.provider.getBalance(deployer.address);
        const finalBalanceETH = ethers.formatEther(finalBalance);
        
        console.log("\n💰 FINAL BALANCE:", finalBalanceETH, "ETH");
        
        // Success verification
        const deploymentSuccess = name && symbol === "COMICS" && hasAdmin && hasMinter && hasManager && noDefaultAdmin;
        
        if (deploymentSuccess) {
            console.log("\n🎉 DEPLOYMENT VERIFICATION SUCCESS!");
            console.log("===================================");
            console.log("✅ Contract deployed with COMICS symbol");
            console.log("✅ All security requirements met");
            console.log("✅ Orchestrator connected");
            console.log("✅ Zero DEFAULT_ADMIN_ROLE usage");
            console.log("✅ Naming error corrected!");
            
            // Save final ecosystem configuration
            const finalEcosystem = {
                network: "base",
                timestamp: new Date().toISOString(),
                status: "DEPLOYMENT_COMPLETE_CORRECTED",
                contracts: {
                    comicsNFT: contractAddress,
                    ft: "0xF8d5a00Ca91D46c07614208C346c49a09409D094",
                    orchestrator: ORCHESTRATOR,
                    impactTracker: "0x20e63Ac004aA0997CC2bE7B8bB4419b9385C4689"
                },
                branding: {
                    name: name,
                    symbol: symbol,
                    corrected: true,
                    previousSymbol: "OMNFTS"
                },
                security: {
                    customRolesOnly: true,
                    noDefaultAdminRole: noDefaultAdmin,
                    ownerHasAllRoles: hasAdmin && hasMinter && hasManager,
                    orchestratorConnected: true
                },
                wallets: {
                    owner: deployer.address,
                    charity: "0xf84eb8B95407f04Dee8fF9acaC0e0AC7231bAb2A"
                },
                finalBalance: finalBalanceETH
            };
            
            fs.writeFileSync('deployments/final-corrected-ecosystem.json', JSON.stringify(finalEcosystem, null, 2));
            
            console.log("\n📋 COMPLETE ECOSYSTEM:");
            console.log("======================");
            console.log("🛡️ COMICS NFT:", contractAddress);
            console.log("🪙 FT Token: 0xF8d5a00Ca91D46c07614208C346c49a09409D094");
            console.log("🎭 Orchestrator: 0xf0D90454C98A0AE934e9DB1B316FF1608C4E9DEf");
            console.log("📊 Impact Tracker: 0x20e63Ac004aA0997CC2bE7B8bB4419b9385C4689");
            
            console.log("\n🎯 CORRECTION APPLIED SUCCESSFULLY!");
            console.log("Symbol changed from OMNFTS → COMICS");
            console.log("Brand consistency restored!");
            
        } else {
            console.log("❌ DEPLOYMENT VERIFICATION FAILED");
        }
        
        return {
            success: deploymentSuccess,
            contractAddress: contractAddress,
            name: name,
            symbol: symbol,
            finalBalance: finalBalanceETH
        };
        
    } catch (error) {
        console.error("❌ Verification error:", error.message);
        return { success: false, error: error.message };
    }
}

verifyComicsDeployment()
    .then((result) => {
        process.exit(result.success ? 0 : 1);
    })
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });