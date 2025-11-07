const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  const provider = deployer.provider;
  
  const sponsorVaultAddress = "0xB19Ee3A16554d339111028fe3a76fEE5AE45E8A3";
  const expectedOwner = "0x8495B3f7493263685fFcDA2602fFfF349d4eD3B8";
  
  console.log("🔍 Analisi SponsorVault Contract");
  console.log("Address:", sponsorVaultAddress);
  console.log("Expected Owner:", expectedOwner);
  console.log("Current Signer:", deployer.address);
  console.log("=" * 50);
  
  try {
    // Get contract code to verify it exists
    const code = await provider.getCode(sponsorVaultAddress);
    console.log("✅ Contract exists (code length:", code.length, "bytes)");
    
    // Get contract instance
    const sponsorVault = await ethers.getContractAt("SolidarySponsorVault", sponsorVaultAddress);
    
    // Check AccessControl roles (this contract uses AccessControl, not Ownable)
    try {
      const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";
      const SPONSOR_ROLE = await sponsorVault.SPONSOR_ROLE();
      
      const hasAdminRole = await sponsorVault.hasRole(DEFAULT_ADMIN_ROLE, expectedOwner);
      const hasSponsorRole = await sponsorVault.hasRole(SPONSOR_ROLE, expectedOwner);
      const currentSignerHasAdmin = await sponsorVault.hasRole(DEFAULT_ADMIN_ROLE, deployer.address);
      const currentSignerHasSponsor = await sponsorVault.hasRole(SPONSOR_ROLE, deployer.address);
      
      console.log("📋 AccessControl Analysis:");
      console.log("  Expected Owner has ADMIN role:", hasAdminRole);
      console.log("  Expected Owner has SPONSOR role:", hasSponsorRole);
      console.log("  Current Signer has ADMIN role:", currentSignerHasAdmin);
      console.log("  Current Signer has SPONSOR role:", currentSignerHasSponsor);
      console.log("  SPONSOR_ROLE hash:", SPONSOR_ROLE);
      
    } catch (error) {
      console.log("⚠️  Cannot read AccessControl roles:", error.message);
    }
    
    // Check balance
    try {
      const balance = await provider.getBalance(sponsorVaultAddress);
      console.log("💰 Contract Balance:", ethers.formatEther(balance), "MATIC");
    } catch (error) {
      console.log("⚠️  Cannot read balance:", error.message);
    }
    
    // Get creation transaction (if recent enough)
    try {
      console.log("\n🔍 Searching for creation transaction...");
      
      // Get recent blocks to find creation
      const latestBlock = await provider.getBlock("latest");
      const searchBlocks = 1000; // Search last 1000 blocks
      
      for (let i = 0; i < searchBlocks; i++) {
        const blockNumber = latestBlock.number - i;
        if (blockNumber < 0) break;
        
        try {
          const block = await provider.getBlock(blockNumber, true);
          if (block && block.transactions) {
            for (const tx of block.transactions) {
              if (tx.to === null && tx.from && tx.from.toLowerCase() === expectedOwner.toLowerCase()) {
                // This might be a contract creation
                const receipt = await provider.getTransactionReceipt(tx.hash);
                if (receipt && receipt.contractAddress && 
                    receipt.contractAddress.toLowerCase() === sponsorVaultAddress.toLowerCase()) {
                  console.log("🎯 Found creation transaction!");
                  console.log("  TX Hash:", tx.hash);
                  console.log("  Block:", blockNumber);
                  console.log("  From:", tx.from);
                  console.log("  Gas Used:", receipt.gasUsed.toString());
                  return;
                }
              }
            }
          }
        } catch (blockError) {
          // Skip problematic blocks
          continue;
        }
        
        if (i % 100 === 0) {
          console.log(`  Searched ${i} blocks...`);
        }
      }
      
      console.log("ℹ️  Creation transaction not found in recent blocks");
      
    } catch (error) {
      console.log("⚠️  Cannot search creation transaction:", error.message);
    }
    
    // Try to call some common functions
    console.log("\n🔧 Testing contract functions...");
    
    try {
      // Test if we can call available functions
      const contract = await ethers.getContractAt("SolidarySponsorVault", sponsorVaultAddress);
      
      // Get contract interface to see available functions
      console.log("📜 Available functions:");
      const interface = contract.interface;
      const functions = Object.keys(interface.functions);
      functions.forEach(func => {
        console.log("  -", func);
      });
      
    } catch (error) {
      console.log("⚠️  Cannot read contract interface:", error.message);
    }
    
  } catch (error) {
    console.error("❌ Error analyzing contract:", error.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });