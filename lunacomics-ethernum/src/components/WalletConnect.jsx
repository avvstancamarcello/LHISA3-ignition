import { useAccount, useConnect, useDisconnect } from 'wagmi';

export default function WalletConnect() {
  const { address, isConnected } = useAccount();
  const { connectors, connect, status, error } = useConnect();
  const { disconnect } = useDisconnect();

  const handleConnect = async (connector) => {
    try {
      console.log('🔌 Attempting to connect with:', connector.name);
      console.log('🔍 Connector details:', connector);
      
      // Check if MetaMask is installed
      if (connector.name === 'MetaMask' && !window.ethereum?.isMetaMask) {
        alert('❌ MetaMask not detected!\n\nPlease:\n1. Install MetaMask extension\n2. Refresh the page\n3. Try connecting again');
        return;
      }

      await connect({ connector });
      console.log('✅ Connection successful');
      
    } catch (err) {
      console.error('❌ Connection failed:', err);
      
      if (err.message.includes('User rejected')) {
        alert('👤 Connection Cancelled\n\nYou cancelled the connection request.\nTry again and approve the connection in your wallet.');
      } else if (err.message.includes('Already processing')) {
        alert('⏳ Already Connecting\n\nA connection is already in progress.\nCheck your wallet for approval prompts.');
      } else {
        alert(`❌ Connection Error\n\n${err.message}\n\nTry:\n1. Refreshing the page\n2. Checking wallet is unlocked\n3. Using a different wallet`);
      }
    }
  };

  if (isConnected) {
    return (
      <div className="wallet-connected">
        <p>✅ Connected to {address?.slice(0, 6)}...{address?.slice(-4)}</p>
        <button onClick={() => disconnect()} className="disconnect-btn">
          Disconnect
        </button>
      </div>
    );
  }

  return (
    <div className="wallet-connect">
      <h3>Connect Wallet</h3>
      <div className="connector-debug">
        <p><small>Available connectors: {connectors.length}</small></p>
        <p><small>MetaMask detected: {window.ethereum?.isMetaMask ? '✅' : '❌'}</small></p>
      </div>
      
      {connectors.map((connector) => (
        <button
          key={connector.uid}
          onClick={() => handleConnect(connector)}
          disabled={status === 'pending'}
          className="wallet-btn"
          style={{
            opacity: status === 'pending' ? 0.6 : 1,
            cursor: status === 'pending' ? 'not-allowed' : 'pointer'
          }}
        >
          {status === 'pending' ? '🔄 Connecting...' : connector.name}
        </button>
      ))}
      
      {error && (
        <div className="error-info">
          <p><strong>❌ Error:</strong> {error.message}</p>
          <details>
            <summary>Debug Info</summary>
            <pre>{JSON.stringify(error, null, 2)}</pre>
          </details>
        </div>
      )}

      {/* Direct MetaMask Connection (Bypass Wagmi) */}
      <div className="direct-test">
        <h4>🔧 Direct MetaMask Connection</h4>
        <p><small>If wagmi connectors fail, use this direct connection:</small></p>
        <button
          onClick={async () => {
            try {
              if (!window.ethereum) {
                alert('❌ No Ethereum provider found');
                return;
              }
              
              console.log('🔍 Connecting directly to MetaMask...');
              const accounts = await window.ethereum.request({
                method: 'eth_requestAccounts',
              });
              
              if (accounts.length > 0) {
                // Force reload to trigger wagmi reconnection
                console.log('✅ Direct connection established, reloading...');
                window.location.reload();
              }
              
            } catch (err) {
              console.error('Direct connection failed:', err);
              alert(`❌ Direct connection failed:\n\n${err.message}`);
            }
          }}
          className="direct-connect-btn"
          style={{
            background: '#ff6b35',
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
          🚀 Connect MetaMask Directly (Bypass Wagmi)
        </button>
        
        <button
          onClick={async () => {
            try {
              if (!window.ethereum) {
                alert('❌ No Ethereum provider found');
                return;
              }
              
              console.log('🔍 Testing direct MetaMask connection...');
              const accounts = await window.ethereum.request({
                method: 'eth_requestAccounts',
              });
              
              alert(`✅ Direct connection successful!\n\nAccount: ${accounts[0]}\n\nClick "Connect MetaMask Directly" above to use this connection.`);
              
            } catch (err) {
              console.error('Direct connection failed:', err);
              alert(`❌ Direct connection failed:\n\n${err.message}`);
            }
          }}
          className="test-btn"
          style={{
            background: '#e2e8f0',
            color: '#4a5568',
            border: '1px solid #cbd5e0',
            padding: '8px 16px',
            borderRadius: '6px',
            fontSize: '14px',
            cursor: 'pointer',
            width: '100%',
            marginTop: '8px'
          }}
        >
          🧪 Test MetaMask Connection
        </button>
      </div>
    </div>
  );
}