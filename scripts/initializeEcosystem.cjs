const { ethers } = require("hardhat");

async function main() {
    const hubAddress = "0xA740d24fcF5Ca9282fC4DB0b97c0A92b06AC7778";
    const hub = await ethers.getContractAt("SolidarySystemHub", hubAddress);

    const tx = await hub.initializeEcosystem(
        "0xA740d24fcF5Ca9282fC4DB0b97c0A92b06AC7778",
        "0xDD2719a4dF35b553878991565599B4D0E9Abd336",
        "0x6F798899abfEA71A3435f6358a950d4e7785B5a3",
        "0x2c4FB783E140a448B33c58aF7bb528c24BF76811",
        "0x67ddA25d10812CDC9F12a4beFBf12760EC5dd957",
        "0x2B4F51c18d47286A67Ea3cDcFE314f878112EeDA",
        "0xE29C728B74Df29655Bc90b6f0586CB6cCc1d8C44",
        "0xE97e9Dbf6c9E662440199f75522b9Ebd5334624e",
        "0xD3e74ed2B62cDAb6d3D8Ff15C0178E3E854B2f58"
    );

    await tx.wait();
    console.log("initializeEcosystem completato!");
}

main().catch(console.error);
