import { ethers } from "hardhat";

async function main() {
  console.log("🔍 Checking Trust Certificates Status...");
  
  const trustManagerAddress = "0x625c95A763F900f3d60fdCEC01A4474B985bAb45";
  const TrustManager = await ethers.getContractFactory("SolidaryTrustManager");
  const trustManager = TrustManager.attach(trustManagerAddress);
  
  const contracts = [
    { name: "SolidaryHub", address: "0xE9458CdA8e3dA88E1b1588EeCd6b1CFE2A398602" },
    { name: "OraculumCaritatis", address: "0xcc516a4374021d4a959A6887F2b1501F372f27F6" }
  ];
  
  for (const contract of contracts) {
    const isValid = await trustManager.validateCertificate(contract.address);
    console.log(`${contract.name}: ${isValid ? "✅ CERTIFIED" : "❌ NOT CERTIFIED"}`);
    
    if (isValid) {
      const cert = await trustManager.certificates(contract.address);
      console.log(`   📅 Valid until: ${new Date(cert.validUntil * 1000).toLocaleDateString()}`);
    }
  }
}

main().catch(console.error);
