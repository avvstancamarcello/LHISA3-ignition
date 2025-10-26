import { ethers } from "hardhat";

async function main() {
  console.log("🏛️ Issuing Trust Certificates (Fixed)...");
  console.log("📜 Propositum Stellarum Duplicium - Sigilla Fidei");

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
    console.log(`\n📜 Issuing certificate for ${cert.name}...`);
    try {
      // Aumenta il gas price per evitare "underpriced"
      const feeData = await ethers.provider.getFeeData();
      const increasedGasPrice = feeData.gasPrice ? feeData.gasPrice * 120n / 100n : undefined;
      
      const tx = await trustManager.issueCertificate(cert.module, cert.name, cert.duration, {
        gasPrice: increasedGasPrice
      });
      
      console.log(`⏳ Waiting for confirmation... (Tx: ${tx.hash})`);
      await tx.wait();
      console.log(`✅ Certificate issued for ${cert.name}`);
      
      // Aspetta 5 secondi tra le transazioni
      console.log("💤 Waiting 5 seconds before next transaction...");
      await new Promise(resolve => setTimeout(resolve, 5000));
      
      // Verifica
      const isValid = await trustManager.validateCertificate(cert.module);
      console.log(`🔍 Certificate valid: ${isValid}`);
      
    } catch (error: any) {
      console.log(`❌ Error issuing certificate: ${error.message}`);
      if (error.message.includes("underpriced")) {
        console.log("💡 Tip: Wait a moment and try again with higher gas price");
      }
    }
  }
  
  console.log("\n🎉 Trust certificates process completed!");
  console.log("🌌 Sigilla Fidei - Systema Certificatum Completum!");
}

main().catch(console.error);
