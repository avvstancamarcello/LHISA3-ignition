#!/usr/bin/env node
/**
 * Quick test mint invoking orchestrator's legacy mintPhotoCombo(tokenURI) that:
 *  - Accepts ETH
 *  - Mints 1 NFT to caller
 *  - Uses 45% of the ETH to mint FT via mintWithEth (through orchestrator logic)
 *  - Distributes FT: net (after 2x2.5% royalties) to user, royalties to creator & charity
 *  - Leaves residual ETH (remaining 55% - royalties fractions) inside orchestrator.
 *
 * Output:
 *  - Transaction hash + gas used
 *  - NFT id minted
 *  - FT amounts: gross minted, net to user, creator royalty, charity royalty
 *  - Post-balances (user, creator, charity) of FT
 *  - ETH deltas (optional when provider supports debug_trace)
 *
 * Usage:
 *   HARDHAT_NETWORK=base node scripts/mint-orchestrator-test.cjs --value 0.01 --uri ipfs://yourMetadata
 *   HARDHAT_NETWORK=base_sepolia node scripts/mint-orchestrator-test.cjs --value 0.002
 *
 * Flags:
 *  --value <ethFloat>   Amount of ETH to send (default 0.002)
 *  --uri <string>       tokenURI metadata (default ipfs://test-metadata)
 *  --orchestrator <addr> Override orchestrator address (defaults from last-orchestrator.json)
 */

const fs = require('fs');
const path = require('path');
const { ethers } = require('hardhat');

async function main(){
  const args = process.argv.slice(2);
  function getFlag(name, def){
    const i = args.indexOf(name);
    if(i === -1) return def;
    return args[i+1] || def;
  }
  const ethValue = parseFloat(getFlag('--value','0.002'));
  const tokenURI = getFlag('--uri','ipfs://test-metadata');
  const overrideOrch = getFlag('--orchestrator', null);
  if(isNaN(ethValue) || ethValue <= 0){
    console.error('❌ Invalid --value');
    process.exit(1);
  }

  // Load orchestrator address
  let orchestratorAddress;
  if(overrideOrch){
    orchestratorAddress = overrideOrch;
  } else {
    const lastPath = path.join(__dirname,'..','last-orchestrator.json');
    if(!fs.existsSync(lastPath)){
      console.error('❌ last-orchestrator.json not found, use --orchestrator');
      process.exit(1);
    }
    const json = JSON.parse(fs.readFileSync(lastPath,'utf8'));
    orchestratorAddress = json.orchestrator;
  }

  // Minimal ABI subset for legacy mint + views
  const orchestratorAbi = [
    'function mintPhotoCombo(string memory tokenURI) external payable',
    'function nextTokenId() external view returns(uint256)',
    'function oceanMangaNFT() external view returns(address)',
    'function lunaComicsFT() external view returns(address)',
    'function creator() external view returns(address)',
    'function charityFund() external view returns(address)'
  ];

  const erc20Abi = [
    'function balanceOf(address) view returns(uint256)',
    'function decimals() view returns(uint8)'
  ];

  const [signer] = await ethers.getSigners();
  console.log('👤 Signer:', await signer.getAddress());
  console.log('🌐 Network:', (await ethers.provider.getNetwork()).name, (await ethers.provider.getNetwork()).chainId);
  console.log('🎯 Orchestrator:', orchestratorAddress);
  console.log('💧 Sending ETH value:', ethValue,'ETH');

  const orchestrator = new ethers.Contract(orchestratorAddress, orchestratorAbi, signer);

  // Pre-call data
  const nextId = await orchestrator.nextTokenId();
  const expectedTokenId = nextId;
  const ftAddr = await orchestrator.lunaComicsFT();
  const nftAddr = await orchestrator.oceanMangaNFT();
  const creator = await orchestrator.creator();
  const charity = await orchestrator.charityFund();

  const ft = new ethers.Contract(ftAddr, erc20Abi, signer);
  const [decimals] = await Promise.all([ft.decimals()]);
  const userPre = await ft.balanceOf(await signer.getAddress());
  const creatorPre = await ft.balanceOf(creator);
  const charityPre = await ft.balanceOf(charity);

  console.log('🧾 NFT contract:', nftAddr);
  console.log('🪙 FT contract:', ftAddr,'decimals', decimals);
  console.log('👨‍🎨 Creator:', creator);
  console.log('💝 Charity:', charity);

  console.log('⏳ Sending transaction...');
  const tx = await orchestrator.mintPhotoCombo(tokenURI,{
    value: ethers.parseEther(ethValue.toString())
  });
  console.log('🧾 Tx hash:', tx.hash);
  const receipt = await tx.wait();
  console.log('⛽ Gas used:', receipt.gasUsed.toString());

  // Post-call balances
  const userPost = await ft.balanceOf(await signer.getAddress());
  const creatorPost = await ft.balanceOf(creator);
  const charityPost = await ft.balanceOf(charity);

  const userDelta = userPost - userPre;
  const creatorDelta = creatorPost - creatorPre;
  const charityDelta = charityPost - charityPre;

  // Based on contract constants: royalties each 2.5% of gross; net = gross - two royalties.
  // We can back-compute gross minted: gross = userDelta + creatorDelta + charityDelta
  const grossMinted = userDelta + creatorDelta + charityDelta;
  let creatorPctBp = grossMinted > 0n ? (creatorDelta * 100000n)/grossMinted : 0n;
  let charityPctBp = grossMinted > 0n ? (charityDelta * 100000n)/grossMinted : 0n;

  console.log('\n✅ Mint SUCCESS');
  console.log('🖼️  NFT minted id (expected):', expectedTokenId.toString());
  console.log('🪙 Gross FT minted:', formatToken(grossMinted, decimals));
  console.log('   -> Net to user (45% - royalties):', formatToken(userDelta, decimals));
  console.log('   -> Creator royalty (2.5% target):', formatToken(creatorDelta, decimals),`(${Number(creatorPctBp)/1000}% approx)`);
  console.log('   -> Charity royalty (2.5% target):', formatToken(charityDelta, decimals),`(${Number(charityPctBp)/1000}% approx)`);
  console.log('🔗 Explorer (Base): https://basescan.org/tx/'+tx.hash);

  console.log('\nBalances diff (FT):');
  console.log('  User   +', formatToken(userDelta, decimals));
  console.log('  Creator+', formatToken(creatorDelta, decimals));
  console.log('  Charity+', formatToken(charityDelta, decimals));

  // NOTE: residual ETH and FT remain in orchestrator per design (not shown here).
}

function formatToken(amount, decimals){
  const factor = 10n ** BigInt(decimals);
  const whole = amount / factor;
  const frac = amount % factor;
  const fracStr = frac.toString().padStart(decimals,'0').slice(0,6); // first 6 decimal digits
  return `${whole}.${fracStr}`;
}

main().catch(e=>{console.error('❌ Failure',e);process.exit(1);});
