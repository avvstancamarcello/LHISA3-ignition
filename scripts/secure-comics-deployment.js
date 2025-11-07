import pkg from 'hardhat';
import fs from 'fs';
import { runPreDeployChecklist } from './pre-deploy-checklist.js';
const { ethers } = pkg;

/**
 * SECURE DEPLOYMENT SCRIPT WITH EXPLICIT APPROVAL
 * Will NOT deploy without user's explicit GO command
 */
async function secureComicsDeployment() {
    console.log("🛡️ SECURE COMICS NFT DEPLOYMENT");
    console.log("================================");
    console.log("⚠️  DEPLOYMENT WILL REQUIRE EXPLICIT USER APPROVAL");
    console.log("⚠️  ALL CHECKS MUST PASS BEFORE PROCEEDING");
    
    try {
        // Step 1: Run pre-deploy checklist
        console.log("\n🔍 RUNNING PRE-DEPLOY CHECKLIST...");
        const checklistResult = await runPreDeployChecklist();
        
        if (!checklistResult.success) {
            console.log("❌ PRE-DEPLOY CHECKLIST FAILED!");
            console.log("Deployment ABORTED for safety.");
            return { success: false, reason: "Checklist failed" };
        }
        
        console.log("✅ PRE-DEPLOY CHECKLIST PASSED!");
        
        // Step 2: Final deployment summary
        const [deployer] = await ethers.getSigners();
        const balance = await ethers.provider.getBalance(deployer.address);
        const balanceETH = ethers.formatEther(balance);
        
        console.log("\n📋 DEPLOYMENT SUMMARY:");
        console.log("======================");
        console.log("🎯 Contract: OceanMangaNFT_Simple");
        console.log("📝 Name: 'OceanManga Comics NFT'");
        console.log("🏷️  Symbol: 'COMICS' (CORRECTED!)");
        console.log("👤 Deployer:", deployer.address);
        console.log("💰 Balance:", balanceETH, "ETH");
        console.log("⛽ Estimated Cost: ~0.000011 ETH");
        console.log("🔒 Security: Zero DEFAULT_ADMIN_ROLE guaranteed");
        
        // Step 3: Gas estimation details
        console.log("\n⛽ DETAILED GAS ESTIMATION:");
        console.log("===========================");
        const NFTContract = await ethers.getContractFactory("OceanMangaNFT_Simple");
        const deployTx = await NFTContract.getDeployTransaction(
            deployer.address,
            "https://ipfs.io/ipfs/",
            "OceanManga Comics NFT",
            "COMICS",
            deployer.address,
            500
        );
        
        const gasEstimate = await ethers.provider.estimateGas(deployTx);
        const feeData = await ethers.provider.getFeeData();
        const estimatedCost = gasEstimate * feeData.gasPrice;
        const estimatedCostETH = ethers.formatEther(estimatedCost);
        const remainingBalance = parseFloat(balanceETH) - parseFloat(estimatedCostETH);
        
        console.log("📊 Gas Limit:", gasEstimate.toString());
        console.log("💲 Gas Price:", ethers.formatUnits(feeData.gasPrice, "gwei"), "gwei");
        console.log("💰 Total Cost:", estimatedCostETH, "ETH");
        console.log("💵 Remaining:", remainingBalance.toFixed(6), "ETH");
        
        // Step 4: Security verification summary
        console.log("\n🔒 SECURITY VERIFICATION:");
        console.log("=========================");
        const ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_ADMIN_ROLE"));
        const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MINTER_ROLE"));
        const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MANAGER_ROLE"));
        
        console.log("✅ ADMIN_ROLE:", ADMIN_ROLE.substring(0, 20) + "...");
        console.log("✅ MINTER_ROLE:", MINTER_ROLE.substring(0, 20) + "...");
        console.log("✅ MANAGER_ROLE:", MANAGER_ROLE.substring(0, 20) + "...");
        console.log("🚫 DEFAULT_ADMIN_ROLE: WILL NOT BE USED");
        
        // Step 5: CRITICAL - WAIT FOR USER APPROVAL
        console.log("\n⚠️  DEPLOYMENT READY - AWAITING YOUR APPROVAL");
        console.log("==============================================");
        console.log("🔴 This deployment will spend ~" + estimatedCostETH + " ETH");
        console.log("🔴 Contract symbol will be 'COMICS' (correcting previous error)");
        console.log("🔴 All security checks have passed");
        console.log("🔴 Orchestrator will be automatically connected");
        
        console.log("\n❌ DEPLOYMENT PAUSED - MANUAL APPROVAL REQUIRED");
        console.log("To proceed, you must run:");
        console.log("npx hardhat run scripts/execute-approved-deployment.js --network base");
        
        // Save deployment parameters for execution script
        const deploymentParams = {
            timestamp: new Date().toISOString(),
            deployer: deployer.address,
            balance: balanceETH,
            estimatedCost: estimatedCostETH,
            gasEstimate: gasEstimate.toString(),
            gasPrice: feeData.gasPrice.toString(),
            contractParams: {
                admin: deployer.address,
                baseURI: "https://ipfs.io/ipfs/",
                name: "OceanManga Comics NFT",
                symbol: "COMICS",
                royaltyReceiver: deployer.address,
                royaltyFee: 500
            },
            security: {
                roles: {
                    admin: ADMIN_ROLE,
                    minter: MINTER_ROLE,
                    manager: MANAGER_ROLE
                },
                noDefaultAdminRole: true
            },
            orchestrator: "0xf0D90454C98A0AE934e9DB1B316FF1608C4E9DEf"
        };
        
        fs.writeFileSync('deployments/pending-deployment.json', JSON.stringify(deploymentParams, null, 2));
        
        console.log("\n💾 Deployment parameters saved to: deployments/pending-deployment.json");
        console.log("🎯 Ready for your approval!");
        
        return {
            success: true,
            stage: "AWAITING_APPROVAL",
            params: deploymentParams
        };
        
    } catch (error) {
        console.error("❌ Secure deployment preparation error:", error.message);
        return {
            success: false,
            error: error.message
        };
    }
}

secureComicsDeployment()
    .then((result) => {
        if (result.success && result.stage === "AWAITING_APPROVAL") {
            console.log("\n✅ DEPLOYMENT PREPARATION COMPLETE");
            console.log("Awaiting your approval to proceed with actual deployment.");
            process.exit(0);
        } else {
            console.log("❌ DEPLOYMENT PREPARATION FAILED");
            process.exit(1);
        }
    })
    .catch((error) => {
        console.error("❌ Fatal error:", error);
        process.exit(1);
    });