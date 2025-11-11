const fs = require('fs');
const path = require('path');
const { ethers } = require('hardhat');

async function main() {
  const [signer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();

  console.log('🔧 Granting MINTER_ROLE to Orchestrator...');
  console.log('👤 Signer:', signer.address);
  console.log('🌐 Network:', network.name, `(Chain ID: ${network.chainId})`);

  // --- 1. Load Addresses ---
  const ftAddressPath = path.join(__dirname, '..', 'TOKEN_ADDRESS.txt');
  const orchestratorAddressPath = path.join(__dirname, '..', 'last-orchestrator.json');

  if (!fs.existsSync(ftAddressPath) || !fs.existsSync(orchestratorAddressPath)) {
    throw new Error('Address file not found. Make sure TOKEN_ADDRESS.txt and last-orchestrator.json exist.');
  }

  const ftAddress = fs.readFileSync(ftAddressPath, 'utf8').trim();
  const orchestratorAddress = JSON.parse(fs.readFileSync(orchestratorAddressPath, 'utf8')).orchestrator;

  console.log('🎯 Target FT Contract:', ftAddress);
  console.log(' beneficiary (Orchestrator):', orchestratorAddress);

  // --- 2. Connect to Contract ---
  const ftAbi = [
    // Function to grant the role
    'function grantMinterRole(address orchestrator) external',
    // Function to check the role
    'function hasRole(bytes32 role, address account) external view returns (bool)',
    // Role hash
    'function MINTER_ROLE() external view returns (bytes32)',
  ];

  const ftContract = new ethers.Contract(ftAddress, ftAbi, signer);

  // --- 3. Check and Grant Role ---
  try {
    const minterRoleHash = await ftContract.MINTER_ROLE();
    console.log(`🔍 MINTER_ROLE hash: ${minterRoleHash}`);

    const hasRole = await ftContract.hasRole(minterRoleHash, orchestratorAddress);

    if (hasRole) {
      console.log('✅ Role already granted. No action needed.');
      return;
    }

    console.log('⏳ Role not found. Granting MINTER_ROLE to orchestrator...');
    const tx = await ftContract.grantMinterRole(orchestratorAddress);
    console.log('🧾 Transaction sent:', tx.hash);

    await tx.wait();
    console.log('✅ Transaction confirmed!');

    const hasRoleAfter = await ftContract.hasRole(minterRoleHash, orchestratorAddress);
    if (hasRoleAfter) {
      console.log('🎉 Successfully granted MINTER_ROLE to the orchestrator.');
    } else {
      throw new Error('Role grant failed after transaction confirmation.');
    }
  } catch (error) {
    console.error('❌ Error granting role:', error.message);
    if (error.message.includes('AccessControl: account')) {
        console.error('💡 Hint: The signer wallet does not have the MANAGER_ROLE required to grant roles.');
    }
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
