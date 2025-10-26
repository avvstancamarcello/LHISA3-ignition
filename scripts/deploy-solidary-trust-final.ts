import { ethers, upgrades } from "hardhat";

async function main() {
  console.log("🏛️ Deploying SolidaryTrustManager (UUPS Upgradeable)...");
  console.log("⚖️ Custos Fidei - The Guardian of Trust");
  console.log("🌌 Propositum Stellarum Duplicium - Systema Gubernationis");
  
  const admin = "0x514efc732cc787fb19c90d01edaf5a79d7e2385d";
  
  // Get contract factory
  const SolidaryTrustManager = await ethers.getContractFactory("SolidaryTrustManager");
  
  console.log("🔄 Deploying UUPS proxy contract...");
  const trustManager = await upgrades.deployProxy(
    SolidaryTrustManager,
    [admin], // initialOwner
    {
      kind: 'uups',
      initializer: 'initialize'
    }
  );
  
  await trustManager.waitForDeployment();
  const proxyAddress = await trustManager.getAddress();
  
  console.log("✅ SolidaryTrustManager Proxy deployed to:", proxyAddress);
  console.log("📋 Implementation address:", await upgrades.erc1967.getImplementationAddress(proxyAddress));
  console.log("👑 Admin/Owner:", admin);
  
  // Test basic functionality
  console.log("🧪 Testing basic functions...");
  const isValid = await trustManager.validateCertificate(admin);
  console.log("🔍 Default certificate validation:", isValid);
  
  console.log("🎉 SolidaryTrustManager deployed successfully!");
  console.log("🌠 Custos Fidei - Systema Gubernationis Completum!");
  
  return proxyAddress;
}

main().catch(console.error);
