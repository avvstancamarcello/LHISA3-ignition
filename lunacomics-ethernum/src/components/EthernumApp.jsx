import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { generateTokenURI } from '../lib/generateTokenURI';
import { mintPhotoCombo, estimateFtFromEth } from '../lib/mintPhotoCombo';
import { DEFAULT_CHAIN_ID, getOrchestratorAddress, CONTRACT_ADDRESSES } from '../config/contracts';
import './EthernumApp.css';

/**
 * APP Ethernum - Complete NFT and FT Minting Application
 * Governed by OceanMangaOrchestrator smart contract
 */
export default function EthernumApp() {
  // Wallet state
  const [account, setAccount] = useState(null);
  const [provider, setProvider] = useState(null);
  const [chainId, setChainId] = useState(null);
  const [isConnecting, setIsConnecting] = useState(false);

  // Form state
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [imageCID, setImageCID] = useState('');
  const [ethValue, setEthValue] = useState('0.002');
  
  // Minting state
  const [status, setStatus] = useState('idle');
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);
  const [estimate, setEstimate] = useState(null);
  const [estimating, setEstimating] = useState(false);

  // Balances
  const [ftBalance, setFtBalance] = useState(null);

  // Contract info
  const [contractInfo, setContractInfo] = useState(null);

  // Connect wallet
  const connectWallet = async () => {
    if (!window.ethereum) {
      alert('Please install MetaMask or another Web3 wallet!');
      return;
    }

    setIsConnecting(true);
    try {
      const prov = new ethers.BrowserProvider(window.ethereum);
      const accounts = await prov.send('eth_requestAccounts', []);
      const network = await prov.getNetwork();
      
      setProvider(prov);
      setAccount(accounts[0]);
      setChainId(Number(network.chainId));

      // Load contract info
      await loadContractInfo(prov, Number(network.chainId));
      
      // Load balances
      await loadBalances(prov, accounts[0], Number(network.chainId));
    } catch (err) {
      console.error('Failed to connect wallet:', err);
      setError(err.message);
    } finally {
      setIsConnecting(false);
    }
  };

  // Load contract information
  const loadContractInfo = async (prov, chainIdNum) => {
    try {
      const orchAddr = getOrchestratorAddress(chainIdNum);
      if (!orchAddr) return;

      const ORCH_INFO_ABI = [
        { inputs: [], name: 'oceanMangaNFT', outputs: [{ type: 'address' }], stateMutability: 'view', type: 'function' },
        { inputs: [], name: 'lunaComicsFT', outputs: [{ type: 'address' }], stateMutability: 'view', type: 'function' },
        { inputs: [], name: 'creator', outputs: [{ type: 'address' }], stateMutability: 'view', type: 'function' },
        { inputs: [], name: 'charityFund', outputs: [{ type: 'address' }], stateMutability: 'view', type: 'function' },
        { inputs: [], name: 'nextTokenId', outputs: [{ type: 'uint256' }], stateMutability: 'view', type: 'function' }
      ];
      
      const orch = new ethers.Contract(orchAddr, ORCH_INFO_ABI, prov);
      const [nftAddr, ftAddr, creator, charity, nextTokenId] = await Promise.all([
        orch.oceanMangaNFT(),
        orch.lunaComicsFT(),
        orch.creator(),
        orch.charityFund(),
        orch.nextTokenId()
      ]);

      setContractInfo({
        orchestrator: orchAddr,
        nft: nftAddr,
        ft: ftAddr,
        creator,
        charity,
        nextTokenId: nextTokenId.toString()
      });
    } catch (err) {
      console.error('Failed to load contract info:', err);
    }
  };

  // Load user balances
  const loadBalances = async (prov, userAddr, chainIdNum) => {
    try {
      const orchAddr = getOrchestratorAddress(chainIdNum);
      if (!orchAddr) return;

      const ORCH_ABI = [
        { inputs: [], name: 'lunaComicsFT', outputs: [{ type: 'address' }], stateMutability: 'view', type: 'function' }
      ];
      const ERC20_ABI = [
        { inputs: [{ name: 'account', type: 'address' }], name: 'balanceOf', outputs: [{ type: 'uint256' }], stateMutability: 'view', type: 'function' },
        { inputs: [], name: 'decimals', outputs: [{ type: 'uint8' }], stateMutability: 'view', type: 'function' },
        { inputs: [], name: 'symbol', outputs: [{ type: 'string' }], stateMutability: 'view', type: 'function' }
      ];

      const orch = new ethers.Contract(orchAddr, ORCH_ABI, prov);
      const ftAddr = await orch.lunaComicsFT();
      const ftContract = new ethers.Contract(ftAddr, ERC20_ABI, prov);

      const [balance, decimals, symbol] = await Promise.all([
        ftContract.balanceOf(userAddr),
        ftContract.decimals().catch(() => 18),
        ftContract.symbol().catch(() => 'FT')
      ]);

      setFtBalance({
        raw: balance.toString(),
        formatted: ethers.formatUnits(balance, decimals),
        symbol,
        decimals
      });
    } catch (err) {
      console.error('Failed to load balances:', err);
    }
  };

  // Estimate FT from ETH
  useEffect(() => {
    let cancelled = false;

    (async () => {
      if (!provider || !ethValue || Number(ethValue) <= 0 || chainId !== DEFAULT_CHAIN_ID) {
        setEstimate(null);
        return;
      }

      try {
        setEstimating(true);
        const orchAddr = getOrchestratorAddress(chainId);
        if (!orchAddr) return;

        const ORCH_MIN_ABI = [
          { inputs: [], name: 'lunaComicsFT', outputs: [{ type: 'address' }], stateMutability: 'view', type: 'function' }
        ];
        const orch = new ethers.Contract(orchAddr, ORCH_MIN_ABI, provider);
        const ftAddr = await orch.lunaComicsFT();
        const valueWei = ethers.parseEther(String(ethValue));
        
        const est = await estimateFtFromEth(provider, ftAddr, valueWei);
        if (!cancelled && est) {
          setEstimate(est);
        }
      } catch (e) {
        console.error('Estimation error:', e);
        if (!cancelled) setEstimate(null);
      } finally {
        if (!cancelled) setEstimating(false);
      }
    })();

    return () => { cancelled = true; };
  }, [provider, ethValue, chainId]);

  // Handle mint
  const handleMint = async (e) => {
    e.preventDefault();
    
    if (!provider || !account) {
      setError('Please connect your wallet first');
      return;
    }

    if (chainId !== DEFAULT_CHAIN_ID) {
      setError(`Please switch to Base network (Chain ID: ${DEFAULT_CHAIN_ID})`);
      return;
    }

    setStatus('preparing');
    setError(null);
    setResult(null);

    try {
      // Generate token URI
      const { tokenURI } = await generateTokenURI({
        title: title || 'Untitled NFT',
        description: description || 'Minted via APP Ethernum',
        imageCID: imageCID || '',
        attributes: []
      }, { mode: 'data' });

      setStatus('sending');

      // Mint via orchestrator
      const res = await mintPhotoCombo({
        provider,
        tokenURI,
        ethValue,
        chainIdExpected: DEFAULT_CHAIN_ID,
      });

      setResult(res);
      setStatus('confirmed');
      
      // Reload balances
      await loadBalances(provider, account, chainId);
      await loadContractInfo(provider, chainId);

      // Clear form
      setTitle('');
      setDescription('');
      setImageCID('');
    } catch (e) {
      console.error('Mint error:', e);
      setError(e?.message || String(e));
      setStatus('error');
    }
  };

  // Switch to Base network
  const switchToBase = async () => {
    if (!window.ethereum) return;

    try {
      await window.ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: '0x2105' }], // Base = 8453 = 0x2105
      });
    } catch (switchError) {
      // Chain not added, try to add it
      if (switchError.code === 4902) {
        try {
          await window.ethereum.request({
            method: 'wallet_addEthereumChain',
            params: [{
              chainId: '0x2105',
              chainName: 'Base',
              nativeCurrency: { name: 'Ethereum', symbol: 'ETH', decimals: 18 },
              rpcUrls: ['https://mainnet.base.org'],
              blockExplorerUrls: ['https://basescan.org'],
            }],
          });
        } catch (addError) {
          console.error('Failed to add Base network:', addError);
        }
      }
    }
  };

  const canSubmit = Number(ethValue) > 0 && (title || description || imageCID);

  return (
    <div className="ethernum-app">
      <div className="ethernum-header">
        <h1>🌊 APP Ethernum</h1>
        <p className="ethernum-subtitle">Mint NFTs and FTs via Orchestrator Smart Contract</p>
      </div>

      {/* Wallet Connection */}
      <div className="wallet-section">
        {!account ? (
          <button 
            className="connect-btn" 
            onClick={connectWallet}
            disabled={isConnecting}
          >
            {isConnecting ? 'Connecting...' : '🔗 Connect Wallet'}
          </button>
        ) : (
          <div className="wallet-info">
            <div className="account-badge">
              <span className="label">Connected:</span>
              <span className="address">{account.slice(0, 6)}...{account.slice(-4)}</span>
            </div>
            {chainId !== DEFAULT_CHAIN_ID && (
              <button className="switch-network-btn" onClick={switchToBase}>
                ⚠️ Switch to Base Network
              </button>
            )}
            {chainId === DEFAULT_CHAIN_ID && (
              <span className="network-badge">✅ Base Network</span>
            )}
          </div>
        )}
      </div>

      {/* Balances Display */}
      {account && ftBalance && (
        <div className="balances-section">
          <h3>💰 Your Balances</h3>
          <div className="balance-item">
            <span className="balance-label">FT Tokens ({ftBalance.symbol}):</span>
            <span className="balance-value">{parseFloat(ftBalance.formatted).toFixed(4)}</span>
          </div>
          {contractInfo && (
            <div className="balance-item">
              <span className="balance-label">Next NFT ID:</span>
              <span className="balance-value">#{contractInfo.nextTokenId}</span>
            </div>
          )}
        </div>
      )}

      {/* Contract Info */}
      {contractInfo && (
        <div className="contract-info-section">
          <h3>📜 Contract Information</h3>
          <div className="contract-detail">
            <span className="label">Orchestrator:</span>
            <a 
              href={`https://basescan.org/address/${contractInfo.orchestrator}`}
              target="_blank"
              rel="noopener noreferrer"
              className="contract-link"
            >
              {contractInfo.orchestrator.slice(0, 6)}...{contractInfo.orchestrator.slice(-4)}
            </a>
          </div>
          <div className="contract-detail">
            <span className="label">NFT Contract:</span>
            <a 
              href={`https://basescan.org/address/${contractInfo.nft}`}
              target="_blank"
              rel="noopener noreferrer"
              className="contract-link"
            >
              {contractInfo.nft.slice(0, 6)}...{contractInfo.nft.slice(-4)}
            </a>
          </div>
          <div className="contract-detail">
            <span className="label">FT Contract:</span>
            <a 
              href={`https://basescan.org/address/${contractInfo.ft}`}
              target="_blank"
              rel="noopener noreferrer"
              className="contract-link"
            >
              {contractInfo.ft.slice(0, 6)}...{contractInfo.ft.slice(-4)}
            </a>
          </div>
        </div>
      )}

      {/* Minting Form */}
      {account && chainId === DEFAULT_CHAIN_ID && (
        <div className="mint-section">
          <h2>🎨 Mint NFT + FT Combo</h2>
          <form onSubmit={handleMint} className="mint-form">
            <div className="form-group">
              <label htmlFor="title">Title</label>
              <input
                id="title"
                type="text"
                value={title}
                onChange={e => setTitle(e.target.value)}
                placeholder="My Awesome NFT"
                className="form-input"
              />
            </div>

            <div className="form-group">
              <label htmlFor="description">Description</label>
              <textarea
                id="description"
                value={description}
                onChange={e => setDescription(e.target.value)}
                placeholder="Describe your NFT..."
                className="form-textarea"
                rows={3}
              />
            </div>

            <div className="form-group">
              <label htmlFor="imageCID">Image CID (IPFS)</label>
              <input
                id="imageCID"
                type="text"
                value={imageCID}
                onChange={e => setImageCID(e.target.value)}
                placeholder="Qm... (optional)"
                className="form-input"
              />
            </div>

            <div className="form-group">
              <label htmlFor="ethValue">ETH Amount</label>
              <input
                id="ethValue"
                type="number"
                step="0.0001"
                min="0.0001"
                value={ethValue}
                onChange={e => setEthValue(e.target.value)}
                className="form-input"
              />
            </div>

            {/* FT Estimate */}
            {estimating && <p className="estimating">⏳ Estimating FT rewards...</p>}
            {estimate && (
              <div className="estimate-box">
                <h4>📊 Estimated FT Distribution</h4>
                <div className="estimate-row">
                  <span>Gross FT:</span>
                  <span className="estimate-value">{estimate.formatted.gross}</span>
                </div>
                <div className="estimate-row highlight">
                  <span>Net to You:</span>
                  <span className="estimate-value">{estimate.formatted.net}</span>
                </div>
                <div className="estimate-row">
                  <span>Creator Fee (2.5%):</span>
                  <span className="estimate-value">{estimate.formatted.creator}</span>
                </div>
                <div className="estimate-row">
                  <span>Charity Fee (2.5%):</span>
                  <span className="estimate-value">{estimate.formatted.charity}</span>
                </div>
              </div>
            )}

            <button
              type="submit"
              className="mint-btn"
              disabled={!canSubmit || status === 'sending' || status === 'preparing'}
            >
              {status === 'preparing' && '⏳ Preparing...'}
              {status === 'sending' && '🚀 Minting...'}
              {status !== 'preparing' && status !== 'sending' && '✨ Mint NFT + FT'}
            </button>
          </form>

          {/* Status Messages */}
          {status === 'error' && error && (
            <div className="error-box">
              <strong>❌ Error:</strong> {error}
            </div>
          )}

          {status === 'confirmed' && result && (
            <div className="success-box">
              <h3>✅ Mint Successful!</h3>
              <div className="result-detail">
                <span className="label">Transaction:</span>
                <a
                  href={`https://basescan.org/tx/${result.txHash}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="tx-link"
                >
                  View on BaseScan
                </a>
              </div>
              <div className="result-detail">
                <span className="label">NFT ID:</span>
                <span className="value">#{result.tokenId}</span>
              </div>
              <div className="result-detail">
                <span className="label">FT Received:</span>
                <span className="value highlight">{result.netFormatted}</span>
              </div>
              <div className="result-detail">
                <span className="label">Creator Fee:</span>
                <span className="value">{result.creatorFormatted} ({result.royaltiesPct.creator}%)</span>
              </div>
              <div className="result-detail">
                <span className="label">Charity Fee:</span>
                <span className="value">{result.charityFormatted} ({result.royaltiesPct.charity}%)</span>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Footer */}
      <div className="ethernum-footer">
        <p>🌟 Powered by Solidary System on Base Network</p>
        <p className="fee-info">Fee Distribution: 2.5% Creator + 2.5% Charity</p>
      </div>
    </div>
  );
}
