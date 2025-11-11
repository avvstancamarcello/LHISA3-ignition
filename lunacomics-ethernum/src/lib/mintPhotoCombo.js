// mintPhotoCombo.js
// Invoke orchestrator legacy mintPhotoCombo(tokenURI) payable.
// Returns structured result with tokenId, FT distribution (gross, net, royalties), transaction info.

import { ethers } from 'ethers';
import { ORCHESTRATOR_ABI, getOrchestratorAddress } from '../config/contracts';
import { formatToken } from './formatToken';

const ORCHESTRATOR_VIEW_ABI = [
  ...ORCHESTRATOR_ABI,
  { inputs: [], name: 'nextTokenId', outputs: [{ type: 'uint256' }], stateMutability: 'view', type: 'function' },
  { inputs: [], name: 'lunaComicsFT', outputs: [{ type: 'address' }], stateMutability: 'view', type: 'function' },
  { inputs: [], name: 'oceanMangaNFT', outputs: [{ type: 'address' }], stateMutability: 'view', type: 'function' },
  { inputs: [], name: 'creator', outputs: [{ type: 'address' }], stateMutability: 'view', type: 'function' },
  { inputs: [], name: 'charityFund', outputs: [{ type: 'address' }], stateMutability: 'view', type: 'function' },
  // Event for decoding
  {
    type: 'event',
    name: 'PhotoMinted',
    inputs: [
      { name: 'user', type: 'address', indexed: true },
      { name: 'tokenURI', type: 'string', indexed: false },
      { name: 'ethPaid', type: 'uint256', indexed: false },
      { name: 'nftId', type: 'uint256', indexed: false },
      { name: 'ftAmount', type: 'uint256', indexed: false }
    ]
  }
];

const ERC20_ABI = [
  { inputs: [{ name: 'account', type: 'address' }], name: 'balanceOf', outputs: [{ type: 'uint256' }], stateMutability: 'view', type: 'function' },
  { inputs: [], name: 'decimals', outputs: [{ type: 'uint8' }], stateMutability: 'view', type: 'function' },
];

const FT_READ_ABI = [
  { inputs: [], name: 'tokensPerEth', outputs: [{ type: 'uint256' }], stateMutability: 'view', type: 'function' },
  ...ERC20_ABI,
];

// Constants (mirror contract shares)
const FT_SHARE_BPS = 450; // basis points scaled to 1000 in contract logic
const CREATOR_BPS = 25;   // 2.5%
const CHARITY_BPS = 25;   // 2.5%

/**
 * Estimate gross FT minted given ETH value and tokensPerEth.
 * tokensPerEth is obtained by reading the FT contract if available (optional).
 */
export async function estimateFtFromEth(provider, ftAddress, ethValueWei) {
  try {
    if (!ftAddress || ftAddress === ethers.ZeroAddress) return null;
    const ft = new ethers.Contract(ftAddress, FT_READ_ABI, provider);
    const [tpe, decimals] = await Promise.all([
      ft.tokensPerEth(),
      (async () => { try { return await ft.decimals(); } catch { return 18; } })(),
    ]);
    // Orchestrator uses 45% of ETH for FT mint
    const ethForFT = (ethValueWei * 450n) / 1000n; // 45%
    const gross = (ethForFT * BigInt(tpe)) / ethers.parseEther('1');
    const creator = (gross * 25n) / 1000n; // 2.5%
    const charity = (gross * 25n) / 1000n; // 2.5%
    const net = gross - creator - charity;
    return {
      tokensPerEth: tpe.toString(),
      decimals: Number(decimals),
      gross,
      net,
      creator,
      charity,
      formatted: {
        gross: formatToken(gross, Number(decimals)),
        net: formatToken(net, Number(decimals)),
        creator: formatToken(creator, Number(decimals)),
        charity: formatToken(charity, Number(decimals)),
      }
    };
  } catch {
    return null;
  }
}

/**
 * Perform the mint transaction.
 * @param {Object} params
 * @param {ethers.BrowserProvider} params.provider - Ethers v6 BrowserProvider
 * @param {string} params.tokenURI - tokenURI string
 * @param {string|number} params.ethValue - ETH float string or number
 * @param {number} [params.chainIdExpected=8453] - expected chain id (Base mainnet default)
 * @returns {Promise<Object>} result
 */
