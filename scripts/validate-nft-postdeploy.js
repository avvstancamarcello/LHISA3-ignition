import pkg from 'hardhat';
const { ethers } = pkg;

// Inserisci qui l'indirizzo del contratto NFT appena deployato
const NFT_ADDRESS = "INSERISCI_ADDRESS_NFT";

async function validateNFTContract() {
    console.log("\n🔍 VALIDAZIONE POST-DEPLOY OceanMangaNFT_SecureFinal");
    try {
        const [deployer] = await ethers.getSigners();
        const nft = await ethers.getContractAt("OceanMangaNFT_SecureFinal", NFT_ADDRESS);

        // Leggi proprietà chiave
        const name = await nft.name();
        const symbol = await nft.symbol();
        const uri0 = await nft.uri(0);
        const supports1155 = await nft.supportsInterface("0xd9b67a26"); // ERC1155
        const supports2981 = await nft.supportsInterface("0x2a55205a"); // ERC2981
        const supportsAccessControl = await nft.supportsInterface("0x7965db0b");

        // Ruoli custom
        const ADMIN_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_ADMIN_ROLE"));
        const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MINTER_ROLE"));
        const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_MANAGER_ROLE"));
        const UPGRADER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("OCEANMANGA_UPGRADER_ROLE"));
        const DEFAULT_ADMIN = "0x0000000000000000000000000000000000000000000000000000000000000000";

        const hasAdmin = await nft.hasRole(ADMIN_ROLE, deployer.address);
        const hasMinter = await nft.hasRole(MINTER_ROLE, deployer.address);
        const hasManager = await nft.hasRole(MANAGER_ROLE, deployer.address);
        const hasUpgrader = await nft.hasRole(UPGRADER_ROLE, deployer.address);
        const hasDefaultAdmin = await nft.hasRole(DEFAULT_ADMIN, deployer.address);
        const noDefaultAdmin = await nft.verifyNoDefaultAdminRole(deployer.address);

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
        console.log("✅ Upgrader Role:", hasUpgrader);
        console.log("✅ Default Admin Role:", hasDefaultAdmin);
        console.log("✅ verifyNoDefaultAdminRole:", noDefaultAdmin);

        // Validazione logica
        if (!name || !symbol) {
            throw new Error("❌ ERRORE: NFT senza name/symbol!");
        }
        if (hasDefaultAdmin || !noDefaultAdmin) {
            throw new Error("❌ ERRORE: DEFAULT_ADMIN_ROLE presente!");
        }
        if (!hasAdmin || !hasMinter || !hasManager || !hasUpgrader) {
            throw new Error("❌ ERRORE: Ruoli custom mancanti!");
        }
        if (!supports1155 || !supports2981 || !supportsAccessControl) {
            throw new Error("❌ ERRORE: Interfacce non supportate!");
        }
        console.log("\n🎉 VALIDAZIONE COMPLETATA: NFT SICURO E FUNZIONANTE!");
    } catch (error) {
        console.error("❌ VALIDAZIONE FALLITA:", error.message);
    }
}

validateNFTContract();
