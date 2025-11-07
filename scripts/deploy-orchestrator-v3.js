import pkg from 'hardhat';
const { ethers } = pkg;

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying OceanMangaOrchestratorV3 with account:", deployer.address);

    // Inserisci qui gli indirizzi NFT e FT già deployati
    const nftAddress = "INSERISCI_ADDRESS_NFT";
    const ftAddress = "INSERISCI_ADDRESS_FT";
    const creator = deployer.address;
    const charity = deployer.address;

    // Deploy orchestrator
    const OrchestratorFactory = await ethers.getContractFactory("OceanMangaOrchestratorV3");
    const orchestrator = await OrchestratorFactory.deploy();
    await orchestrator.waitForDeployment();
    const orchestratorAddress = await orchestrator.getAddress();
    console.log("Orchestrator deployed at:", orchestratorAddress);

    // Inizializza
    const tx = await orchestrator.initialize(nftAddress, ftAddress, creator, charity);
    await tx.wait();
    console.log("Orchestrator initialized with NFT:", nftAddress, "FT:", ftAddress);

    // Assegna MINTER_ROLE all'orchestrator sull'NFT
    const NFTFactory = await ethers.getContractFactory("OceanMangaNFT");
    const nft = NFTFactory.attach(nftAddress);
    const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
    const grantTx = await nft.grantRole(MINTER_ROLE, orchestratorAddress);
    await grantTx.wait();
    console.log("MINTER_ROLE granted to orchestrator on NFT");
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
