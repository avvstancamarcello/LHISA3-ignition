import pkg from 'hardhat';
const { ethers } = pkg;

async function diagnoseFTContract() {
    console.log("🔍 DIAGNOSING FT CONTRACT");
    console.log("=========================");
    
    const ftAddress = "0xF8d5a00Ca91D46c07614208C346c49a09409D094";
    console.log("📍 Contract:", ftAddress);
    
    try {
        const [deployer] = await ethers.getSigners();
        
        // Try to get basic contract info
        const code = await ethers.provider.getCode(ftAddress);
        console.log("✅ Contract exists, code length:", code.length);
        
        // Try different approaches to connect
        console.log("\n🔍 TESTING CONTRACT METHODS:");
        
        try {
            const FTContract = await ethers.getContractFactory("LunaComicsFT");
            const ft = FTContract.attach(ftAddress);
            
            // Test basic ERC20 methods
            console.log("Testing name()...");
            const name = await ft.name();
            console.log("✅ Name:", name || "EMPTY");
            
            console.log("Testing symbol()...");
            const symbol = await ft.symbol();
            console.log("✅ Symbol:", symbol || "EMPTY");
            
            console.log("Testing totalSupply()...");
            const totalSupply = await ft.totalSupply();
            console.log("✅ Total Supply:", ethers.formatEther(totalSupply));
            
            console.log("Testing decimals()...");
            const decimals = await ft.decimals();
            console.log("✅ Decimals:", decimals.toString());
            
            // Test roles
            console.log("\n🔑 TESTING ROLES:");
            const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";
            const hasAdmin = await ft.hasRole(DEFAULT_ADMIN_ROLE, deployer.address);
            console.log("✅ Has DEFAULT_ADMIN_ROLE:", hasAdmin);
            
            if (name === "" && symbol === "" && totalSupply.toString() === "0") {
                console.log("\n⚠️ CONTRACT IS NOT INITIALIZED");
                console.log("Attempting initialization with different approach...");
                
                // Try direct call to initialize
                const initData = ft.interface.encodeFunctionData("initialize", [
                    deployer.address,
                    "Cosmix Protocol Token",
                    "COSMIX", 
                    ethers.parseEther("1000000"),
                    deployer.address
                ]);
                
                console.log("📊 Initialize call data prepared");
                console.log("Data length:", initData.length);
                
                // Estimate gas for initialize
                const gasEstimate = await ethers.provider.estimateGas({
                    to: ftAddress,
                    data: initData,
                    from: deployer.address
                });
                
                console.log("⛽ Gas estimate:", gasEstimate.toString());
                
                // Check if we have enough balance
                const balance = await ethers.provider.getBalance(deployer.address);
                const balanceETH = ethers.formatEther(balance);
                console.log("💰 Balance:", balanceETH, "ETH");
                
                const gasPrice = await ethers.provider.getFeeData();
                const estimatedCost = gasEstimate * gasPrice.gasPrice;
                const estimatedCostETH = ethers.formatEther(estimatedCost);
                console.log("💸 Estimated cost:", estimatedCostETH, "ETH");
                
                if (parseFloat(balanceETH) > parseFloat(estimatedCostETH)) {
                    console.log("\n🚀 EXECUTING INITIALIZATION...");
                    
                    const tx = await deployer.sendTransaction({
                        to: ftAddress,
                        data: initData,
                        gasLimit: gasEstimate
                    });
                    
                    console.log("⏳ Transaction:", tx.hash);
                    const receipt = await tx.wait();
                    console.log("✅ Block:", receipt.blockNumber);
                    console.log("✅ Status:", receipt.status === 1 ? "SUCCESS" : "FAILED");
                    
                    if (receipt.status === 1) {
                        // Verify after init
                        const newName = await ft.name();
                        const newSymbol = await ft.symbol();
                        const newSupply = await ft.totalSupply();
                        
                        console.log("\n🎉 INITIALIZATION SUCCESS!");
                        console.log("Name:", newName);
                        console.log("Symbol:", newSymbol);
                        console.log("Supply:", ethers.formatEther(newSupply));
                    }
                } else {
                    console.log("❌ Insufficient balance for initialization");
                }
                
            } else {
                console.log("\n✅ CONTRACT ALREADY INITIALIZED");
                console.log("Current state is valid");
            }
            
        } catch (contractError) {
            console.log("❌ Contract interaction error:", contractError.message);
            
            // Try as generic contract
            console.log("\n🔍 TRYING GENERIC ERC20 INTERFACE...");
            const genericERC20 = new ethers.Contract(
                ftAddress,
                [
                    "function name() view returns (string)",
                    "function symbol() view returns (string)", 
                    "function totalSupply() view returns (uint256)",
                    "function decimals() view returns (uint8)"
                ],
                ethers.provider
            );
            
            try {
                const name = await genericERC20.name();
                const symbol = await genericERC20.symbol();
                console.log("✅ Generic check - Name:", name);
                console.log("✅ Generic check - Symbol:", symbol);
            } catch (genericError) {
                console.log("❌ Generic interface also failed:", genericError.message);
            }
        }
        
    } catch (error) {
        console.error("❌ Diagnosis error:", error.message);
    }
}

diagnoseFTContract()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });