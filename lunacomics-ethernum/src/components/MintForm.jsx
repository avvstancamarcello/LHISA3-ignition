import React, { useEffect, useMemo, useState } from 'react';
import { ethers } from 'ethers';
import { generateTokenURI } from '../lib/generateTokenURI';
import { mintPhotoCombo, estimateFtFromEth } from '../lib/mintPhotoCombo';
import { DEFAULT_CHAIN_ID, getOrchestratorAddress } from '../config/contracts';

export default function MintForm({ provider }) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [imageCID, setImageCID] = useState('');
  const [ethValue, setEthValue] = useState('0.002');
  const [status, setStatus] = useState('idle');
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);
  const [estimate, setEstimate] = useState(null);
  const [estimating, setEstimating] = useState(false);

  const canSubmit = useMemo(() => {
    return Number(ethValue) > 0 && (title || description || imageCID);
  }, [ethValue, title, description, imageCID]);

  // Recalculate FT estimate when ethValue changes & provider available
  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        setEstimating(true);
        setEstimate(null);
        if (!window.ethereum && !provider) return;
        if (!ethValue || Number(ethValue) <= 0) return;

        // Build provider if not provided
        const prov = provider || new ethers.BrowserProvider(window.ethereum);
        const network = await prov.getNetwork();
        const chainIdNum = Number(network.chainId);
        if (chainIdNum !== DEFAULT_CHAIN_ID) return;

        const orchAddr = getOrchestratorAddress(chainIdNum);
        if (!orchAddr) return;

        const ORCH_MIN_ABI = [
          { inputs: [], name: 'lunaComicsFT', outputs: [{ type: 'address' }], stateMutability: 'view', type: 'function' }
        ];
        const orch = new ethers.Contract(orchAddr, ORCH_MIN_ABI, prov);
        const ftAddr = await orch.lunaComicsFT();
        const valueWei = ethers.parseEther(String(ethValue));
        if (valueWei <= 0n) return;
        const est = await estimateFtFromEth(prov, ftAddr, valueWei);
        if (!cancelled) setEstimate(est);
      } catch (e) {
        if (!cancelled) setEstimate(null);
      } finally {
        if (!cancelled) setEstimating(false);
      }
    })();
    return () => { cancelled = true; };
  }, [provider, ethValue]);

  async function onSubmit(e) {
    e.preventDefault();
    setStatus('preparing');
    setError(null);
    setResult(null);

    try {
      // 1) Build tokenURI
      const { tokenURI } = await generateTokenURI({
        title, description, imageCID, attributes: []
      }, { mode: 'data' }); // default to inline data URI; can switch to 'ipfs'

      setStatus('sending');

      // 2) Send transaction
      const res = await mintPhotoCombo({
        provider,
        tokenURI,
        ethValue,
        chainIdExpected: DEFAULT_CHAIN_ID,
      });

      // Compute estimation snapshot post-mint using on-chain result (for accuracy)
      try {
        setEstimate({
          gross: res.grossFormatted,
          net: res.netFormatted,
          creator: res.creatorFormatted,
          charity: res.charityFormatted,
        });
      } catch {}

      setResult(res);
      setStatus('confirmed');
    } catch (e) {
      setError(e?.message || String(e));
      setStatus('error');
    }
  }

  return (
    <div style={{ maxWidth: 560, margin: '0 auto', padding: 16 }}>
      <h2>Mint Photo Combo</h2>
      <form onSubmit={onSubmit}>
        <div style={{ marginBottom: 8 }}>
          <label>Title</label>
          <input type="text" value={title} onChange={e=>setTitle(e.target.value)} placeholder="Title" style={{ width: '100%' }} />
        </div>
        <div style={{ marginBottom: 8 }}>
          <label>Description</label>
          <textarea value={description} onChange={e=>setDescription(e.target.value)} placeholder="Description" style={{ width: '100%' }} />
        </div>
        <div style={{ marginBottom: 8 }}>
          <label>Image CID (ipfs)</label>
          <input type="text" value={imageCID} onChange={e=>setImageCID(e.target.value)} placeholder="Qm..." style={{ width: '100%' }} />
        </div>
        <div style={{ marginBottom: 8 }}>
          <label>ETH amount</label>
          <input type="number" step="0.0001" min="0" value={ethValue} onChange={e=>setEthValue(e.target.value)} style={{ width: '100%' }} />
        </div>

        {estimating && <p>Estimating FT from ETH…</p>}
        {estimate && (
          <div style={{ margin: '8px 0', padding: 8, background: '#f6f6f6', borderRadius: 6 }}>
            <div><strong>Estimated FT</strong></div>
            <div>Gross: {estimate.formatted.gross}</div>
            <div>Net to you: {estimate.formatted.net}</div>
            <div>Royalties: creator {estimate.formatted.creator}, charity {estimate.formatted.charity}</div>
          </div>
        )}

        <button type="submit" disabled={!canSubmit || status==='sending'}>
          {status === 'sending' ? 'Minting…' : 'Mint'}
        </button>
      </form>

      {status === 'preparing' && <p>Preparing tokenURI…</p>}
      {status === 'sending' && <p>Sending transaction…</p>}
      {status === 'error' && <p style={{ color: 'crimson' }}>Error: {error}</p>}
      {status === 'confirmed' && result && (
        <div style={{ marginTop: 16 }}>
          <h3>Mint Confirmed</h3>
          <div>Tx: <a href={`https://basescan.org/tx/${result.txHash}`} target="_blank" rel="noreferrer">{result.txHash}</a></div>
          <div>NFT ID: {result.tokenId}</div>
          <div>Gross FT: {result.grossFormatted}</div>
          <div>Net to you: {result.netFormatted}</div>
          <div>Royalties: creator {result.creatorFormatted} ({result.royaltiesPct.creator}%), charity {result.charityFormatted} ({result.royaltiesPct.charity}%)</div>
          {result.event && (
            <div style={{ marginTop: 8 }}>
              <strong>Event Decoded:</strong> net FT (ftAmount) = {result.event.ftAmount}, ethPaid = {result.event.ethPaid}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
