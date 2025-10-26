const { ethers } = require("hardhat");

async function main() {
  const solidaryAddress = "0xC3b8B00a45F66821b885a1372434D1072D6b6B77";
  
  console.log("🧪 Testing LuccaComixSolidary functions...");
  
  const LuccaComixSolidary = await ethers.getContractFactory("LuccaComixSolidary");
  const solidary = LuccaComixSolidary.attach(solidaryAddress);
  
  try {
    // Test getContractInfo
    const contractInfo = await solidary.getContractInfo();
    console.log("📊 Contract Info:");
    console.log("  Token Address:", contractInfo[0]);
    console.log("  NFT Address:", contractInfo[1]);
    console.log("  Owner:", contractInfo[2]);
    console.log("  Charity Count:", contractInfo[3].toString());
    console.log("  Hourly Prize:", contractInfo[4].toString());
    
    // Test getCharityCount
    const charityCount = await solidary.getCharityCount();
    console.log("❤️  Charity Count:", charityCount.toString());
    
    // Test current hour participants
    const participants = await solidary.getCurrentHourParticipants();
    console.log("🎰 Current Hour Participants:", participants.toString());
    
    console.log("✅ All functions working correctly!");
    
  } catch (error) {
    console.log("❌ Error testing functions:", error.message);
  }
}

main().catch(console.error);
