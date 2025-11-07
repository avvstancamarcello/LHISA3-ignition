import { useState, useEffect } from 'react';
import { MetaMaskSDK } from '@metamask/sdk';

export default function MetaMaskSDKWallet() {
  const [sdk, setSDK] = useState(null);
  const [account, setAccount] = useState(null);
  const [chainId, setChainId] = useState(null);
  const [isConnected, setIsConnected] = useState(false);
  const [isConnecting, setIsConnecting] = useState(false);

  useEffect(() => {
    initializeSDK();
  }, []);

  const initializeSDK = async () => {
    try {
      // Check if MetaMask is actually available (Brave browser fix)
      const isMetaMaskAvailable = window.ethereum && (
        window.ethereum.isMetaMask || 
        window.ethereum.providers?.some(p => p.isMetaMask) ||
        // Check for MetaMask in Brave
        (navigator.userAgent.includes('Brave') && window.ethereum)
      );

      console.log('🔍 MetaMask detection:', {
        hasEthereum: !!window.ethereum,
        isMetaMask: window.ethereum?.isMetaMask,
        providers: window.ethereum?.providers?.length,
        isBrave: navigator.userAgent.includes('Brave'),
        isMetaMaskAvailable
      });

      const MMSDK = new MetaMaskSDK({
        dappMetadata: {
          name: "LunaComics Ethernum",
          url: window.location.origin,
        },
        infuraAPIKey: import.meta.env.VITE_METAMASK_API_KEY,
        // Disable install modal if MetaMask is detected
        modals: {
          install: ({ link }) => {
            return new Promise((resolve) => {
              if (isMetaMaskAvailable) {
                console.log('✅ MetaMask detected, skipping install modal');
                resolve();
                return;
              }
              
              const modal = document.createElement('div');
              modal.innerHTML = `
                <div style="position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.8); display: flex; align-items: center; justify-content: center; z-index: 10000;">
                  <div style="background: white; padding: 20px; border-radius: 8px; text-align: center;">
                    <h3>🦊 MetaMask Detection Issue</h3>
                    <p>MetaMask might be installed but not detected properly.</p>
                    <p><small>This can happen in Brave browser with wallet conflicts.</small></p>
                    <button onclick="this.parentElement.parentElement.parentElement.remove(); location.reload();" style="background: #4CAF50; color: white; padding: 10px 20px; border: none; border-radius: 5px; margin: 5px; cursor: pointer;">🔄 Refresh & Retry</button>
                    <a href="${link}" target="_blank" style="display: inline-block; background: #f6851b; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; margin: 5px;">🦊 Install/Update MetaMask</a>
                    <button onclick="this.parentElement.parentElement.parentElement.remove(); ${resolve}()" style="display: block; width: 100%; margin-top: 10px; padding: 10px; background: #ccc; border: none; border-radius: 5px; cursor: pointer;">❌ Close</button>
                  </div>
                </div>
              `;
              document.body.appendChild(modal);
            });
          },
        },
      });

      setSDK(MMSDK);

      // Listen for connection events
      MMSDK.on('connect', (connectInfo) => {
        console.log('🔗 MetaMask SDK connected:', connectInfo);
        checkConnection();
      });

      MMSDK.on('disconnect', (error) => {
        console.log('❌ MetaMask SDK disconnected:', error);
        setAccount(null);
        setChainId(null);
        setIsConnected(false);
      });

      // Check if already connected (removed MMSDK.isConnected() as it's not available)
      checkConnection(MMSDK);

    } catch (error) {
      console.error('Failed to initialize MetaMask SDK:', error);
    }
  };

  const checkConnection = async () => {
    if (!sdk) return;

    try {
      const ethereum = sdk.getProvider();
      if (!ethereum) return;

      const accounts = await ethereum.request({
        method: 'eth_accounts',
      });

      if (accounts.length > 0) {
        const chainId = await ethereum.request({
          method: 'eth_chainId',
        });

        setAccount(accounts[0]);
        setChainId(parseInt(chainId, 16));
        setIsConnected(true);

        // Listen for account/chain changes
        ethereum.on('accountsChanged', (accounts) => {
          if (accounts.length > 0) {
            setAccount(accounts[0]);
          } else {
            setAccount(null);
            setIsConnected(false);
          }
        });

        ethereum.on('chainChanged', (chainId) => {
          setChainId(parseInt(chainId, 16));
        });
      }
    } catch (error) {
      console.error('Failed to check connection:', error);
    }
  };

  const connectWallet = async () => {
    setIsConnecting(true);
    try {
      // Try direct connection first (better for Brave)
      if (window.ethereum && (window.ethereum.isMetaMask || navigator.userAgent.includes('Brave'))) {
        console.log('🔌 Using direct MetaMask connection (Brave-friendly)...');
        
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

          console.log('✅ Connected directly (bypassing SDK):', accounts[0]);
          alert(`🎉 MetaMask Connected!\n\nAccount: ${accounts[0]}\nChain: ${parseInt(chainId, 16)}\n\n🦊 Connection method: Direct (Brave-optimized)`);
          return;
        }
      }

      // Fallback to SDK if direct fails
      if (!sdk) {
        alert('MetaMask SDK not initialized and direct connection failed');
        return;
      }

      console.log('🔌 Fallback to MetaMask SDK...');
      
      const ethereum = sdk.getProvider();
      const accounts = await ethereum.request({
        method: 'eth_requestAccounts',
      });

      if (accounts.length > 0) {
        const chainId = await ethereum.request({
          method: 'eth_chainId',
        });

        setAccount(accounts[0]);
        setChainId(parseInt(chainId, 16));
        setIsConnected(true);

        console.log('✅ Connected via MetaMask SDK:', accounts[0]);
        alert(`🎉 MetaMask SDK Connected!\n\nAccount: ${accounts[0]}\nChain: ${parseInt(chainId, 16)}`);
      }
    } catch (error) {
      console.error('Connection failed:', error);
      alert(`❌ Connection failed:\n\n${error.message}\n\n💡 Try using the "Direct MetaMask Connection" above instead.`);
    } finally {
      setIsConnecting(false);
    }
  };

  const switchToBase = async () => {
    if (!sdk) return;

    try {
      const ethereum = sdk.getProvider();
      await ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: '0x2105' }], // Base mainnet
      });
    } catch (error) {
      if (error.code === 4902) {
        // Chain not added, add it
        try {
          const ethereum = sdk.getProvider();
          await ethereum.request({
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

  const disconnect = async () => {
    if (sdk) {
      try {
        await sdk.disconnect();
        setAccount(null);
        setChainId(null);
        setIsConnected(false);
      } catch (error) {
        console.error('Disconnect failed:', error);
      }
    }
  };

  if (isConnected) {
    return (
      <div className="metamask-sdk-connected" style={{
        background: '#f0fff4',
        border: '2px solid #48bb78',
        borderRadius: '8px',
        padding: '16px',
        margin: '16px 0'
      }}>
        <h3>🦊 MetaMask SDK Connected</h3>
        <p><strong>Account:</strong> {account?.slice(0, 6)}...{account?.slice(-4)}</p>
        <p><strong>Chain ID:</strong> {chainId}</p>
        <p><strong>Network:</strong> {chainId === 8453 ? '✅ Base' : chainId === 1 ? '⚠️ Ethereum' : `❓ Unknown (${chainId})`}</p>
        <p><strong>SDK Status:</strong> ✅ Active</p>
        
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

  return (
    <div className="metamask-sdk-connector" style={{
      background: '#fff5f5',
      border: '2px solid #f6851b',
      borderRadius: '8px',
      padding: '16px',
      margin: '16px 0'
    }}>
      <h3>🦊 MetaMask SDK Connection</h3>
      <p><small>Enhanced MetaMask integration with official SDK</small></p>
      
      <button
        onClick={connectWallet}
        disabled={isConnecting}
        style={{
          background: isConnecting ? '#a0aec0' : '#f6851b',
          color: 'white',
          border: 'none',
          padding: '12px 24px',
          borderRadius: '8px',
          fontSize: '16px',
          fontWeight: 'bold',
          cursor: isConnecting ? 'not-allowed' : 'pointer',
          width: '100%'
        }}
      >
        {isConnecting ? '🔄 Connecting...' : 
         navigator.userAgent.includes('Brave') ? '🦊 Connect MetaMask (Brave-Optimized)' :
         !sdk ? '⏳ Initializing SDK...' : 
         '🦊 Connect with MetaMask SDK'}
      </button>

      <div style={{ marginTop: '10px', fontSize: '12px', color: '#666' }}>
        <p>✅ Uses official MetaMask SDK</p>
        <p>✅ Better mobile support</p>
        <p>✅ Enhanced error handling</p>
        <p>✅ Deep linking support</p>
        {navigator.userAgent.includes('Brave') && (
          <>
            <p style={{color: '#f6851b', fontWeight: 'bold'}}>🛡️ Brave browser detected</p>
            <p style={{color: '#f6851b'}}>🔧 Using Brave-optimized connection</p>
          </>
        )}
      </div>
    </div>
  );
}