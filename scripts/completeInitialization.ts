import { ethers } from "hardhat";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);

    // Nuovi indirizzi dal deployed_addresses.json
    const hubAddress = "0x221be674D710e9AaD3129407538a5D84B5BF3FDb";
    const routerAddress = "0x0c415b3c53727fd1Ab02D3EC337aDB4b2399277e";
    const trustManagerAddress = "0x71fEB584DFE553268152A699a98194B5724F74b1";
    const orchestratorAddress = "0x89CfA5418326f22999Ac2265aA48D173A4Da6f86";
    const metricsAddress = "0xf7d5dED91d12FF8A9F08888dF2Da1E680af0F9FB";
    const reputationManagerAddress = "0xd9f12bC43287BC98392C52C16E12c27e55E0fF0b";
    const oceanMangaNFTAddress = "0xBeC80BF2ef21597c0b40106D8eF70d03fEE44C79";
    const lunaComicsFTAddress = "0xE82CCA2448C87c4B07e489714eC16684209D7D58";

    // Ottieni le istanze dei contratti
    const Hub = await ethers.getContractAt("SolidarySystemHub", hubAddress);
    const Router = await ethers.getContractAt("SolidarySystemModuleRouter2", routerAddress);
    const TrustManager = await ethers.getContractAt("SolidarySystemTrustManager4", trustManagerAddress);
    const Orchestrator = await ethers.getContractAt("UniversalMultiChainOrchestratorV2", orchestratorAddress);

    // Prima, concedi ECOSYSTEM_ADMIN al deployer se necessario
    const ECOSYSTEM_ADMIN = ethers.keccak256(ethers.toUtf8Bytes("ECOSYSTEM_ADMIN"));
    const hasRole = await Hub.hasRole(ECOSYSTEM_ADMIN, deployer.address);
    if (!hasRole) {
        console.log("Granting ECOSYSTEM_ADMIN to deployer...");
        await Hub.grantRole(ECOSYSTEM_ADMIN, deployer.address);
        console.log("Granted.");
    } else {
        console.log("Deployer already has ECOSYSTEM_ADMIN.");
    }

    // Ora, chiama initializeEcosystem
    console.log("Calling initializeEcosystem...");
    try {
        await Hub.initializeEcosystem(
            hubAddress, // _orchestrator
            oceanMangaNFTAddress, // _nftPlanet
            lunaComicsFTAddress, // _ftSatellite
            metricsAddress, // _metrics
            reputationManagerAddress, // _reputationManager
            "0x3E01ecA61f0ac7A25dF2142D3C036292808E0B91", // _impactLogger (ImpactLogger address)
            routerAddress, // _moduleRouter
            orchestratorAddress, // _multiChainOrchestrator
            trustManagerAddress // _moduleUtils
        );
        console.log("initializeEcosystem called successfully.");
    } catch (error) {
        console.error("Error calling initializeEcosystem:", error);
    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});