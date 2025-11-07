const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("🔧 Testing existing Orchestrator with mock addresses");
  console.log("📍 Contract: 0x361eDa57Cd71C976B638fEC20256a433107c9282");
  
  // Connect to existing contract
  const orchestratorAddress = "0x361eDa57Cd71C976B638fEC20256a433107c9282";
  const abi = [
    "function mintPhotoCombo(string memory tokenURI) external payable",
    "function creator() external view returns (address)",
    "function nextTokenId() external view returns (uint256)"
  ];
  
  const orchestrator = new ethers.Contract(orchestratorAddress, abi, deployer);
  
  try {
    console.log("\n🔍 Contract Info:");
    const creator = await orchestrator.creator();
    const nextId = await orchestrator.nextTokenId();
    console.log("  Creator:", creator);
    console.log("  Next Token ID:", nextId.toString());
    
    // Try a minimal mint (very small amount)
    console.log("\n🧪 Testing mint with minimal amount...");
    const tx = await orchestrator.mintPhotoCombo("ipfs://test", {
      value: ethers.parseEther("0.001"), // Much smaller
      gasLimit: 100000 // Lower gas
    });
    
    console.log("✅ Transaction sent:", tx.hash);
    const receipt = await tx.wait();
    console.log("✅ Transaction confirmed!");
    console.log("🔗 BaseScan:", `https://basescan.org/tx/${tx.hash}`);
    
  } catch (error) {
    console.error("❌ Test failed:", error.message);
    
    if (error.message.includes("insufficient funds")) {
      console.log("\n💡 SOLUTION: You need more ETH on Base network");
      console.log("   Current balance: ~0.0009 ETH");
      console.log("   Recommended: Get 0.01 ETH on Base");
      console.log("   Bridge from: https://bridge.base.org");
    }
    
    if (error.message.includes("execution reverted")) {
      console.log("\n💡 SOLUTION: Contract has mock addresses issue");
      console.log("   The contract tries to call non-existent NFT/FT contracts");
      console.log("   We need to either:");
      console.log("   1. Deploy real NFT/FT contracts");
      console.log("   2. Or deploy a simplified orchestrator");
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });