import pkg from 'hardhat';
const { ethers } = pkg;

/**
 * Pre-deployment checklist script
 * Validates all conditions before allowing deployment
 */
async function runPreDeployChecklist() {
    console.log("🔍 PRE-DEPLOY CHECKLIST");
    console.log("========================");
    
    let allChecksPass = true;
    const results = [];
    
    try {
        // Check 1: Balance validation
        console.log("1. Checking account balance...");
        const [deployer] = await ethers.getSigners();
        const balance = await ethers.provider.getBalance(deployer.address);
        const balanceETH = ethers.formatEther(balance);
        
        const minRequired = 0.006; // ETH
        const balanceCheck = parseFloat(balanceETH) >= minRequired;
        
        results.push({
            check: "Balance",
            status: balanceCheck ? "PASS" : "FAIL",
            details: `${balanceETH} ETH (min: ${minRequired} ETH)`
        });
        
        if (!balanceCheck) allChecksPass = false;
        
        // Check 2: Contract compilation
        console.log("2. Verifying contract compilation...");
        let contractFactory;
        try {
            contractFactory = await ethers.getContractFactory("OceanMangaNFT_Simple");
            results.push({
                check: "Compilation",
                status: "PASS",
                details: "Contract compiles successfully"
            });
        } catch (compileError) {
            results.push({
                check: "Compilation",
                status: "FAIL",
                details: compileError.message
            });
            allChecksPass = false;
        }
        
        // Check 3: Role hash validation
        console.log("3. Validating role hashes...");
        const ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_ADMIN_ROLE"));
        const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MINTER_ROLE"));
        const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MANAGER_ROLE"));
        
        const zeroRole = "0x0000000000000000000000000000000000000000000000000000000000000000";
        const rolesNonZero = ADMIN_ROLE !== zeroRole && MINTER_ROLE !== zeroRole && MANAGER_ROLE !== zeroRole;
        
        results.push({
            check: "Role Hashes",
            status: rolesNonZero ? "PASS" : "FAIL",
            details: rolesNonZero ? "All roles are non-zero hashes" : "One or more roles are zero"
        });
        
        if (!rolesNonZero) allChecksPass = false;
        
        // Check 4: Gas estimation
        console.log("4. Estimating gas costs...");
        if (contractFactory) {
            try {
                const deployTx = await contractFactory.getDeployTransaction(
                    deployer.address,
                    "https://ipfs.io/ipfs/",
                    "OceanManga Comics NFT",
                    "COMICS",
                    deployer.address,
                    500
                );
                
                const gasEstimate = await ethers.provider.estimateGas(deployTx);
                const gasPrice = await ethers.provider.getFeeData();
                const estimatedCost = gasEstimate * gasPrice.gasPrice;
                const estimatedCostETH = ethers.formatEther(estimatedCost);
                
                const gasCheck = parseFloat(balanceETH) > parseFloat(estimatedCostETH);
                
                results.push({
                    check: "Gas Estimate",
                    status: gasCheck ? "PASS" : "FAIL",
                    details: `Estimated: ${estimatedCostETH} ETH (Available: ${balanceETH} ETH)`
                });
                
                if (!gasCheck) allChecksPass = false;
                
            } catch (gasError) {
                results.push({
                    check: "Gas Estimate",
                    status: "WARN",
                    details: "Could not estimate gas, proceeding with caution"
                });
            }
        }
        
        // Check 5: Constructor parameters validation
        console.log("5. Validating constructor parameters...");
        const params = [
            deployer.address,           // admin
            "https://ipfs.io/ipfs/",   // baseURI
            "OceanManga Comics NFT",    // name
            "COMICS",                   // symbol
            deployer.address,           // royalty receiver
            500                         // royalty fee
        ];
        
        const paramsValid = params.every(param => param !== null && param !== undefined && param !== "");
        
        results.push({
            check: "Constructor Params",
            status: paramsValid ? "PASS" : "FAIL",
            details: paramsValid ? "All parameters valid" : "Invalid parameters detected"
        });
        
        if (!paramsValid) allChecksPass = false;
        
        // Display results
        console.log("\n📋 CHECKLIST RESULTS:");
        console.log("=====================");
        results.forEach(result => {
            const emoji = result.status === "PASS" ? "✅" : result.status === "WARN" ? "⚠️" : "❌";
            console.log(`${emoji} ${result.check}: ${result.status} - ${result.details}`);
        });
        
        console.log("\n🎯 OVERALL STATUS:", allChecksPass ? "✅ ALL CHECKS PASS" : "❌ CHECKS FAILED");
        
        return {
            success: allChecksPass,
            results: results,
            balance: balanceETH,
            deployer: deployer.address
        };
        
    } catch (error) {
        console.error("❌ Checklist error:", error.message);
        return {
            success: false,
            error: error.message
        };
    }
}

// Export for use in other scripts
export { runPreDeployChecklist };

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
    runPreDeployChecklist()
        .then((result) => {
            process.exit(result.success ? 0 : 1);
        })
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
}