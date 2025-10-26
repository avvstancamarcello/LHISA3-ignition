// scripts/verify-deployment.ts
import { ethers } from "hardhat";

async function main() {
  console.log("🔍 Verifying DoubleStar Ecosystem Deployment...");
  
  const contracts = {
    hub: "0xE9458CdA8e3dA88E1b1588EeCd6b1CFE2A398602",
    oraculum: "0xcc516a4374021d4a959A6887F2b1501F372f27F6",
    trustManager: "0x625c95A763F900f3d60fdCEC01A4474B985bAb45"
  };
  
  // Test SolidaryHub
  try {
    const Hub = await ethers.getContractFactory("SolidaryHub");
    const hub = Hub.attach(contracts.hub);
    const hubOwner = await hub.owner();
    console.log("✅ SolidaryHub - Owner:", hubOwner);
  } catch (error) {
    console.log("❌ SolidaryHub test failed");
  }
  
  // Test OraculumCaritatis
  try {
    const Oraculum = await ethers.getContractFactory("OraculumCaritatis");
    const oraculum = Oraculum.attach(contracts.oraculum);
    const oraculumOwner = await oraculum.owner();
    console.log("✅ OraculumCaritatis - Owner:", oraculumOwner);
  } catch (error) {
    console.log("❌ OraculumCaritatis test failed");
  }
  
  // Test SolidaryTrustManager
  try {
    const TrustManager = await ethers.getContractFactory("SolidaryTrustManager");
    const trustManager = TrustManager.attach(contracts.trustManager);
    const trustOwner = await trustManager.owner();
    console.log("✅ SolidaryTrustManager - Owner:", trustOwner);
    
    // Test certificate validation
    const isValid = await trustManager.validateCertificate(contracts.hub);
    console.log("🔍 Trust Manager - Hub Certificate:", isValid);
  } catch (error) {
    console.log("❌ SolidaryTrustManager test failed");
  }
  
  console.log("🎉 DoubleStar Ecosystem Verification Complete!");
  console.log("🌌 Propositum Stellarum Duplicium - Systema Completum!");
}

main().catch(console.error);
