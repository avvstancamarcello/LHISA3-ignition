const { upgrades } = require("hardhat");

async function main() {
  console.log("🔄 DEPLOYING LUNACOMICS ADVANCED SWAPPER");
  console.log("═══════════════════════════════════════════");

  try {
    const [deployer] = await ethers.getSigners();
    console.log("📍 Deployer:", deployer.address);
    
    const balance = await deployer.provider.getBalance(deployer.address);
    console.log("💰 Balance:", ethers.formatEther(balance), "ETH");

    // Contract addresses (use deployed ones or deploy new)
    const lunaTokenAddress = process.env.LUNA_TOKEN_ADDRESS || "0x0000000000000000000000000000000000000000";
    const routerAddress = process.env.ROUTER_ADDRESS || "0x0000000000000000000000000000000000000000";
    const feeCollector = deployer.address; // Use deployer as fee collector

    // Deploy router if needed
    let actualRouterAddress = routerAddress;
    if (routerAddress === "0x0000000000000000000000000000000000000000") {
      console.log("\n🛣️ Deploying SolidarySystemTokenRouter...");
      const Router = await ethers.getContractFactory("SolidarySystemTokenRouter");
      const router = await Router.deploy();
      await router.waitForDeployment();
      actualRouterAddress = await router.getAddress();
      console.log("✅ Router deployed:", actualRouterAddress);
    }

    console.log("\n🔄 Deploying LunaComicsAdvancedSwapper (Upgradeable)...");
    
    const LunaSwapper = await ethers.getContractFactory("LunaComicsAdvancedSwapper");
    
    const swapper = await upgrades.deployProxy(
      LunaSwapper,
      [
        lunaTokenAddress === "0x0000000000000000000000000000000000000000" ? deployer.address : lunaTokenAddress,
        actualRouterAddress,
        feeCollector
      ],
      { 
        initializer: 'initialize',
        kind: 'uups' 
      }
    );
    
    await swapper.waitForDeployment();
    const swapperAddress = await swapper.getAddress();
    
    console.log("✅ LunaComicsAdvancedSwapper deployed:", swapperAddress);

    // Verify initialization
    console.log("\n🔍 Verifying deployment...");
    
    try {
      const supportedTokens = await swapper.getSupportedTokens();
      console.log("📋 Supported tokens count:", supportedTokens.length);
      
      for (let i = 0; i < supportedTokens.length; i++) {
        const tokenInfo = await swapper.getTokenInfo(supportedTokens[i]);
        console.log(`  ${i + 1}. ${tokenInfo.symbol} (${supportedTokens[i]})`);
      }
      
      const conversionFee = await swapper.conversionFeeBps();
      console.log("💰 Conversion fee:", (conversionFee / 100).toString(), "%");
      
    } catch (error) {
      console.log("⚠️ Verification partially failed:", error.message);
    }

    // Test quote (if LUNA token is real)
    if (lunaTokenAddress !== "0x0000000000000000000000000000000000000000") {
      console.log("\n🧪 Testing conversion quotes...");
      try {
        const supportedTokens = await swapper.getSupportedTokens();
        if (supportedTokens.length > 0) {
          const testAmount = ethers.parseEther("100"); // 100 LUNA
          const quote = await swapper.getQuoteLunaToToken(supportedTokens[0], testAmount);
          const tokenInfo = await swapper.getTokenInfo(supportedTokens[0]);
          console.log(`💱 100 LUNA → ${ethers.formatUnits(quote.amountOut, tokenInfo.decimals)} ${tokenInfo.symbol}`);
          console.log(`💸 Fee: ${ethers.formatUnits(quote.fee, tokenInfo.decimals)} ${tokenInfo.symbol}`);
        }
      } catch (error) {
        console.log("⚠️ Quote test failed:", error.message);
      }
    }

    // Save deployment info
    const deploymentInfo = {
      timestamp: new Date().toISOString(),
      network: "base",
      deployer: deployer.address,
      contracts: {
        LunaComicsAdvancedSwapper: swapperAddress,
        SolidarySystemTokenRouter: actualRouterAddress,
        LunaToken: lunaTokenAddress
      },
      supportedTokens: {
        WETH: "0x4200000000000000000000000000000000000006",
        USDC: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913", 
        DAI: "0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb",
        cbETH: "0x2Ae3F1Ec7F1F5012CFEab0185bfc7aa3cf0DEc22"
      },
      features: [
        "Multi-token swapping",
        "Slippage protection", 
        "Dynamic conversion rates",
        "Fee collection system",
        "Upgradeable proxy pattern",
        "Emergency pause functionality"
      ],
      gasUsed: "Upgradeable",
      status: "READY_FOR_SWAPPING"
    };

    const fs = require('fs');
    fs.writeFileSync('LUNACOMICS_SWAPPER_DEPLOYED.json', JSON.stringify(deploymentInfo, null, 2));

    console.log("\n🎉 LUNACOMICS ADVANCED SWAPPER DEPLOYED!");
    console.log("════════════════════════════════════════════");
    console.log("📍 Swapper Address:", swapperAddress);
    console.log("📍 Router Address:", actualRouterAddress);
    console.log("💾 Config saved to LUNACOMICS_SWAPPER_DEPLOYED.json");
    
    console.log("\n🚀 SWAPPER FEATURES:");
    console.log("═══════════════════");
    console.log("✅ Swap LUNA ↔ WETH, USDC, DAI, cbETH");
    console.log("✅ Dynamic conversion rates");
    console.log("✅ Slippage protection");
    console.log("✅ 0.30% conversion fee");
    console.log("✅ Upgradeable proxy pattern");
    console.log("✅ Emergency pause/unpause");
    console.log("✅ Liquidity management");
    
    console.log("\n💡 SUGGESTED ADDITIONAL TOKENS:");
    console.log("═══════════════════════════════");
    console.log("• COMP (Compound) - DeFi governance token");
    console.log("• AAVE - Lending protocol token");
    console.log("• UNI (Uniswap) - DEX governance token");
    console.log("• LINK (Chainlink) - Oracle network token");
    console.log("• WBTC - Wrapped Bitcoin");
    console.log("• MATIC - Polygon token (for cross-chain)");
    console.log("• OP (Optimism) - L2 governance token");
    
    console.log("\n🔗 BaseScan Links:");
    console.log("═══════════════════");
    console.log(`Swapper: https://basescan.org/address/${swapperAddress}`);
    console.log(`Router: https://basescan.org/address/${actualRouterAddress}`);

    console.log("\n📱 INTEGRATION READY:");
    console.log("════════════════════");
    console.log("The swapper is ready to be integrated with:");
    console.log("• React frontend for token swapping");
    console.log("• OceanManga orchestrator for automatic conversions");
    console.log("• DeFi protocols for yield farming");
    console.log("• Cross-chain bridges for multi-network support");

  } catch (error) {
    console.error("❌ Deploy failed:", error.message);
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});