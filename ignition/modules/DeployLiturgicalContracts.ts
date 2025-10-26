import { ethers, upgrades } from "hardhat";

async function main() {
  console.log("⛪ Inizio deploy liturgico...");

  const [deployer, liturgicalAdmin] = await ethers.getSigners();
  console.log("👤 Deployer:", deployer.address);
  console.log("🕊️ Liturgical Admin:", liturgicalAdmin.address);

  // Deploy proxy per CaritasInternationalis
  const Caritas = await ethers.getContractFactory("CaritasInternationalis");
  const caritasProxy = await upgrades.deployProxy(Caritas, [], {
    initializer: "initialize"
  });
  await caritasProxy.waitForDeployment();
  console.log("✅ CaritasInternationalis proxy deployed at:", await caritasProxy.getAddress());

  // Deploy proxy per SistemaSistinaArt
  const Sistina = await ethers.getContractFactory("SistemaSistinaArt");
  const sistinaProxy = await upgrades.deployProxy(Sistina, [], {
    initializer: "initialize"
  });
  await sistinaProxy.waitForDeployment();
  console.log("🎨 SistemaSistinaArt proxy deployed at:", await sistinaProxy.getAddress());

  // Assegna ruoli liturgici
  const LITURGICAL_ROLE = ethers.keccak256(ethers.toUtf8Bytes("LITURGICAL_ADMIN"));
  await caritasProxy.grantRole(LITURGICAL_ROLE, liturgicalAdmin.address);
  await sistinaProxy.grantRole(LITURGICAL_ROLE, liturgicalAdmin.address);
  console.log("🪔 Ruoli liturgici assegnati a:", liturgicalAdmin.address);

  // Logging sacramentale
  console.log("📜 Deploy completato. I contratti sono pronti per la processione digitale.");
}

main().catch((error) => {
  console.error("❌ Errore durante il deploy:", error);
  process.exitCode = 1;
});
