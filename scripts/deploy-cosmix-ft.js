import pkg from 'hardhat';
const { ethers } = pkg;

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying COSMIX Protocol Token with account:", deployer.address);

    // Parametri
    const initialSupply = ethers.parseEther("1000000"); // 1M COSMIX
    const treasury = deployer.address;
    const admin = deployer.address;

    // Deploy
    const FTFactory = await ethers.getContractFactory("CosmixProtocolToken");
    const ft = await FTFactory.deploy();
    await ft.waitForDeployment();
    const ftAddress = await ft.getAddress();
    console.log("COSMIX Protocol Token deployed at:", ftAddress);

    // Inizializza
    const tx = await ft.initialize(admin, initialSupply, treasury);
    await tx.wait();
    console.log("Initialized with name: COSMIX Protocol Token, symbol: COSMIX, supply:", ethers.formatEther(initialSupply));

    // Ruoli
    const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("COSMIX_MINTER_ROLE"));
    const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("COSMIX_MANAGER_ROLE"));
    const hasMinter = await ft.hasRole(MINTER_ROLE, admin);
    const hasManager = await ft.hasRole(MANAGER_ROLE, admin);
    console.log("MINTER_ROLE:", hasMinter, "MANAGER_ROLE:", hasManager);

    // Validazione
    const name = await ft.name();
    const symbol = await ft.symbol();
    const totalSupply = await ft.totalSupply();
    console.log("Token name:", name);
    console.log("Token symbol:", symbol);
    console.log("Total supply:", ethers.formatEther(totalSupply));
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
