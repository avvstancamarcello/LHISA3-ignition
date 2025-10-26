const { ethers } = require("hardhat");

async function main() {
  const [signer] = await ethers.getSigners();
  const balance = await ethers.provider.getBalance(signer.address);
  
  console.log("💰 Account Balance:", ethers.formatEther(balance), "ETH");
  console.log("📧 Account Address:", signer.address);
  
  if (balance < ethers.parseEther("0.001")) {
    console.log("❌ INSUFFICIENT FUNDS! Need at least 0.001 ETH for gas");
    console.log("💡 Deposit ETH to Base Network: https://bridge.base.org/");
  } else {
    console.log("✅ Sufficient funds for initialization!");
  }
}

main().catch(console.error);
