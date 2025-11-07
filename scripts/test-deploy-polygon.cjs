const { ethers } = require("hardhat");

async function main() {
  try {
    console.log("Testing deployment on Polygon...");
    const [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);
    console.log("Deployer balance:", (await ethers.provider.getBalance(deployer.address)).toString());

    console.log("Getting contract factory...");
    const SolidaryHub = await ethers.getContractFactory("SolidarySystemHub");
    console.log("Contract factory ready");

    console.log("Estimating gas...");
    const estimatedGas = await ethers.provider.estimateGas(SolidaryHub.getDeployTransaction());
    console.log("Estimated gas:", estimatedGas.toString());

    console.log("Deploying with EIP-1559 fees...");
    const deployTx = await SolidaryHub.deploy({
      maxFeePerGas: ethers.parseUnits("300", "gwei"), // 300 Gwei
      maxPriorityFeePerGas: ethers.parseUnits("50", "gwei"), // 50 Gwei
    });
    console.log("Deploy tx sent:", deployTx.deploymentTransaction().hash);

    console.log("Waiting for deployment...");
    const timeout = setTimeout(() => {
      console.log("Deployment timeout after 5 minutes");
      process.exit(1);
    }, 300000); // 5 minutes

    await deployTx.waitForDeployment();
    clearTimeout(timeout);
    const address = await deployTx.getAddress();
    console.log("Deployed at:", address);

  } catch (error) {
    console.error("Error:", error.message);
  }
}

main();