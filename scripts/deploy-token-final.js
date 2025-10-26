const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("🚀 Deploying LuccaComixToken (FINAL VERSION)...");
  
  try {
    const LuccaComixToken = await ethers.getContractFactory("LuccaComixToken");
    console.log("✅ Contract factory loaded");
    
    const token = await upgrades.deployProxy(LuccaComixToken, [], {
      initializer: "initialize",
      timeout: 120000
    });
    console.log("✅ Proxy deployment started...");
    
    await token.waitForDeployment();
    const address = await token.getAddress();
    console.log("✅ Proxy deployed to:", address);
    
    // Aspetta per sicurezza
    console.log("⏳ Waiting for blockchain confirmation...");
    await new Promise(resolve => setTimeout(resolve, 10000));
    
    // VERIFICA CRITICA
    console.log("🔍 Verifying deployment...");
    const name = await token.name();
    const symbol = await token.symbol();
    const owner = await token.owner();
    const totalSupply = await token.totalSupply();
    
    console.log("🎉 DEPLOYMENT SUCCESS!");
    console.log("Name:", name);
    console.log("Symbol:", symbol);
    console.log("Owner:", owner);
    console.log("Total Supply:", ethers.formatUnits(totalSupply, 18), "COMIX");
    console.log("🔗 BaseScan: https://basescan.org/address/" + address);
    
    // Salva l'address
    const fs = require('fs');
    fs.writeFileSync('TOKEN_ADDRESS.txt', address);
    console.log("💾 Address saved to TOKEN_ADDRESS.txt");
    
  } catch (error) {
    console.log("❌ Deployment failed:", error.message);
    if (error.message.includes("insufficient funds")) {
      console.log("💡 Need more ETH for gas!");
    }
  }
}

main().catch(console.error);
