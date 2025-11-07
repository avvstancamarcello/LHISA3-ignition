import pkg from 'hardhat';
const { ethers } = pkg;

/**
 * Unit tests for OceanMangaNFT_Simple contract
 * Tests initialization, role assignment, and security features
 */
async function runContractTests() {
    console.log("🧪 CONTRACT UNIT TESTS");
    console.log("======================");
    
    let allTestsPass = true;
    const testResults = [];
    
    try {
        const [deployer, user1] = await ethers.getSigners();
        
        // Test 1: Contract deployment and initialization
        console.log("1. Testing contract deployment...");
        const NFTContract = await ethers.getContractFactory("OceanMangaNFT_Simple");
        
        const testContract = await NFTContract.deploy(
            deployer.address,
            "https://test.ipfs.io/",
            "Test Comics NFT",
            "TESTCOMICS",
            deployer.address,
            500
        );
        
        await testContract.waitForDeployment();
        const contractAddress = await testContract.getAddress();
        
        testResults.push({
            test: "Contract Deployment",
            status: "PASS",
            details: `Deployed at ${contractAddress}`
        });
        
        // Test 2: Name and symbol validation
        console.log("2. Testing name and symbol...");
        const name = await testContract.name();
        const symbol = await testContract.symbol();
        
        const nameSymbolTest = name === "Test Comics NFT" && symbol === "TESTCOMICS";
        testResults.push({
            test: "Name/Symbol",
            status: nameSymbolTest ? "PASS" : "FAIL",
            details: `Name: ${name}, Symbol: ${symbol}`
        });
        
        if (!nameSymbolTest) allTestsPass = false;
        
        // Test 3: Role assignments
        console.log("3. Testing role assignments...");
        const ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_ADMIN_ROLE"));
        const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MINTER_ROLE"));
        const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MANAGER_ROLE"));
        
        const hasAdmin = await testContract.hasRole(ADMIN_ROLE, deployer.address);
        const hasMinter = await testContract.hasRole(MINTER_ROLE, deployer.address);
        const hasManager = await testContract.hasRole(MANAGER_ROLE, deployer.address);
        
        const rolesTest = hasAdmin && hasMinter && hasManager;
        testResults.push({
            test: "Role Assignment",
            status: rolesTest ? "PASS" : "FAIL",
            details: `Admin: ${hasAdmin}, Minter: ${hasMinter}, Manager: ${hasManager}`
        });
        
        if (!rolesTest) allTestsPass = false;
        
        // Test 4: DEFAULT_ADMIN_ROLE verification (CRITICAL)
        console.log("4. Testing DEFAULT_ADMIN_ROLE security...");
        const noDefaultAdmin = await testContract.verifyNoDefaultAdminRole(deployer.address);
        
        testResults.push({
            test: "No DEFAULT_ADMIN_ROLE",
            status: noDefaultAdmin ? "PASS" : "FAIL",
            details: noDefaultAdmin ? "Deployer has NO default admin role" : "SECURITY BREACH: Has default admin role"
        });
        
        if (!noDefaultAdmin) allTestsPass = false;
        
        // Test 5: Minting functionality
        console.log("5. Testing minting functionality...");
        try {
            const mintTx = await testContract.mint(user1.address, 1, 10, "0x");
            await mintTx.wait();
            
            const balance = await testContract.balanceOf(user1.address, 1);
            const mintTest = balance.toString() === "10";
            
            testResults.push({
                test: "Minting Function",
                status: mintTest ? "PASS" : "FAIL",
                details: `Minted 10 tokens, balance: ${balance.toString()}`
            });
            
            if (!mintTest) allTestsPass = false;
            
        } catch (mintError) {
            testResults.push({
                test: "Minting Function",
                status: "FAIL",
                details: `Mint failed: ${mintError.message}`
            });
            allTestsPass = false;
        }
        
        // Test 6: Role-based access control
        console.log("6. Testing access control...");
        try {
            // Try minting from non-minter account (should fail)
            const userContract = testContract.connect(user1);
            await userContract.mint(user1.address, 2, 5, "0x");
            
            // If we reach here, access control failed
            testResults.push({
                test: "Access Control",
                status: "FAIL",
                details: "Non-minter was able to mint tokens"
            });
            allTestsPass = false;
            
        } catch (accessError) {
            // This should fail - good!
            testResults.push({
                test: "Access Control",
                status: "PASS",
                details: "Non-minter correctly denied access"
            });
        }
        
        // Display test results
        console.log("\n📋 TEST RESULTS:");
        console.log("=================");
        testResults.forEach(result => {
            const emoji = result.status === "PASS" ? "✅" : "❌";
            console.log(`${emoji} ${result.test}: ${result.status} - ${result.details}`);
        });
        
        console.log("\n🎯 OVERALL TESTS:", allTestsPass ? "✅ ALL TESTS PASS" : "❌ TESTS FAILED");
        
        return {
            success: allTestsPass,
            results: testResults,
            contractAddress: contractAddress
        };
        
    } catch (error) {
        console.error("❌ Test error:", error.message);
        return {
            success: false,
            error: error.message
        };
    }
}

// Export for use in other scripts
export { runContractTests };

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
    runContractTests()
        .then((result) => {
            process.exit(result.success ? 0 : 1);
        })
        .catch((error) => {
            console.error(error);
            process.exit(1);
        });
}