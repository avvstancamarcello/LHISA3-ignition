import pkg from 'hardhat';
const { ethers } = pkg;

async function main() {
    const addr = "0x8495b3f7493263685fFcDA2602fFfF349d4eD3B8";
    const network = "polygon"; // Cambia a "base" se necessario

    console.log(`Controllo saldo su ${network} per ${addr}...`);

    // Ottieni provider per la rete (usa quello di hardhat)
    const provider = ethers.provider;

    // Saldo attuale
    const balanceWei = await provider.getBalance(addr);
    const balanceMatic = ethers.formatEther(balanceWei);
    console.log(`Saldo attuale: ${balanceMatic} MATIC`);

    // Stima costo per deploy (basata su dati passati)
    // Dal CSV precedente: ~17 transazioni, gas totale ~1.5 POL
    // Per completare: assumi altre 10-20 transazioni, costo ~0.5-2 POL
    const estimatedCostLow = 0.5; // MATIC
    const estimatedCostHigh = 2.0; // MATIC

    console.log(`Stima costo per completare deploy: ${estimatedCostLow} - ${estimatedCostHigh} MATIC`);
    console.log(`(Basata su ~10-20 transazioni aggiuntive, gas price attuale ~25 gwei)`);

    // Controlla se sufficiente
    if (parseFloat(balanceMatic) < estimatedCostHigh) {
        console.log(`ATTENZIONE: Saldo insufficiente. Aggiungi almeno ${estimatedCostHigh - parseFloat(balanceMatic)} MATIC.`);
    } else {
        console.log(`Saldo sufficiente per il deploy.`);
    }

    // Gas price attuale
    const gasPrice = await provider.getFeeData();
    console.log(`Gas price attuale: ${ethers.formatUnits(gasPrice.gasPrice, 'gwei')} gwei`);
}

main().catch((error) => {
    console.error("Errore:", error);
    process.exitCode = 1;
});