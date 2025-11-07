import pkg from 'hardhat';
const { ethers } = pkg;

async function main() {
    // Inserisci qui l'indirizzo dell'orchestrator
    const orchestratorAddress = "INSERISCI_ADDRESS_ORCHESTRATOR";
    const OrchestratorFactory = await ethers.getContractFactory("OceanMangaOrchestratorV3");
    const orchestrator = OrchestratorFactory.attach(orchestratorAddress);

    // Validazione parametri
    const nftAddress = await orchestrator.oceanMangaNFT();
    const ftAddress = await orchestrator.cosmixFT();
    const lockPeriod = await orchestrator.lockPeriod();
    console.log("NFT address:", nftAddress);
    console.log("FT address:", ftAddress);
    console.log("Lock period (seconds):", lockPeriod);

    // Test mint combinato (solo se vuoi simulare)
    // const tx = await orchestrator.mintPhotoCombo("ipfs://testuri");
    // await tx.wait();
    // console.log("Mint combinato eseguito");
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
