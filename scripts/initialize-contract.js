const { ethers } = require("hardhat");

async function main() {
  const contractAddress = "0xaDcfd61E582573Ccee77003796d20AB1d964649A";
  
  console.log("🚀 Initializing LuccaComixToken...");
  console.log("📝 Contract:", contractAddress);
  
  const LuccaComixToken = await ethers.getContractFactory("LuccaComixToken");
  const token = LuccaComixToken.attach(contractAddress);
  
  try {
    console.log("⏳ Sending initialize transaction...");
    const tx = await token.initialize();
    console.log("📫 Transaction sent:", tx.hash);
    
    console.log("⏰ Waiting for confirmation...");
    const receipt = await tx.wait();
    
    console.log("✅ Contract initialized successfully!");
    console.log("📊 Gas used:", receipt.gasUsed.toString());
    
    // Verifica
    const name = await token.name();
    const symbol = await token.symbol();
    const owner = await token.owner();
    const totalSupply = await token.totalSupply();
    
    console.log("🎉 VERIFICATION:");
    console.log("Name:", name);
    console.log("Symbol:", symbol);
    console.log("Owner:", owner);
    console.log("Total Supply:", ethers.formatUnits(totalSupply, 18), "COMIX");
    
  } catch (error) {
    console.log("❌ Initialization failed:", error.message);
    if (error.message.includes("insufficient funds")) {
      console.log("💡 DEPOSIT MORE ETH TO BASE NETWORK!");
    }
  }
}

main().catch(console.error);
