cd scripts

cat > issue-certificates-simple.ts << 'EOF'
import { ethers } from "hardhat";

async function main() {
  console.log("🏛️ Issuing Trust Certificates (Simple)...");
  
  const trustManagerAddress = "0x625c95A763F900f3d60fdCEC01A4474B985bAb45";
  const TrustManager = await ethers.getContractFactory("SolidaryTrustManager");
  const trustManager = TrustManager.attach(trustManagerAddress);

  // Solo OraculumCaritatis (SolidaryHub già tentato)
  const certificate = {
    module: "0xcc516a4374021d4a959A6887F2b1501F372f27F6",
    name: "OraculumCaritatis_Justice_System",
    duration: 86400 * 365 // 1 anno
  };

  console.log(`📜 Issuing certificate for ${certificate.name}...`);
  
  try {
    const tx = await trustManager.issueCertificate(
      certificate.module, 
      certificate.name, 
      certificate.duration
    );
    
    console.log(`⏳ Waiting... (Tx: ${tx.hash})`);
    await tx.wait();
    console.log(`✅ Certificate issued for ${certificate.name}`);
    
    const isValid = await trustManager.validateCertificate(certificate.module);
    console.log(`🔍 Certificate valid: ${isValid}`);
    
  } catch (error: any) {
    console.log(`❌ Error: ${error.message}`);
  }
  
  console.log("🎉 Process completed!");
}

main().catch(console.error);
EOF

cd ..
