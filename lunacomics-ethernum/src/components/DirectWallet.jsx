import { useState, useEffect } from 'react';

export default function DirectWallet() {
  const [account, setAccount] = useState(null);
  const [chainId, setChainId] = useState(null);
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    // Check if already connected on load
    checkConnection();
    
    // Listen for account changes
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
        
        console.log('🔍 Direct wallet connection detected:', accounts[0]);
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
    // Reload to ensure app state is fresh
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
        // Chain not added, add it
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

  const disconnect = () => {
    setAccount(null);
    setChainId(null);
    setIsConnected(false);
    // Note: MetaMask doesn't have a programmatic disconnect
    // User needs to disconnect manually from MetaMask
    alert('Please disconnect manually from MetaMask extension');
  };

  if (isConnected) {
    return (
      <div className="direct-wallet-connected" style={{
        background: '#f0fff4',
        border: '2px solid #48bb78',
        borderRadius: '8px',
        padding: '16px',
        margin: '16px 0'
      }}>
        <h3>🎉 Direct Wallet Connected</h3>
        <p><strong>Account:</strong> {account?.slice(0, 6)}...{account?.slice(-4)}</p>
        <p><strong>Chain ID:</strong> {chainId}</p>
        <p><strong>Network:</strong> {chainId === 8453 ? '✅ Base' : chainId === 1 ? '⚠️ Ethereum' : `❓ Unknown (${chainId})`}</p>
        
        {chainId !== 8453 && (
          <button 
            onClick={switchToBase}
            style={{
              background: '#3182ce',
              color: 'white',
              border: 'none',
              padding: '8px 16px',
              borderRadius: '6px',
              cursor: 'pointer',
              marginRight: '8px'
            }}
          >
            🚀 Switch to Base
          </button>
        )}
        
        <button 
          onClick={disconnect}
          style={{
            background: '#e53e3e',
            color: 'white',
            border: 'none',
            padding: '8px 16px',
            borderRadius: '6px',
            cursor: 'pointer'
          }}
        >
          Disconnect
        </button>
      </div>
    );
  }

  return null;
}