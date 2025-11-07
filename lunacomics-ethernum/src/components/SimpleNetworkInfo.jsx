import { useState, useEffect } from 'react';

export default function SimpleNetworkInfo() {
  const [account, setAccount] = useState(null);
  const [chainId, setChainId] = useState(null);
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    checkConnection();
    
    if (window.ethereum) {
      window.ethereum.on('accountsChanged', handleAccountsChanged);
      window.ethereum.on('chainChanged', handleChainChanged);
    }

    return () => {
      if (window.ethereum) {
        window.ethereum.removeListener('accountsChanged', handleAccountsChanged);
        window.ethereum.removeListener('chainChanged', handleChainChanged);
      }
    };
  }, []);

  const checkConnection = async () => {
    try {
      if (!window.ethereum) return;
      
      const accounts = await window.ethereum.request({
        method: 'eth_accounts'
      });
      
      if (accounts.length > 0) {
        const chainId = await window.ethereum.request({
          method: 'eth_chainId'
        });
        
        setAccount(accounts[0]);
        setChainId(parseInt(chainId, 16));
        setIsConnected(true);
      }
    } catch (error) {
      console.error('Failed to check connection:', error);
    }
  };

  const handleAccountsChanged = (accounts) => {
    if (accounts.length > 0) {
      setAccount(accounts[0]);
      setIsConnected(true);
    } else {
      setAccount(null);
      setIsConnected(false);
    }
  };

  const handleChainChanged = (chainId) => {
    setChainId(parseInt(chainId, 16));
    window.location.reload();
  };

  const switchToBase = async () => {
    try {
      await window.ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: '0x2105' }], // Base mainnet
      });
    } catch (error) {
      if (error.code === 4902) {
        try {
          await window.ethereum.request({
            method: 'wallet_addEthereumChain',
            params: [{
              chainId: '0x2105',
              chainName: 'Base',
              nativeCurrency: {
                name: 'Ethereum',
                symbol: 'ETH',
                decimals: 18,
              },
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

  if (!isConnected) {
    return (
      <div style={{
        background: '#f7fafc',
        border: '1px solid #e2e8f0',
        borderRadius: '8px',
        padding: '16px',
        margin: '16px 0',
        textAlign: 'center'
      }}>
        <p>🔌 Connect wallet above to see network info</p>
      </div>
    );
  }

  return (
    <div style={{
      background: '#f7fafc',
      border: '1px solid #e2e8f0',
      borderRadius: '8px',
      padding: '16px',
      margin: '16px 0'
    }}>
      <h3>🌐 Network Information</h3>
      
      <div style={{ marginBottom: '12px' }}>
        <p><strong>Network:</strong> {chainId === 8453 ? 'Base' : chainId === 1 ? 'Ethereum' : chainId === 137 ? 'Polygon' : `Unknown (${chainId})`}</p>
        <p><strong>Chain ID:</strong> {chainId}</p>
        <p><strong>Account:</strong> {account?.slice(0, 6)}...{account?.slice(-4)}</p>
      </div>

      {chainId === 8453 && (
        <div style={{
          background: '#f0fff4',
          border: '1px solid #48bb78',
          borderRadius: '6px',
          padding: '12px',
          marginBottom: '12px'
        }}>
          <p><strong>✅ OceanManga Orchestrator:</strong></p>
          <p style={{ fontSize: '14px', fontFamily: 'monospace' }}>
            0x361eDa57Cd71C976B638fEC20256a433107c9282
          </p>
          <a 
            href="https://basescan.org/address/0x361eDa57Cd71C976B638fEC20256a433107c9282"
            target="_blank" 
            rel="noopener noreferrer"
            style={{ color: '#3182ce', textDecoration: 'none' }}
          >
            📊 View on BaseScan
          </a>
          <p style={{ color: '#48bb78', fontWeight: 'bold', marginTop: '8px' }}>
            🚀 Ready for minting!
          </p>
        </div>
      )}

      {chainId !== 8453 && (
        <div style={{
          background: '#fff3cd',
          border: '1px solid #ffc107',
          borderRadius: '6px',
          padding: '12px',
          marginBottom: '12px'
        }}>
          <p><strong>⚠️ Wrong Network</strong></p>
          <p>Please switch to Base network for optimal experience</p>
          <div style={{
            background: '#f8f9fa',
            border: '1px solid #dee2e6',
            borderRadius: '4px',
            padding: '8px',
            margin: '8px 0',
            fontSize: '12px'
          }}>
            <p><strong>💰 Cost Comparison:</strong></p>
            <p>• Current network: High gas fees</p>
            <p>• Base: ~$0.0002 per mint</p>
            <p>• <strong>Save 99.99%</strong> on Base! 🚀</p>
          </div>
          <button 
            onClick={switchToBase}
            style={{
              background: 'linear-gradient(45deg, #0052ff, #0066ff)',
              color: 'white',
              border: 'none',
              padding: '12px 24px',
              borderRadius: '8px',
              fontSize: '16px',
              fontWeight: 'bold',
              cursor: 'pointer',
              width: '100%',
              marginTop: '8px'
            }}
          >
            🚀 Switch to Base Network
          </button>
        </div>
      )}
    </div>
  );
}