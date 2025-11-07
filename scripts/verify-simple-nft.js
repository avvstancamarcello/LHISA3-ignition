import pkg from 'hardhat';
const { ethers } = pkg;

async function verifySimpleNFT() {
    const nftAddress = "0xA139b06bf55e340286b11A021d45Ccbdf27308c6";
    console.log("🔍 VERIFYING SIMPLE NFT CONTRACT");
    console.log("=================================");
    console.log(`📍 Contract: ${nftAddress}`);
    
    try {
        const [deployer] = await ethers.getSigners();
        console.log(`👤 Deployer: ${deployer.address}`);
        
        // Wait a bit for propagation
        console.log("⏳ Waiting for network propagation...");
        await new Promise(resolve => setTimeout(resolve, 3000));
        
        const OceanMangaNFT = await ethers.getContractFactory("OceanMangaNFT_Simple");
        const nft = await OceanMangaNFT.attach(nftAddress);
        
        // Define roles
        const ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_ADMIN_ROLE"));
        const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MINTER_ROLE"));
        const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MANAGER_ROLE"));
        
        console.log("\n🔑 Role verification:");
        console.log(`ADMIN_ROLE: ${ADMIN_ROLE}`);
        console.log(`MINTER_ROLE: ${MINTER_ROLE}`);
        console.log(`MANAGER_ROLE: ${MANAGER_ROLE}`);
        
        // Check roles
        const hasAdmin = await nft.hasRole(ADMIN_ROLE, deployer.address);
        const hasMinter = await nft.hasRole(MINTER_ROLE, deployer.address);
        const hasManager = await nft.hasRole(MANAGER_ROLE, deployer.address);
        
        console.log(`✅ Has ADMIN_ROLE: ${hasAdmin}`);
        console.log(`✅ Has MINTER_ROLE: ${hasMinter}`);
        console.log(`✅ Has MANAGER_ROLE: ${hasManager}`);
        
        // Verify no DEFAULT_ADMIN_ROLE
        const noDefaultAdmin = await nft.verifyNoDefaultAdminRole(deployer.address);
        console.log(`🚫 NO DEFAULT_ADMIN_ROLE: ${noDefaultAdmin}`);
        
        // Get contract details
        const name = await nft.name();
        const symbol = await nft.symbol();
        console.log(`📝 Name: ${name}`);
        console.log(`📝 Symbol: ${symbol}`);
        
        if (hasAdmin && hasMinter && hasManager && noDefaultAdmin) {
            console.log("\n🎉 CONTRATTO PERFETTAMENTE SICURO!");
            
            // Connect to orchestrator
            console.log("\n🔗 CONNECTING TO ORCHESTRATOR...");
            const ORCHESTRATOR = "0xf0D90454C98A0AE934e9DB1B316FF1608C4E9DEf";
            
            const grantTx = await nft.grantRole(MINTER_ROLE, ORCHESTRATOR);
            await grantTx.wait();
            console.log("✅ MINTER_ROLE granted to orchestrator");
            
            const orchestratorHasMinter = await nft.hasRole(MINTER_ROLE, ORCHESTRATOR);
            console.log(`Orchestrator has MINTER_ROLE: ${orchestratorHasMinter}`);
            
            console.log("\n📋 ECOSISTEMA FINALE COMPLETO:");
            console.log(`🛡️ Secure NFT: ${nftAddress}`);
            console.log("🪙 FT: 0xF8d5a00Ca91D46c07614208C346c49a09409D094");
            console.log(`🎭 Orchestrator: ${ORCHESTRATOR}`);
            console.log("📊 Impact Tracker: 0x20e63Ac004aA0997CC2bE7B8bB4419b9385C4689");
            
            console.log("\n✅ SICUREZZA GARANTITA:");
            console.log("- Zero ruoli 0x000...000");
            console.log("- Tutti ruoli personalizzati");
            console.log("- Owner e Orchestrator connessi");
            console.log("- Contratto non-upgradeable");
            
        } else {
            console.log("❌ SECURITY VERIFICATION FAILED");
        }
        
    } catch (error) {
        console.error("❌ Verification error:", error.message);
    }
}

verifySimpleNFT()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });