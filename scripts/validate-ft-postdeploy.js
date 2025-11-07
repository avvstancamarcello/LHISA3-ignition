import pkg from 'hardhat';
const { ethers } = pkg;

// Inserisci qui l'indirizzo del contratto FT appena deployato
const FT_ADDRESS = "0xF8d5a00Ca91D46c07614208C346c49a09409D094";

async function validateFTContract() {
    console.log("\n🔍 VALIDAZIONE POST-DEPLOY FT CONTRACT");
    try {
        const [deployer] = await ethers.getSigners();
        const ft = await ethers.getContractAt("LunaComicsFT", FT_ADDRESS);

        // Leggi proprietà chiave
        const name = await ft.name();
        const symbol = await ft.symbol();
        const totalSupply = await ft.totalSupply();
        const decimals = await ft.decimals();
        const treasuryBalance = await ft.balanceOf(deployer.address);

        // Ruoli
        const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";
        const MINTER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MINTER_ROLE"));
        const MANAGER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("MANAGER_ROLE"));

        const hasAdmin = await ft.hasRole(DEFAULT_ADMIN_ROLE, deployer.address);
        const hasMinter = await ft.hasRole(MINTER_ROLE, deployer.address);
        const hasManager = await ft.hasRole(MANAGER_ROLE, deployer.address);

        // Output dettagliato
        console.log("✅ Address:", FT_ADDRESS);
        console.log("✅ Name:", name);
        console.log("✅ Symbol:", symbol);
        console.log("✅ Total Supply:", ethers.formatEther(totalSupply));
        console.log("✅ Decimals:", decimals.toString());
        console.log("✅ Treasury Balance:", ethers.formatEther(treasuryBalance));
        console.log("✅ Admin Role:", hasAdmin);
        console.log("✅ Minter Role:", hasMinter);
        console.log("✅ Manager Role:", hasManager);

        // Validazione logica
        if (!name || !symbol) {
            throw new Error("❌ ERRORE: Token FT senza name/symbol!");
        }
        if (hasAdmin) {
            throw new Error("❌ ERRORE: DEFAULT_ADMIN_ROLE presente!");
        }
        if (!hasMinter || !hasManager) {
            throw new Error("❌ ERRORE: Ruoli MINTER/MANAGER mancanti!");
        }
        console.log("\n🎉 VALIDAZIONE COMPLETATA: FT CONTRACT FUNZIONANTE E SICURO!");
    } catch (error) {
        console.error("❌ VALIDAZIONE FALLITA:", error.message);
    }
}

validateFTContract();
