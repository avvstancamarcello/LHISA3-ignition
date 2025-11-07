import pkg from 'hardhat';
const { ethers, upgrades } = pkg;

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);

    const hubAddress = "0x221be674D710e9AaD3129407538a5D84B5BF3FDb";

    // Deploy new implementation
    console.log("Deploying new SolidarySystemHub implementation...");
    let newImplAddress;
    try {
        const SolidarySystemHub = await ethers.getContractFactory("SolidarySystemHub");
        const newImpl = await upgrades.deployImplementation(SolidarySystemHub, {
            kind: 'uups',
            timeout: 600000 // 10 minutes
        });
        await newImpl.waitForDeployment();
        newImplAddress = await newImpl.getAddress();
        console.log("New implementation deployed at:", newImplAddress);
    } catch (error) {
        console.log("Deployment timed out or failed, using known address:", error.message);
        newImplAddress = "0x361eDa57Cd71C976B638fEC20256a433107c9282"; // From previous attempt
        console.log("Using address:", newImplAddress);
    }

    // Upgrade the proxy using upgrades.upgradeProxy
    console.log("Upgrading proxy...");
    const SolidarySystemHub = await ethers.getContractFactory("SolidarySystemHub");
    const upgraded = await upgrades.upgradeProxy(hubAddress, SolidarySystemHub, {
        kind: 'uups',
        timeout: 600000
    });
    console.log("Upgrade completed. New proxy at:", await upgraded.getAddress());

    // Now call emergencyGrantRoles
    console.log("Calling emergencyGrantRoles...");
    const txGrant = await Hub.emergencyGrantRoles();
    await txGrant.wait();
    console.log("Roles granted.");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});