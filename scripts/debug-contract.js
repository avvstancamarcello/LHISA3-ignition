const { ethers } = require("hardhat");

async function main() {
  const contractAddress = "0xaDcfd61E582573Ccee77003796d20AB1d964649A";
  
  console.log("🔍 Debugging contract...");
  
  const LuccaComixToken = await ethers.getContractFactory("LuccaComixToken");
  const token = LuccaComixToken.attach(contractAddress);
  
  try {
    // Prova a leggere diverse proprietà
    console.log("1. Testing name()...");
    const name = await token.name();
    console.log("   Name:", name);
    
    console.log("2. Testing symbol()...");
    const symbol = await token.symbol();
    console.log("   Symbol:", symbol);
    
    console.log("3. Testing owner()...");
    const owner = await token.owner();
    console.log("   Owner:", owner);
    
    console.log("4. Testing totalSupply()...");
    const totalSupply = await token.totalSupply();
    console.log("   Total Supply:", ethers.formatUnits(totalSupply, 18));
    
    console.log("5. Testing implementation address...");
    const implementation = await ethers.provider.getStorage(contractAddress, "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc");
    console.log("   Implementation:", implementation);
    
  } catch (error) {
    console.log("❌ Error:", error.message);
  }
}

main().catch(console.error);
