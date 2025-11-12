"use strict";
require('dotenv').config({ path: process.env.HARDHAT_NETWORK === 'localhost' ? '.env.local' : '.env' });
const { ethers, upgrades } = require('hardhat');
const fs = require('fs');

/**
 * Helper per assegnare ruoli sfruttando EIP-1559 e retry.
 */
async function grantIfMissing(contract, role, account, label) {
  const already = await contract.hasRole(role, account);
  if (already) {
    console.log(`ℹ️ ${label}: ruolo già presente su ${account}`);
    return true;
  }
  let gasLimit;
  try {
    gasLimit = await contract.estimateGas.grantRole(role, account);
  } catch {
    gasLimit = 200000n;
  }
  const fee = await ethers.provider.getFeeData();
  let maxFeePerGas = fee.maxFeePerGas || ethers.parseUnits(process.env.FALLBACK_MAXFEEPERGAS_GWEI || "0.05", "gwei");
  let maxPriorityFeePerGas = fee.maxPriorityFeePerGas || ethers.parseUnits(process.env.FALLBACK_MAXPRIORITYFEEPERGAS_GWEI || "0.02", "gwei");
  const tx = await contract.grantRole(role, account, { gasLimit, maxFeePerGas, maxPriorityFeePerGas });
  const rcpt = await tx.wait();
  const ok = await contract.hasRole(role, account);
  if (ok) {
    console.log(`✅ ${label}: ruolo assegnato (tx: ${tx.hash}, status: ${rcpt.status})`);
    return true;
  }
  // Retry con fee maggiorate
  const fee2 = await ethers.provider.getFeeData();
  maxFeePerGas = (fee2.maxFeePerGas || maxFeePerGas) + ethers.parseUnits("0.02", "gwei");
  maxPriorityFeePerGas = (fee2.maxPriorityFeePerGas || maxPriorityFeePerGas) + ethers.parseUnits("0.01", "gwei");
  const tx2 = await contract.grantRole(role, account, { gasLimit, maxFeePerGas, maxPriorityFeePerGas });
  const rcpt2 = await tx2.wait();
  const ok2 = await contract.hasRole(role, account);
  if (!ok2) throw new Error(`${label}: ruolo non assegnato dopo retry (tx: ${tx2.hash})`);
  console.log(`✅ ${label}: ruolo assegnato al retry (tx: ${tx2.hash}, status: ${rcpt2.status})`);
  return true;
}

/**
 * Helper per verificare se ci sono fondi sufficienti per il deploy.
 */
async function canAffordDeploy(factory, args, label, deployer) {
  try {
    const gasEstimate = await factory.estimateGas.deploy(...args);
    const fee = await ethers.provider.getFeeData();
    const price = fee.maxFeePerGas || fee.gasPrice || ethers.parseUnits("1", "gwei");
    const cost = gasEstimate * price;
    const bal = await deployer.provider.getBalance(deployer.address);
    const margin = cost + (cost / 10n); // +10%
    if (bal < margin) {
      console.warn(`⚠️ Fondi insufficienti per deploy ${label}. Necessari ~${ethers.formatEther(margin)} ETH, saldo ${ethers.formatEther(bal)} ETH.`);
      return { ok: false, needed: margin, balance: bal };
    }
    return { ok: true };
  } catch (e) {
    console.warn(`[WARN] Impossibile stimare gas per ${label}:`, e.message);
    return { ok: true };
  }
}

async function main() {
  console.log("🎯 DEPLOY MINIMAL NFT/FT CONTRACTS ON BASE (ENV SAFE & TOKEN CONFIGURABLE)");
  console.log("═══════════════════════════════════════════════");

  // 1. Deployer
  const isLocal = process.env.HARDHAT_NETWORK === 'localhost';
  let deployer;
  if (isLocal) {
    const localAccounts = await ethers.getSigners();
    deployer = localAccounts[0];
  } else {
    [deployer] = await ethers.getSigners();
  }
  console.log("📍 Deployer address:", deployer.address);

  // 2. Lettura config di rete dall'env
  let explorerUrl = process.env.EXPLORER_URL || "https://basescan.org/address/";
  let explorerName = process.env.EXPLORER_NAME || "BaseScan";
  let tokenName = process.env.TOKEN_NAME || "COSMIX";

  const balance = await deployer.provider.getBalance(deployer.address);
  console.log("💰 Balance:", ethers.formatEther(balance), "ETH");

  // 3. Parametri critici da .env
  const creatorAddress = process.env.CREATOR_ADDRESS || deployer.address;
  const charityAddress = process.env.CHARITY_ADDRESS;
  const charityAlias = process.env.CHARITY_ALIAS || "caritasinternational.cb.id";
  if (!charityAddress) throw new Error('CHARITY_ADDRESS non è definito nel file .env');

  // 4. Orchestrator: riusa se esiste, altrimenti nuovo deploy dopo NFT/FT
  const Orchestrator = await ethers.getContractFactory("OceanMangaOrchestrator");
  let orchestrator, orchestratorAddress;
  let routerAddress, swapperAddress;
  let swapper;

  if (process.env.ORCHESTRATOR_ADDRESS) {
    orchestratorAddress = process.env.ORCHESTRATOR_ADDRESS;
    orchestrator = await Orchestrator.attach(orchestratorAddress);
    console.log("✅ Orchestrator già deployato (ENV):", orchestratorAddress);
  } else if (fs.existsSync('last-orchestrator.json')) {
    try {
      const prev = JSON.parse(fs.readFileSync('last-orchestrator.json'));
      if (prev && prev.orchestrator) {
        orchestratorAddress = prev.orchestrator;
        orchestrator = await Orchestrator.attach(orchestratorAddress);
        console.log("♻️ Orchestrator recuperato da last-orchestrator.json:", orchestratorAddress);
      }
    } catch (e) {
      console.warn("[WARN] Impossibile leggere last-orchestrator.json. Procedo senza orchestrator.");
    }
  }

  // 5. NFT/FT: recupera o deploya nuovi (parametrizza indirizzi da ENV se presenti)
  let nftAddress, ftAddress, nft, ft;
  if (orchestratorAddress) {
    try {
      const orchNFT = await orchestrator.oceanMangaNFT();
      const orchFT = await orchestrator.lunaComicsFT();
      if (orchNFT && orchNFT !== ethers.ZeroAddress && orchFT && orchFT !== ethers.ZeroAddress) {
        nftAddress = orchNFT;
        ftAddress = orchFT;
        nft = await ethers.getContractAt("contracts/nft/OceanMangaNFT.sol:OceanMangaNFT", nftAddress);
        ft = await ethers.getContractAt("CosmixProtocolToken", ftAddress);
        console.log("✅ NFT/FT re-used from orchestrator ENV:", nftAddress, ftAddress);
      }
    } catch {}
  }
  if (!nftAddress || !ftAddress) {
    if (process.env.NFT_ADDRESS && process.env.FT_ADDRESS) {
      nftAddress = process.env.NFT_ADDRESS;
      ftAddress = process.env.FT_ADDRESS;
      nft = await ethers.getContractAt("contracts/nft/OceanMangaNFT.sol:OceanMangaNFT", nftAddress);
      ft = await ethers.getContractAt("CosmixProtocolToken", ftAddress);
      console.log("✅ NFT e FT proxy da ENV:", nftAddress, ftAddress);
    } else {
      // Deploy NFT
      const NFT = await ethers.getContractFactory("contracts/nft/OceanMangaNFT.sol:OceanMangaNFT");
      nft = await upgrades.deployProxy(NFT, [
        creatorAddress,    // admin
        "",                // initialURI
        creatorAddress,    // royaltyReceiver
        0                  // royalty fee numerator (bps)
      ], {
        initializer: 'initialize', kind: 'uups'
      });
      await nft.waitForDeployment();
      nftAddress = await nft.getAddress();
      console.log("✅ NFT proxy deployed & initialized:", nftAddress);

      // Deploy FT
      const FT = await ethers.getContractFactory("CosmixProtocolToken");
      const initialSupply = ethers.parseUnits(process.env.INITIAL_SUPPLY || "1000000", 18);
      ft = await upgrades.deployProxy(FT, [
        creatorAddress,
        initialSupply,
        creatorAddress // treasury
      ], {
        initializer: 'initialize', kind: 'uups'
      });
      await ft.waitForDeployment();
      ftAddress = await ft.getAddress();
      console.log("✅ FT proxy deployed & initialized:", ftAddress);
    }
  }

  // 6. Deploy orchestrator se necessario
  if (!orchestratorAddress) {
    const feeData = await ethers.provider.getFeeData();
    const maxFeePerGas = feeData.maxFeePerGas || ethers.parseUnits(process.env.FALLBACK_MAXFEEPERGAS_GWEI || "0.1", "gwei");
    const maxPriorityFeePerGas = feeData.maxPriorityFeePerGas || ethers.parseUnits(process.env.FALLBACK_MAXPRIORITYFEEPERGAS_GWEI || "0.01", "gwei");
    orchestrator = await Orchestrator.deploy(
      nftAddress,
      ftAddress,
      creatorAddress,
      charityAddress,
      { maxFeePerGas, maxPriorityFeePerGas }
    );
    await orchestrator.waitForDeployment();
    orchestratorAddress = await orchestrator.getAddress();
    fs.writeFileSync('last-orchestrator.json', JSON.stringify({ orchestrator: orchestratorAddress }, null, 2));
    console.log("✅ Nuovo Orchestrator deployato:", orchestratorAddress);
  }

  // 7. Ruoli
  let MINTER_ROLE, DEFAULT_ADMIN_ROLE, FT_MINTER_ROLE;
  try {
    MINTER_ROLE = await nft.MINTER_ROLE();
    DEFAULT_ADMIN_ROLE = await nft.DEFAULT_ADMIN_ROLE();
    FT_MINTER_ROLE = await ft.MINTER_ROLE();
  } catch (e) {
    MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
    DEFAULT_ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes("DEFAULT_ADMIN_ROLE"));
    FT_MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
  }
  await grantIfMissing(nft, MINTER_ROLE, orchestratorAddress, "NFT MINTER_ROLE → orchestrator");
  await grantIfMissing(ft, FT_MINTER_ROLE, orchestratorAddress, "FT MINTER_ROLE → orchestrator");

  // 8. Deploy TokenRouter e Swapper
  const TokenRouter = await ethers.getContractFactory("TokenRouter");
  const affordRouter = await canAffordDeploy(TokenRouter, [orchestratorAddress, ftAddress], "TokenRouter", deployer);
  if (affordRouter.ok) {
    const fee = await ethers.provider.getFeeData();
    const router = await TokenRouter.deploy(orchestratorAddress, ftAddress, {
      maxFeePerGas: fee.maxFeePerGas || undefined,
      maxPriorityFeePerGas: fee.maxPriorityFeePerGas || undefined,
    });
    await router.waitForDeployment();
    routerAddress = await router.getAddress();
    console.log("✅ TokenRouter deployed:", routerAddress);
  }

  const Swapper = await ethers.getContractFactory("AdvancedSwapper");
  const affordSwapper = await canAffordDeploy(Swapper, [orchestratorAddress, ftAddress], "AdvancedSwapper", deployer);
  if (affordSwapper.ok) {
    const feeS = await ethers.provider.getFeeData();
    swapper = await Swapper.deploy(orchestratorAddress, ftAddress, {
      maxFeePerGas: feeS.maxFeePerGas || undefined,
      maxPriorityFeePerGas: feeS.maxPriorityFeePerGas || undefined,
    });
    await swapper.waitForDeployment();
    swapperAddress = await swapper.getAddress();
    console.log("✅ AdvancedSwapper deployed:", swapperAddress);
  }

  // 9. Grant MINTER_ROLE a swapper se presente
  if (swapperAddress) {
    await grantIfMissing(ft, FT_MINTER_ROLE, swapperAddress, "FT MINTER_ROLE → swapper");
  }

  // 10. Carica i token dal file JSON e aggiungi al Swapper
  if (swapper) {
    console.log("🔗 Importazione token dal file JSON...");
    const supportedTokensPath = process.env.SUPPORTED_TOKENS_FILE || './scripts/supported_tokens.json';
    if (!fs.existsSync(supportedTokensPath)) throw new Error(`File non trovato: ${supportedTokensPath}`);
    const supportedTokens = JSON.parse(fs.readFileSync(supportedTokensPath));
    for (const token of supportedTokens) {
      await swapper.addSupportedToken(token.address, token.amount, token.symbol, token.decimals);
      console.log(`✅ Token integrato: ${token.symbol} (${token.address})`);
    }
    console.log("✅ Tutti i token importati dal file JSON.");
  }

  // 11. Salva info deploy su file (ricorda: i file non vanno committati)
  const deploymentInfo = {
    timestamp: new Date().toISOString(),
    network: process.env.HARDHAT_NETWORK || "base",
    deployer: deployer.address,
    wallets: {
      deployer: deployer.address,
      creator: creatorAddress,
      charity: charityAddress,
      charityAlias: charityAlias
    },
    contracts: {
      OceanMangaNFT: nftAddress,
      LunaComicsFT: ftAddress,
      OceanMangaOrchestrator: orchestratorAddress,
      TokenRouter: routerAddress,
      Swapper: swapperAddress
    },
    supportedTokensFile: supportedTokensPath,
    feeDistribution: {
      creatorShare: process.env.CREATOR_FEE_SHARE || "2.5%",
      charityShare: process.env.CHARITY_FEE_SHARE || "2.5%",
      totalFees: process.env.TOTAL_FEE_SHARE || "5%"
    },
    status: "READY_FOR_MINTING"
  };

  fs.writeFileSync('BASE_COMPLETE_ECOSYSTEM.json', JSON.stringify(deploymentInfo, null, 2));
  fs.writeFileSync('last-orchestrator.json', JSON.stringify({ orchestrator: orchestratorAddress }, null, 2));
  console.log("\n💾 Configurazione deploy salvata su BASE_COMPLETE_ECOSYSTEM.json");

  // Output finale
  console.log("\n🎉 ECOSISTEMA COMPLETO DEPLOYATO!");
  console.log("════════════════════════════════════════════════");
  console.log("📍 NFT Contract:", nftAddress);
  console.log("📍 FT Contract:", ftAddress);
  console.log("📍 Orchestrator:", orchestratorAddress);
  console.log("📍 Token Router:", routerAddress);
  console.log("📍 Advanced Swapper:", swapperAddress);
  console.log("\n📑 Token configurati (.json):", supportedTokensPath);
  console.log("💾 Config saved to BASE_COMPLETE_ECOSYSTEM.json");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
