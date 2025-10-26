const { ethers } = require("hardhat");

async function main() {
  const contractAddress = "0xaDcfd61E582573Ccee77003796d20AB1d964649A";
  
  console.log("🔍 Verifying contract at:", contractAddress);
  
  try {
    const LuccaComixToken = await ethers.getContractFactory("LuccaComixToken");
    const token = LuccaComixToken.attach(contractAddress);
    
    console.log("📡 Connecting to contract...");
    
    const name = await token.name();
    console.log("✅ Name:", name);
    
    const symbol = await token.symbol();
    console.log("✅ Symbol:", symbol);
    
    const owner = await token.owner();
    console.log("✅ Owner:", owner);
    
    const totalSupply = await token.totalSupply();
    console.log("✅ Total Supply:", ethers.formatUnits(totalSupply, 18));
    
    console.log("🎉 CONTRACT SUCCESSFULLY DEPLOYED AND INITIALIZED!");
    console.log("🔗 BaseScan: https://basescan.org/address/" + contractAddress);
    
  } catch (error) {
    console.log("❌ Error:", error.message);
    console.log("💡 The contract might be deployed but not initialized properly.");
  }
}

main().catch(console.error);
