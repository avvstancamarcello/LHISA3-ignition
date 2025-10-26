// scripts/issue-certificates.ts
import { ethers } from "hardhat";

async function main() {
  console.log("🏛️ Issuing Trust Certificates...");
  
  const trustManagerAddress = "0x625c95A763F900f3d60fdCEC01A4474B985bAb45";
  const TrustManager = await ethers.getContractFactory("SolidaryTrustManager");
  const trustManager = TrustManager.attach(trustManagerAddress);
  
  // Emetti certificati per gli altri contratti
  const certificates = [
    {
      module: "0xE9458CdA8e3dA88E1b1588EeCd6b1CFE2A398602", // SolidaryHub
      name: "SolidaryHub_Core_Infrastructure",
      duration: 86400 * 365 // 1 anno
    },
    {
      module: "0xcc516a4374021d4a959A6887F2b1501F372f27F6", // OraculumCaritatis  
      name: "OraculumCaritatis_Justice_System",
      duration: 86400 * 365 // 1 anno
    }
  ];
  
  for (const cert of certificates) {
    console.log(`📜 Issuing certificate for ${cert.name}...`);
    const tx = await trustManager.issueCertificate(cert.module, cert.name, cert.duration);
    await tx.wait();
    console.log(`✅ Certificate issued for ${cert.name}`);
    
    // Verifica
    const isValid = await trustManager.validateCertificate(cert.module);
    console.log(`🔍 Certificate valid: ${isValid}`);
  }
  
  console.log("🎉 All trust certificates issued!");
}

main().catch(console.error);
