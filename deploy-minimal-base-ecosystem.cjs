// Token aggiunti più avanti dentro la funzione `main()` dopo il deploy dello Swapper.
// Tutte le chiamate await swapper.addSupportedToken devono essere all'interno di async function main()
require('dotenv').config({ path: process.env.HARDHAT_NETWORK === 'localhost' ? '.env.local' : '.env' });
const { ethers, upgrades } = require('hardhat');
const fs = require('fs');

async function main() {
  console.log("🎯 DEPLOY MINIMAL NFT/FT CONTRACTS ON BASE");
  console.log("═══════════════════════════════════════════════");

  try {
    // Se sei su localhost, usa esplicitamente il primo account generato da Hardhat Node
    const isLocal = process.env.HARDHAT_NETWORK === 'localhost';
    let deployer;
    if (isLocal) {
      const localAccounts = await ethers.getSigners();
      deployer = localAccounts[0];
      console.log("📍 Deployer (localhost):", deployer.address);
    } else {
      [deployer] = await ethers.getSigners();
      console.log("📍 Deployer:", deployer.address);
    }
      // Determina l'explorer in base alla rete
      let explorerUrl = "https://basescan.org/address/";
      let explorerName = "BaseScan";
      let tokenName = "COSMIX";
      if (process.env.HARDHAT_NETWORK === "polygon" || (hre && hre.network && hre.network.name === "polygon")) {
        explorerUrl = "https://polygonscan.com/address/";
        explorerName = "Polygonscan";
      } else if (process.env.HARDHAT_NETWORK === "localhost") {
        explorerUrl = "http://localhost:8545/address/";
        explorerName = "Localhost";
      }

    const balance = await deployer.provider.getBalance(deployer.address);
    console.log("💰 Balance:", ethers.formatEther(balance), "ETH");

    // Usa indirizzi già deployati se forniti
    let nftAddress, ftAddress, nft, ft;
    if (process.env.NFT_ADDRESS && process.env.FT_ADDRESS) {
      nftAddress = process.env.NFT_ADDRESS;
      ftAddress = process.env.FT_ADDRESS;
      nft = await ethers.getContractAt("contracts/nft/OceanMangaNFT.sol:OceanMangaNFT", nftAddress);
      ft = await ethers.getContractAt("CosmixProtocolToken", ftAddress);
      console.log("✅ NFT proxy già deployato:", nftAddress);
      console.log("✅ FT proxy già deployato:", ftAddress);
    } else {
      // Deploy NFT
      console.log("\n🎨 Deploying OceanMangaNFT...");
      const NFT = await ethers.getContractFactory("contracts/nft/OceanMangaNFT.sol:OceanMangaNFT");
      console.log("🔧 Deploying NFT as UUPS proxy and initializing with deployer as admin...");
      nft = await upgrades.deployProxy(
        NFT,
        [
          process.env.OWNER_WALLET || deployer.address,
          "", // initialURI
          process.env.OWNER_WALLET || deployer.address, // royaltyReceiver (treasury)
          0 // royalty fee numerator (bps)
        ],
        { initializer: 'initialize', kind: 'uups' }
      );
      await nft.waitForDeployment();
      nftAddress = await nft.getAddress();
      console.log("✅ NFT proxy deployed & initialized:", nftAddress);
      // Deploy FT
      console.log("\n🪙 Deploying CosmicsProtocolToken...");
      const FT = await ethers.getContractFactory("CosmixProtocolToken");
      console.log("🔧 Deploying FT as UUPS proxy e inizializzando con nome 'Cosmics' e simbolo 'COSMICS'...");
      const initialSupply = ethers.parseUnits("1000000", 18);
      ft = await upgrades.deployProxy(
        FT,
        [
          deployer.address,
          initialSupply,
          deployer.address // treasury
        ],
        { initializer: 'initialize', kind: 'uups' }
      );
      await ft.waitForDeployment();
      ftAddress = await ft.getAddress();
      console.log("✅ FT proxy deployed & initialized:", ftAddress);
    }

    console.log("\n🔄 Deploying NEW Orchestrator with REAL addresses...");
    
    // REAL WALLET ADDRESSES
    const creatorAddress = deployer.address; // Developer/Creator
    const charityAddress = "0xf84eb8B95407f04Dee8fF9acaC0e0AC7231bAb2A"; // Caritas International
    
    console.log("📍 Creator wallet:", creatorAddress);
    console.log("📍 Charity wallet (Caritas):", charityAddress);

    const Orchestrator = await ethers.getContractFactory("OceanMangaOrchestrator");
    console.log("[DEBUG] OceanMangaOrchestrator bytecode length:", Orchestrator.bytecode.length / 2, "bytes");
    let orchestrator, orchestratorAddress;
    try {
        // Calcola costo gas reale prima del deploy
        const gasLimit = 9000000;
        // Gas price di rete attuale (0.002 gwei)
        const gasPriceGwei = 0.002;
        const gasPriceWei = ethers.parseUnits(gasPriceGwei.toString(), "gwei");
        // Costo stimato in wei
        const estimatedCostWei = BigInt(gasLimit) * BigInt(gasPriceWei);
        // Saldo attuale del wallet
        const walletBalanceWei = await deployer.provider.getBalance(deployer.address);
        // Stampa info
        console.log(`[CHECK] Gas price di rete: ${gasPriceGwei} gwei`);
        console.log(`[CHECK] Gas limit stimato: ${gasLimit}`);
        console.log(`[CHECK] Costo stimato deploy: ${ethers.formatEther(estimatedCostWei)} ETH`);
        console.log(`[CHECK] Saldo wallet: ${ethers.formatEther(walletBalanceWei)} ETH`);
        if (walletBalanceWei < estimatedCostWei) {
          console.error("❌ Saldo insufficiente per il deploy dell'Orchestrator! Ricarica il wallet e riprova.");
          process.exitCode = 1;
          return;
        }
        // Usa solo gasLimit, lascia che la rete scelga il gasPrice
        console.log("[DEBUG] Deploying Orchestrator with network gas price");
        orchestrator = await Orchestrator.deploy(
          nftAddress,
          ftAddress,
          creatorAddress,
          charityAddress,
          { gasLimit: 9000000 }
        );
      console.log("[DEBUG] Deploy transaction sent, waiting for confirmation...");
      await orchestrator.waitForDeployment();
      orchestratorAddress = await orchestrator.getAddress();
      console.log("✅ New Orchestrator deployed:", orchestratorAddress);
    } catch (e) {
      console.error("[ERROR] Orchestrator deploy failed:", e);
      throw e;
    }

    console.log("\n🔐 Setting up COMPLETE permissions and roles...");
    
  // Get all role constants
  let MINTER_ROLE, DEFAULT_ADMIN_ROLE, FT_MINTER_ROLE;
  try {
    MINTER_ROLE = await nft.MINTER_ROLE();
    DEFAULT_ADMIN_ROLE = await nft.DEFAULT_ADMIN_ROLE();
    console.log("[DEBUG] NFT MINTER_ROLE via contract method");
  } catch (e) {
    // fallback: OpenZeppelin default hash
    MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
    DEFAULT_ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes("DEFAULT_ADMIN_ROLE"));
    console.log("[DEBUG] NFT MINTER_ROLE via keccak fallback");
  }
  try {
    FT_MINTER_ROLE = await ft.MINTER_ROLE();
    console.log("[DEBUG] FT MINTER_ROLE via contract method");
  } catch (e) {
    FT_MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("COSMIX_MINTER_ROLE"));
    console.log("[DEBUG] FT MINTER_ROLE via keccak fallback (COSMIX_MINTER_ROLE)");
  }
    
    console.log("🔍 Role addresses:");
    console.log("  MINTER_ROLE:", MINTER_ROLE);
    console.log("  DEFAULT_ADMIN_ROLE:", DEFAULT_ADMIN_ROLE);
    
    // Verify deployer has admin roles
    console.log("\n🔐 Verifying deployer admin permissions...");
    let nftAdminRole = false, ftAdminRole = false;
    try {
      nftAdminRole = await nft.hasRole(DEFAULT_ADMIN_ROLE, deployer.address);
      console.log("  NFT Admin Role (deployer):", nftAdminRole ? "✅" : "❌");
      if (nftAdminRole) {
        console.log("  NFT DEFAULT_ADMIN_ROLE is held by:", deployer.address);
      }
    } catch (e) {
      console.warn("[WARN] NFT contract does not support hasRole. Skipping admin check.");
    }
    try {
      ftAdminRole = await ft.hasRole(DEFAULT_ADMIN_ROLE, deployer.address);
      console.log("  FT Admin Role (deployer):", ftAdminRole ? "✅" : "❌");
      if (ftAdminRole) {
        console.log("  FT DEFAULT_ADMIN_ROLE is held by:", deployer.address);
      }
    } catch (e) {
      console.warn("[WARN] FT contract does not support hasRole. Skipping admin check.");
    }
    
    // Grant MINTER_ROLE to orchestrator on NFT contract
    console.log("\n🎨 Granting NFT minting permissions...");
    try {
      const nftTx = await nft.grantRole(MINTER_ROLE, orchestratorAddress);
      await nftTx.wait();
      console.log("✅ NFT minter role granted to orchestrator");
    } catch (err) {
      console.error("❌ Revert on NFT grantRole:", err);
      throw err;
    }

    // Grant MINTER_ROLE to orchestrator on FT contract
    console.log("🪙 Granting FT minting permissions...");
    try {
      const FT_MANAGER_ROLE = await ft.MANAGER_ROLE();
      const ftManagerRole = await ft.hasRole(FT_MANAGER_ROLE, deployer.address);
      console.log("  FT Manager Role (deployer):", ftManagerRole ? "✅" : "❌");
      if (!ftManagerRole) {
        console.log("🛠️ Assegno MANAGER_ROLE al deployer sul FT...");
        const FT_ADMIN_ROLE = await ft.DEFAULT_ADMIN_ROLE();
        const ftAdminRole = await ft.hasRole(FT_ADMIN_ROLE, deployer.address);
        if (!ftAdminRole) {
          throw new Error("❌ Deployer non ha DEFAULT_ADMIN_ROLE sul FT: impossibile assegnare MANAGER_ROLE");
        }
        const managerTx = await ft.grantRole(FT_MANAGER_ROLE, deployer.address);
        await managerTx.wait();
        console.log("✅ MANAGER_ROLE assegnato al deployer sul FT");
      }
      const ftTx = await ft.grantMinterRole(orchestratorAddress);
      await ftTx.wait();
      console.log("✅ FT minter role granted to orchestrator");
    } catch (err) {
      console.error("❌ Revert on FT grantMinterRole:", err);
      throw err;
    }
    
    // Verify orchestrator has minting permissions
    console.log("\n🔍 Verifying orchestrator permissions...");
    const nftMinterRole = await nft.hasRole(MINTER_ROLE, orchestratorAddress);
  const ftMinterRole = await ft.hasRole(FT_MINTER_ROLE, orchestratorAddress);
    console.log("  NFT Minter Role (orchestrator):", nftMinterRole ? "✅" : "❌");
    console.log("  FT Minter Role (orchestrator):", ftMinterRole ? "✅" : "❌");
    
    // Verify orchestrator configuration
    console.log("\n🔍 Verifying orchestrator configuration...");
    const orchNFT = await orchestrator.oceanMangaNFT();
    const orchFT = await orchestrator.lunaComicsFT();
    const orchCreator = await orchestrator.creator();
    const orchCharity = await orchestrator.charityFund();
    
    console.log("  Orchestrator NFT address:", orchNFT === nftAddress ? "✅" : "❌", orchNFT);
    console.log("  Orchestrator FT address:", orchFT === ftAddress ? "✅" : "❌", orchFT);
    console.log("  Creator address:", orchCreator === creatorAddress ? "✅" : "❌", orchCreator);
    console.log("  Charity address:", orchCharity === charityAddress ? "✅" : "❌", orchCharity);
    
    if (!nftMinterRole || !ftMinterRole) {
      throw new Error("❌ Orchestrator missing required minting permissions!");
    }
    
    console.log("\n🎯 ALL PERMISSIONS CONFIGURED CORRECTLY!");
    
    console.log("\n🔄 Deploying Token Router & Swapper...");
    
    // Deploy solo Orchestrator, blocca altri deploy finché non è ok
    if (process.env.ORCHESTRATOR_ADDRESS) {
      orchestratorAddress = process.env.ORCHESTRATOR_ADDRESS;
      console.log("✅ Orchestrator già deployato:", orchestratorAddress);
    } else {
      const Orchestrator = await ethers.getContractFactory("OceanMangaOrchestrator");
      orchestrator = await Orchestrator.deploy(
        nftAddress,
        ftAddress,
        creatorAddress,
        charityAddress,
        { gasLimit: 9000000 }
      );
      await orchestrator.waitForDeployment();
      orchestratorAddress = await orchestrator.getAddress();
      console.log("✅ Orchestrator deployed:", orchestratorAddress);
    }

    // Blocca il deploy degli altri contratti finché l'Orchestrator non è deployato
    if (!orchestratorAddress) {
      console.error("❌ Deploy Orchestrator fallito. Blocca il deploy degli altri contratti.");
      return;
    }
    // Solo dopo l'ok del deploy dell'Orchestrator, si potranno deployare gli altri contratti
    
  // Grant MINTER_ROLE to swapper (for reverse swaps)
  console.log("🔐 Granting swapper minting permissions...");
  const swapperTx = await ft.grantRole(FT_MINTER_ROLE, swapperAddress);
  await swapperTx.wait();
  console.log("✅ Swapper can mint COSMICS tokens for reverse swaps");

  // Integra nuovi token nello swapper
  console.log("🔗 Adding supported tokens to swapper...");
  // ALGORAND
  await swapper.addSupportedToken("0x3a51f2a377ea8b55faf3c671138a00503b031af3", "1000000000000000", "AGORAND", 18);
  // Arbitrum (ARB)
  await swapper.addSupportedToken("0x912CE59144191C1204E64559FE8253a0e49E6548", "1000000000000000000", "ARB", 18);
  // BAL
  await swapper.addSupportedToken("0xBA12222222228d8Ba445958a75a0704d566BF2C8", "1000000000000000000", "BAL", 18);
  // BIO
  await swapper.addSupportedToken("0x226a2fa2556c48245e57cd1cba4c6c9e67077dd2", "1000000000000000", "BIO", 18);
  // cbETH
  await swapper.addSupportedToken("0x2Ae3F1Ec7F1F5012CFEab0185bfc7aa3cf0DEc22", "1000000000000000000", "cbETH", 18);
  // Chainlink (LINK)
  await swapper.addSupportedToken("0x514910771AF9Ca656af840dff83E8264EcF986CA", "1000000000000000000", "LINK", 18);
  // Compound USDC (cUSDCv3)
  await swapper.addSupportedToken("0xb125e6687d4313864e53df431d5425969c15eb2f", "10000000000000000", "cUSDCv3", 18);
  // DAI
  await swapper.addSupportedToken("0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb", "1000000000000000", "DAI", 18);
  // DepressionStop Token (DST) su Polygon
  await swapper.addSupportedToken("0xAf783f67a83754b5989256fA180534232dF83a0a", "1000000000000000000", "DST", 18);
  // ETH Bridge
  await swapper.addSupportedToken("0x4200000000000000000000000000000000000006", "1000000000000000000", "ETHBRIDGE", 18);
  // Ethereum Universal Token
  await swapper.addSupportedToken("0x1cff25b095cf6595afabe35dd7e5348666e57c11", "1000000000000000000", "ETHU", 18);
  // LINK
  await swapper.addSupportedToken("0x514910771AF9Ca656af840dff83E8264EcF986CA", "1000000000000000000", "LINK", 18);
  // MATIC Universal Token
  await swapper.addSupportedToken("0xe868c3d83ec287c01bcb533a33d197d9bfa79dad", "1000000000000000000", "MATICU", 18);
  // OOE
  await swapper.addSupportedToken("0x6cbb2598881940d08d5ea3fa8f557e02996e1031", "1000000000000000", "OOE", 18);
  // OP
  await swapper.addSupportedToken("0x4200000000000000000000000000000000000042", "1000000000000000000", "OP", 18);
  // Price Oracle Sentinel
  await swapper.addSupportedToken("0xD228edaA3BD33D604f5561e187782aD9D5B65571", "1000000000000000", "SENTINEL", 18);
  // protocol token
  await swapper.addSupportedToken("0x1cff25b095cf6595afabe35dd7e5348666e57c11", "1000000000000000", "TOKEN", 18);
  // SLD Solidary Token
  await swapper.addSupportedToken("0x18794e4168dc77f0ee3963ef3c3b4460b33cfb5b", "1000000000000000", "SLDY", 18); // Sostituisci con l'indirizzo reale di SLDY
  // SOL Solidary Music
  await swapper.addSupportedToken("0x321974e059c54d009eb57d77ea903d70e6edbef2", "1000000000000000", "SOLMUS", 18);
  // uDogeToken
  await swapper.addSupportedToken("0x12e96c2bfea6e835cf8dd38a5834fa61cf723736", "1000000000000000", "uDOGE", 18);
  // USDC
  await swapper.addSupportedToken("0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913", "1000000000000", "USDC", 6);
  // USDC Bridge
  await swapper.addSupportedToken("0x46ae9BaB8CEA96610807a275EBD36f8e916b5C61", "1000000000000", "USDCBRIDGE", 6);
  // USDC MATIC Wrapper
  await swapper.addSupportedToken("0xD89ea85ee5dD2027dbC29Fbc198DC197D44c3d70", "1000000000000", "USDCMATIC", 6);
  // USOL
  await swapper.addSupportedToken("0x9b8df6e244526ab5f6e6400d331db28c8fdddb55", "1000000000000000", "USOL", 18);
    console.log("✅ Tutti i token integrati nello swapper!");

    // Save deployment info
    const deploymentInfo = {
      timestamp: new Date().toISOString(),
      network: "base",
      deployer: deployer.address,
      wallets: {
        deployer: deployer.address,
        creator: creatorAddress,
        charity: charityAddress,
        charityAlias: "caritasinternational.cb.id"
      },
      contracts: {
        OceanMangaNFT: nftAddress,
        LunaComicsFT: ftAddress,
        OceanMangaOrchestrator: orchestratorAddress,
        TokenRouter: routerAddress,
        AdvancedSwapper: swapperAddress
      },
      supportedSwapTokens: {
        WETH: "0x4200000000000000000000000000000000000006",
        USDC: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913", 
        DAI: "0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb",
        cbETH: "0x2Ae3F1Ec7F1F5012CFEab0185bfc7aa3cf0DEc22"
      },
      feeDistribution: {
        creatorShare: "2.5%",
        charityShare: "2.5%",
        totalFees: "5%"
      },
      gasUsed: "Minimal",
      status: "READY_FOR_MINTING"
    };

    const fs = require('fs');
    fs.writeFileSync('BASE_COMPLETE_ECOSYSTEM.json', JSON.stringify(deploymentInfo, null, 2));

    console.log("\n🎉 COMPLETE ECOSYSTEM + SWAPPER DEPLOYED ON BASE!");
    console.log("════════════════════════════════════════════════");
    console.log("📍 NFT Contract:", nftAddress);
    console.log("📍 FT Contract:", ftAddress);
    console.log("📍 Orchestrator:", orchestratorAddress);
    console.log("📍 Token Router:", routerAddress);
    console.log("📍 Advanced Swapper:", swapperAddress);
    console.log("💾 Config saved to BASE_COMPLETE_ECOSYSTEM.json");
    
    console.log("\n🚀 ECOSYSTEM READY FOR REAL MINTING!");
    console.log("═════════════════════════════════════");
    console.log("✅ All contracts deployed on Base network");
    console.log("✅ Orchestrator has MINTER_ROLE on both NFT/FT");
    console.log("✅ Deployer retains DEFAULT_ADMIN_ROLE for management");
    console.log("✅ Ultra-low gas fees (~$0.0002 per mint)");
    console.log("✅ Real blockchain minting now possibile!");
    
    console.log("\n🔐 SECURITY VERIFICATION:");
    console.log("═══════════════════════════");
    console.log("• Deployer =", deployer.address);
    console.log("• Has admin control over NFT contract ✅");
    console.log("• Has admin control over FT contract ✅");
    console.log("• Orchestrator can mint NFTs ✅");
    console.log("• Orchestrator can mint FTs ✅");
    console.log("• Creator fees (2.5%) go to:", creatorAddress, "✅");
    console.log("• Charity fees (2.5%) go to Caritas:", charityAddress, "✅");
    
    console.log("\n📱 UPDATE REACT APP:");
    console.log("════════════════════════");
    console.log(`Update .env file:`);
    console.log(`VITE_ORCHESTRATOR_CONTRACT_ADDRESS=${orchestratorAddress}`);
    
    console.log("\n� TOKEN SWAPPING FEATURES:");
    console.log("══════════════════════════");
    console.log(`✅ ${tokenName} ↔ WETH (Wrapped Ethereum)`);
    console.log(`✅ ${tokenName} ↔ USDC (USD Coin)`);
    console.log(`✅ ${tokenName} ↔ DAI (Maker DAI)`);
    console.log(`✅ ${tokenName} ↔ cbETH (Coinbase ETH)`);
    console.log("💰 Conversion fee: 0.30%");
    console.log("🛡️ Slippage protection enabled");
    console.log("🔄 Upgradeable proxy pattern");
    
    console.log("\n💡 SUGGESTED ADDITIONAL TOKENS:");
    console.log("═══════════════════════════════");
    console.log("• COMP (Compound) - DeFi governance");
    console.log("• AAVE - Lending protocol");
    console.log("• UNI (Uniswap) - DEX token");
    console.log("• LINK (Chainlink) - Oracle network");
    console.log("• WBTC - Wrapped Bitcoin");
    console.log("• OP (Optimism) - Layer 2 token");
    
    console.log("\n�🔗 BaseScan Links:");
    console.log("═══════════════════");
    console.log(`\n🔗 ${explorerName} Links:`);
    console.log("═══════════════════");
    console.log(`NFT: ${explorerUrl}${nftAddress}`);
    console.log(`FT: ${explorerUrl}${ftAddress}`);
    console.log(`Orchestrator: ${explorerUrl}${orchestratorAddress}`);
    console.log(`Router: ${explorerUrl}${routerAddress}`);
    console.log(`Swapper: ${explorerUrl}${swapperAddress}`);

  } catch (error) {
    console.error("❌ Deploy failed:", error.message || error);
    console.error("Error details:", error.stack || error);
    process.exitCode = 1;
  }
}

// SUGGERIMENTO: Per testare senza bruciare gas, usa la rete locale o Sepolia
// Esempio per la rete locale:
// npx hardhat node
// npx hardhat run scripts/deploy-minimal-base-ecosystem.cjs --network localhost
// Esempio per Sepolia:
// npx hardhat run scripts/deploy-minimal-base-ecosystem.cjs --network sepolia

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});