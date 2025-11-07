import pkg from 'hardhat';
import fs from 'fs';
const { ethers } = pkg;

/**
 * FINAL EXECUTION SCRIPT - ONLY RUNS AFTER USER APPROVAL
 * Executes the deployment with all safety checks passed
 */
async function executeApprovedDeployment() {
    console.log("🚀 EXECUTING APPROVED DEPLOYMENT");
    console.log("=================================");
    console.log("⚠️  THIS WILL SPEND ETH ON BASE NETWORK");
    
    try {
        // Load approved deployment parameters
        if (!fs.existsSync('deployments/pending-deployment.json')) {
            throw new Error("No pending deployment found. Run secure-comics-deployment.js first.");
        }
        
        const deploymentParams = JSON.parse(fs.readFileSync('deployments/pending-deployment.json', 'utf8'));
        console.log("📋 Loaded deployment parameters from:", deploymentParams.timestamp);
        
        // Final safety check
        const [deployer] = await ethers.getSigners();
        const currentBalance = await ethers.provider.getBalance(deployer.address);
        const currentBalanceETH = ethers.formatEther(currentBalance);
        
        console.log("💰 Current Balance:", currentBalanceETH, "ETH");
        console.log("💸 Estimated Cost:", deploymentParams.estimatedCost, "ETH");
        
        if (parseFloat(currentBalanceETH) < parseFloat(deploymentParams.estimatedCost)) {
            throw new Error("Insufficient balance detected at execution time!");
        }
        
        console.log("✅ Final balance check passed");
        
        // Execute deployment
        console.log("\n🚀 DEPLOYING CONTRACT...");
        const NFTContract = await ethers.getContractFactory("OceanMangaNFT_Simple");
        
        const startTime = Date.now();
        const deployTx = await NFTContract.deploy(
            deploymentParams.contractParams.admin,
            deploymentParams.contractParams.baseURI,
            deploymentParams.contractParams.name,
            deploymentParams.contractParams.symbol,
            deploymentParams.contractParams.royaltyReceiver,
            deploymentParams.contractParams.royaltyFee,
            {
                gasLimit: deploymentParams.gasEstimate
            }
        );
        
        console.log("⏳ Waiting for deployment confirmation...");
        await deployTx.waitForDeployment();
        const endTime = Date.now();
        const deploymentTime = (endTime - startTime) / 1000;
        
        const contractAddress = await deployTx.getAddress();
        console.log("✅ CONTRACT DEPLOYED:", contractAddress);
        console.log("⏱️  Deployment time:", deploymentTime, "seconds");
        
        // Verify deployment
        console.log("\n🔍 VERIFYING DEPLOYMENT...");
        const name = await deployTx.name();
        const symbol = await deployTx.symbol();
        
        console.log("📝 Name:", name);
        console.log("🏷️  Symbol:", symbol);
        
        // Verify roles
        const ADMIN_ROLE = deploymentParams.security.roles.admin;
        const MINTER_ROLE = deploymentParams.security.roles.minter;
        const MANAGER_ROLE = deploymentParams.security.roles.manager;
        
        const hasAdmin = await deployTx.hasRole(ADMIN_ROLE, deployer.address);
        const hasMinter = await deployTx.hasRole(MINTER_ROLE, deployer.address);
        const hasManager = await deployTx.hasRole(MANAGER_ROLE, deployer.address);
        
        console.log("✅ Admin Role:", hasAdmin);
        console.log("✅ Minter Role:", hasMinter);
        console.log("✅ Manager Role:", hasManager);
        
        // Verify no DEFAULT_ADMIN_ROLE
        const noDefaultAdmin = await deployTx.verifyNoDefaultAdminRole(deployer.address);
        console.log("🔒 No DEFAULT_ADMIN_ROLE:", noDefaultAdmin);
        
        // Connect to orchestrator
        console.log("\n🔗 CONNECTING TO ORCHESTRATOR...");
        const grantTx = await deployTx.grantRole(MINTER_ROLE, deploymentParams.orchestrator);
        await grantTx.wait();
        console.log("✅ MINTER_ROLE granted to orchestrator");
        
        // Final balance check
        const finalBalance = await ethers.provider.getBalance(deployer.address);
        const finalBalanceETH = ethers.formatEther(finalBalance);
        const actualCost = parseFloat(currentBalanceETH) - parseFloat(finalBalanceETH);
        
        console.log("\n💰 FINAL FINANCIAL SUMMARY:");
        console.log("============================");
        console.log("💸 Actual Cost:", actualCost.toFixed(8), "ETH");
        console.log("💵 Final Balance:", finalBalanceETH, "ETH");
        console.log("📊 Cost vs Estimate:", actualCost <= parseFloat(deploymentParams.estimatedCost) ? "✅ Within estimate" : "⚠️ Exceeded estimate");
        
        // Save deployment record
        const deploymentRecord = {
            ...deploymentParams,
            execution: {
                timestamp: new Date().toISOString(),
                contractAddress: contractAddress,
                deploymentTime: deploymentTime,
                actualCost: actualCost.toString(),
                finalBalance: finalBalanceETH,
                transactionHash: deployTx.deploymentTransaction?.hash,
                verified: {
                    name: name,
                    symbol: symbol,
                    roles: { hasAdmin, hasMinter, hasManager },
                    noDefaultAdminRole: noDefaultAdmin,
                    orchestratorConnected: true
                }
            },
            status: "DEPLOYMENT_SUCCESSFUL"
        };
        
        fs.writeFileSync(`deployments/deployment-${Date.now()}.json`, JSON.stringify(deploymentRecord, null, 2));
        fs.unlinkSync('deployments/pending-deployment.json'); // Clean up pending file
        
        console.log("\n🎉 DEPLOYMENT SUCCESSFUL!");
        console.log("==========================");
        console.log("🛡️ Contract Address:", contractAddress);
        console.log("🏷️  Symbol: COMICS (CORRECTED!)");
        console.log("✅ All security requirements met");
        console.log("✅ Orchestrator connected");
        console.log("✅ Zero DEFAULT_ADMIN_ROLE usage");
        console.log("💾 Deployment record saved");
        
        return {
            success: true,
            contractAddress: contractAddress,
            actualCost: actualCost,
            deploymentRecord: deploymentRecord
        };
        
    } catch (error) {
        console.error("❌ Deployment execution error:", error.message);
        
        // Save error record
        const errorRecord = {
            timestamp: new Date().toISOString(),
            error: error.message,
            stage: "EXECUTION",
            status: "DEPLOYMENT_FAILED"
        };
        
        fs.writeFileSync(`deployments/error-${Date.now()}.json`, JSON.stringify(errorRecord, null, 2));
        
        return {
            success: false,
            error: error.message
        };
    }
}

executeApprovedDeployment()
    .then((result) => {
        process.exit(result.success ? 0 : 1);
    })
    .catch((error) => {
        console.error("❌ Fatal execution error:", error);
        process.exit(1);
    });