export async function mintPhotoCombo({ provider, tokenURI, ethValue, chainIdExpected = 8453 }) {
  if (!provider) throw new Error('Provider missing');
  if (!tokenURI) throw new Error('tokenURI missing');
  if (!ethValue || Number(ethValue) <= 0) throw new Error('ethValue invalid');

  const network = await provider.getNetwork();
  if (network.chainId !== BigInt(chainIdExpected)) {
    throw new Error(`Wrong network chainId=${network.chainId} expected=${chainIdExpected}`);
  }

  const signer = await provider.getSigner();
  const userAddress = await signer.getAddress();

  const orchestratorAddress = getOrchestratorAddress(Number(network.chainId));
  if (!orchestratorAddress) throw new Error('Orchestrator address not configured for this network');

  const orchestrator = new ethers.Contract(orchestratorAddress, ORCHESTRATOR_VIEW_ABI, signer);

  // Prefetch state
  const [nextTokenId, ftAddr, creator, charity] = await Promise.all([
    orchestrator.nextTokenId(),
    orchestrator.lunaComicsFT(),
    orchestrator.creator(),
    orchestrator.charityFund(),
  ]);

  const ftContract = new ethers.Contract(ftAddr, ERC20_ABI, provider);
  let decimals = 18;
  try { decimals = await ftContract.decimals(); } catch (_) {}

  // Balances pre
  const [userPre, creatorPre, charityPre] = await Promise.all([
    ftContract.balanceOf(userAddress),
    ftContract.balanceOf(creator),
    ftContract.balanceOf(charity),
  ]);

  // Send tx
  const valueWei = ethers.parseEther(String(ethValue));
  let tx;
  try {
    tx = await orchestrator.mintPhotoCombo(tokenURI, { value: valueWei });
  } catch (e) {
    throw new Error(`Tx submit failed: ${e.message || e}`);
  }

  const receipt = await tx.wait();

  // Decode PhotoMinted event if present
  let eventDecoded = null;
  try {
    const iface = new ethers.Interface(ORCHESTRATOR_VIEW_ABI);
    for (const log of receipt.logs) {
      if ((log.address?.toLowerCase?.() || '') === orchestratorAddress.toLowerCase()) {
        try {
          const parsed = iface.parseLog({ topics: log.topics, data: log.data });
          if (parsed?.name === 'PhotoMinted') {
            eventDecoded = {
              user: parsed.args?.user,
              tokenURI: parsed.args?.tokenURI,
              ethPaid: parsed.args?.ethPaid?.toString?.(),
              nftId: parsed.args?.nftId?.toString?.(),
              ftAmount: parsed.args?.ftAmount?.toString?.(), // Net FT according to contract emit
            };
            break;
          }
        } catch {}
      }
    }
  } catch {}

  // Balances post
  const [userPost, creatorPost, charityPost] = await Promise.all([
    ftContract.balanceOf(userAddress),
    ftContract.balanceOf(creator),
    ftContract.balanceOf(charity),
  ]);

  const userDelta = userPost - userPre;
  const creatorDelta = creatorPost - creatorPre;
  const charityDelta = charityPost - charityPre;
  const grossMinted = userDelta + creatorDelta + charityDelta;

  // Royalties percentages computed from deltas
  const pct = (portion) => grossMinted > 0n ? Number((portion * 10000n) / grossMinted) / 100 : 0;

  // Build result
  return {
    status: 'confirmed',
    txHash: tx.hash,
    tokenId: nextTokenId.toString(), // minted ID equals pre-call nextTokenId
    chainId: Number(network.chainId),
    orchestrator: orchestratorAddress,
    ftAddress: ftAddr,
    creator,
    charity,
    grossMinted: grossMinted.toString(),
    netToUser: userDelta.toString(),
    creatorRoyalty: creatorDelta.toString(),
    charityRoyalty: charityDelta.toString(),
    grossFormatted: formatToken(grossMinted, decimals),
    netFormatted: formatToken(userDelta, decimals),
    creatorFormatted: formatToken(creatorDelta, decimals),
    charityFormatted: formatToken(charityDelta, decimals),
    royaltiesPct: {
      creator: pct(creatorDelta),
      charity: pct(charityDelta),
    },
    gasUsed: receipt.gasUsed?.toString(),
    event: eventDecoded,
  };
}
