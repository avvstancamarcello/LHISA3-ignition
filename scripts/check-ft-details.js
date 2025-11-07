import pkg from 'hardhat';
const { ethers } = pkg;

async function checkFTTokenDetails() {
    console.log("🪙 CHECKING FT TOKEN DETAILS");
    console.log("=============================");
    
    const ftAddress = "0xF8d5a00Ca91D46c07614208C346c49a09409D094";
    console.log("📍 FT Contract Address:", ftAddress);
    
    try {
        // Wait for network propagation
        console.log("⏳ Connecting to FT contract...");
        
        const FTContract = await ethers.getContractFactory("LunaComicsFT");
        const ft = FTContract.attach(ftAddress);
        
        // Get token details
        console.log("\n📝 FT TOKEN PROPERTIES:");
        const name = await ft.name();
        const symbol = await ft.symbol();
        const decimals = await ft.decimals();
        
        console.log("✅ Name:", name);
        console.log("✅ Symbol:", symbol);
        console.log("✅ Decimals:", decimals.toString());
        
        // Get deployer info
        const [deployer] = await ethers.getSigners();
        const balance = await ft.balanceOf(deployer.address);
        const totalSupply = await ft.totalSupply();
        
        console.log("\n💰 TOKEN SUPPLY INFO:");
        console.log("✅ Total Supply:", ethers.formatEther(totalSupply));
        console.log("✅ Owner Balance:", ethers.formatEther(balance));
        
        // Check roles if available
        try {
            const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
            const hasMinterRole = await ft.hasRole(MINTER_ROLE, deployer.address);
            console.log("✅ Owner has MINTER_ROLE:", hasMinterRole);
        } catch (roleError) {
            console.log("⚠️ Role check not available");
        }
        
        console.log("\n🔍 BRANDING ANALYSIS:");
        console.log("======================");
        console.log("🏷️ Current FT Symbol:", symbol);
        console.log("🏷️ Current NFT Symbol: COMICS");
        
        if (symbol.includes("LUNA") || symbol.includes("COMICS")) {
            console.log("✅ FT symbol is brand-aligned");
        } else {
            console.log("⚠️ FT symbol may need branding review");
        }
        
        return {
            success: true,
            name: name,
            symbol: symbol,
            decimals: decimals.toString(),
            totalSupply: ethers.formatEther(totalSupply),
            ownerBalance: ethers.formatEther(balance)
        };
        
    } catch (error) {
        console.error("❌ FT check error:", error.message);
        
        // Try alternative approach - check deployment files
        console.log("\n📁 Checking deployment records...");
        try {
            const fs = await import('fs');
            const files = fs.readdirSync('deployments/');
            console.log("Available deployment files:", files);
            
            // Look for FT deployment info in files
            for (const file of files) {
                if (file.includes('ecosystem') || file.includes('ft')) {
                    const content = fs.readFileSync(`deployments/${file}`, 'utf8');
                    const data = JSON.parse(content);
                    console.log(`Found in ${file}:`, data);
                }
            }
        } catch (fsError) {
            console.log("❌ Could not read deployment files:", fsError.message);
        }
        
        return { success: false, error: error.message };
    }
}

checkFTTokenDetails()
    .then((result) => {
        if (result.success) {
            console.log("\n🎯 FT TOKEN SUMMARY:");
            console.log("====================");
            console.log("Name:", result.name);
            console.log("Symbol:", result.symbol);
            console.log("Total Supply:", result.totalSupply);
        }
        process.exit(result.success ? 0 : 1);
    })
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });