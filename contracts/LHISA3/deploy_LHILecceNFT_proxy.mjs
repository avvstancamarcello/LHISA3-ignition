// scripts/deploy_LHILecceNFT_proxy.mjs
import hre from "hardhat";
import { JsonRpcProvider, Wallet } from "ethers";
import * as dotenv from "dotenv";
dotenv.config();

const provider = new JsonRpcProvider(process.env.POLYGON_RPC_URL);
const signer = new Wallet(process.env.PRIVATE_KEY, provider);

// 📦 Parametri di inizializzazione
const baseURI = "ipfs://bafybeiep63gjj7coo5hvhq7dvhmjp6k2mjqnm2a7zqhanvj4spokredtvy/";
const initialManager = "0x514EFc732Cc787fb19C90d01eDaf5a79d7E2385D"; // Wallet deployer

async function main() {
  console.log("🚀 Deploy del contratto LHILecceNFT come Transparent Proxy...");

  const LHILecceNFT = await hre.ethers.getContractFactory("LHILecceNFT", signer);

  const proxy = await hre.upgrades.deployProxy(LHILecceNFT, [baseURI, initialManager], {
    kind: "transparent"
  });

  await proxy.waitForDeployment();
  const proxyAddress = await proxy.getAddress();

  console.log("✅ Proxy deployato a:", proxyAddress);
}

main().catch(console.error);
