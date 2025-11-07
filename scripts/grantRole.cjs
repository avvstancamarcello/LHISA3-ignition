const { ethers } = require("hardhat");

async function main() {
    const hubAddress = "0xA740d24fcF5Ca9282fC4DB0b97c0A92b06AC7778";
    const hub = await ethers.getContractAt("SolidarySystemHub", hubAddress);

    const DEFAULT_ADMIN_ROLE = "0xa49b0dc1e696db729b090931047acb0b49e21c13be3be601c57eb24eaf8760c0";
    const wallet = "0x8495B3f7493263685fFcDA2602fFfF349d4eD3B8";

    const tx = await hub.grantRole(DEFAULT_ADMIN_ROLE, wallet);
    await tx.wait();
    console.log("Ruolo DEFAULT_ADMIN_ROLE concesso a", wallet);
}

main().catch(console.error);
