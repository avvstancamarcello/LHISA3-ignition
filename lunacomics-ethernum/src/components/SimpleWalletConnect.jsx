import { useState, useEffect } from 'react'

export default function SimpleWalletConnect() {
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

  const connectWallet = async () => {
    try {
      if (!window.ethereum) {
        alert('❌ MetaMask not detected!\n\nPlease install MetaMask extension.');
        return;
      }

      const accounts = await window.ethereum.request({
        method: 'eth_requestAccounts',
      });

      if (accounts.length > 0) {
        const chainId = await window.ethereum.request({
          method: 'eth_chainId',
        });

        setAccount(accounts[0]);
        setChainId(parseInt(chainId, 16));
        setIsConnected(true);
      }
    } catch (error) {
      console.error('Connection failed:', error);
      alert(`❌ Connection failed:\n\n${error.message}`);
    }
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

  if (isConnected) {
    return (
      <div style={{
        background: '#f0fff4',
        border: '2px solid #48bb78',
        borderRadius: '8px',
        padding: '16px',
        margin: '16px 0'
      }}>
        <h3>✅ Wallet Connected (Error-Free)</h3>
        <p><strong>Account:</strong> {account?.slice(0, 6)}...{account?.slice(-4)}</p>
        <p><strong>Chain ID:</strong> {chainId}</p>
        <p><strong>Network:</strong> {chainId === 8453 ? '✅ Base' : chainId === 1 ? '⚠️ Ethereum' : `❓ Unknown (${chainId})`}</p>
        
        {chainId && chainId !== 8453 && (
          <button 
            onClick={switchToBase}
            style={{
              background: '#3182ce',
              color: 'white',
              border: 'none',
              padding: '8px 16px',
              borderRadius: '6px',
              cursor: 'pointer',
              marginTop: '8px'
            }}
          >
            🚀 Switch to Base
          </button>
        )}
      </div>
    );
  }

  return (
    <div style={{
      background: '#f7fafc',
      border: '2px solid #3182ce',
      borderRadius: '8px',
      padding: '16px',
      margin: '16px 0'
    }}>
      <h3>🔌 Simple Wallet Connection</h3>
      <p><small>Error-free MetaMask integration (no SDK dependencies)</small></p>
      
      <button
        onClick={connectWallet}
        style={{
          background: '#3182ce',
          color: 'white',
          border: 'none',
          padding: '12px 24px',
          borderRadius: '8px',
          fontSize: '16px',
          fontWeight: 'bold',
          cursor: 'pointer',
          width: '100%'
        }}
      >
        🦊 Connect MetaMask (Simple)
      </button>

      <div style={{ marginTop: '10px', fontSize: '12px', color: '#666' }}>
        <p>✅ No external dependencies</p>
        <p>✅ No SDK errors</p>
        <p>✅ Direct MetaMask integration</p>
        <p>🛡️ Brave browser compatible</p>
      </div>
    </div>
  );
}