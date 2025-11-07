import pkg from 'hardhat';
const { ethers } = pkg;

// Inserisci qui l'indirizzo del contratto NFT appena deployato
const NFT_ADDRESS = "INSERISCI_ADDRESS_NFT";

async function validateOceanMangaNFT() {
    console.log("\n🔍 VALIDAZIONE POST-DEPLOY OceanMangaNFT.sol");
    try {
        const [deployer] = await ethers.getSigners();
        const nft = await ethers.getContractAt("OceanMangaNFT", NFT_ADDRESS);

        // Leggi proprietà chiave
        const name = await nft.name();
        const symbol = await nft.symbol();
        const uri0 = await nft.uri(0);
        const supports1155 = await nft.supportsInterface("0xd9b67a26"); // ERC1155
        const supports2981 = await nft.supportsInterface("0x2a55205a"); // ERC2981
        const supportsAccessControl = await nft.supportsInterface("0x7965db0b");

        // Ruoli
        const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";
        const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
        const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MANAGER_ROLE"));

        const hasAdmin = await nft.hasRole(DEFAULT_ADMIN_ROLE, deployer.address);
        const hasMinter = await nft.hasRole(MINTER_ROLE, deployer.address);
        const hasManager = await nft.hasRole(MANAGER_ROLE, deployer.address);

        // Output dettagliato
        console.log("✅ Address:", NFT_ADDRESS);
        console.log("✅ Name:", name);
        console.log("✅ Symbol:", symbol);
        console.log("✅ URI (id=0):", uri0);
        console.log("✅ ERC1155:", supports1155);
        console.log("✅ ERC2981:", supports2981);
        console.log("✅ AccessControl:", supportsAccessControl);
        console.log("✅ Admin Role:", hasAdmin);
        console.log("✅ Minter Role:", hasMinter);
        console.log("✅ Manager Role:", hasManager);

        // Validazione logica
        if (!name || !symbol) {
            throw new Error("❌ ERRORE: NFT senza name/symbol!");
        }
        if (!hasAdmin) {
            throw new Error("❌ ERRORE: DEFAULT_ADMIN_ROLE mancante!");
        }
        if (!hasMinter || !hasManager) {
            throw new Error("❌ ERRORE: Ruoli MINTER/MANAGER mancanti!");
        }
        if (!supports1155 || !supports2981 || !supportsAccessControl) {
            throw new Error("❌ ERRORE: Interfacce non supportate!");
        }
        console.log("\n🎉 VALIDAZIONE COMPLETATA: NFT OceanMangaNFT FUNZIONANTE!");
    } catch (error) {
        console.error("❌ VALIDAZIONE FALLITA:", error.message);
    }
}

validateOceanMangaNFT();
