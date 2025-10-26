import { ethers } from "hardhat";

async function main() {
  console.log("🔍 Debugging Certificate Issue...");
  
  const trustManagerAddress = "0x625c95A763F900f3d60fdCEC01A4474B985bAb45";
  const TrustManager = await ethers.getContractFactory("SolidaryTrustManager");
  const trustManager = TrustManager.attach(trustManagerAddress);
  
  const hubAddress = "0xE9458CdA8e3dA88E1b1588EeCd6b1CFE2A398602";
  
  // Ottieni i dettagli del certificato
  const cert = await trustManager.certificates(hubAddress);
  console.log("📋 Certificate Details:");
  console.log("Name:", cert.name);
  console.log("Module:", cert.module);
  console.log("Issued At:", new Date(Number(cert.issuedAt) * 1000).toLocaleString());
  console.log("Valid Until:", new Date(Number(cert.validUntil) * 1000).toLocaleString());
  console.log("Revoked:", cert.revoked);
  
  // Verifica la validità
  const isValid = await trustManager.validateCertificate(hubAddress);
  console.log("\n🔍 Validation Result:", isValid);
  
  // Controlla il timestamp corrente
  const currentBlock = await ethers.provider.getBlock("latest");
  console.log("Current Block Timestamp:", new Date(Number(currentBlock.timestamp) * 1000).toLocaleString());
}

main().catch(console.error);
