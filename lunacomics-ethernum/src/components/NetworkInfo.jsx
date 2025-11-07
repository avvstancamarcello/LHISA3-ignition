import { useAccount, useChainId, useSwitchChain } from 'wagmi';
import { getOrchestratorAddress, CHAINS } from '../config/contracts';

export default function NetworkInfo() {
  const { isConnected } = useAccount();
  const chainId = useChainId();
  const { switchChain, isPending } = useSwitchChain();

  if (!isConnected) {
    return (
      <div className="network-info">
        <p>🔌 Connect wallet to see network info</p>
      </div>
    );
  }

  const chainConfig = CHAINS[chainId];
  const orchestratorAddress = getOrchestratorAddress(chainId);

  const handleSwitchToBase = async () => {
    try {
      console.log('🔄 Attempting to switch to Base network...');
      console.log('Current chainId from wagmi:', chainId);
      
      // First, try wagmi switch
      await switchChain({ chainId: 8453 });
      console.log('✅ Successfully switched to Base network via wagmi');
      
      // Wait a bit and refresh
      setTimeout(() => {
        window.location.reload();
      }, 1000);
      
    } catch (error) {
      console.error('❌ Failed to switch via wagmi:', error);
      
      // Fallback: Direct MetaMask interaction
      if (window.ethereum) {
        try {
          console.log('🔄 Trying direct MetaMask switch...');
          
          // First try to switch to existing Base network
          await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: '0x2105' }], // 8453 in hex
          });
          console.log('✅ Switched via direct MetaMask call');
          
        } catch (switchError) {
          console.log('⚠️ Switch failed, trying to add Base network...');
          
          // If switch fails, try to add the network
          try {
            await window.ethereum.request({
              method: 'wallet_addEthereumChain',
              params: [{
                chainId: '0x2105', // 8453 in hex
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
            console.log('✅ Base network added successfully');
            
          } catch (addError) {
            console.error('❌ Failed to add Base network:', addError);
            alert(`❌ Network Switch Failed!\n\nPlease add Base network manually in MetaMask:\n\n• Chain ID: 8453\n• RPC URL: https://mainnet.base.org\n• Currency: ETH\n• Explorer: https://basescan.org\n\nThen refresh the page.`);
          }
        }
      } else {
        alert('❌ MetaMask not detected!\n\nPlease install MetaMask extension.');
      }
    }
  };

  return (
    <div className="network-info">
      <h3>🌐 Network Information</h3>
      
      <div className="network-details">
        <p><strong>Network:</strong> {chainConfig?.name || `Unknown (${chainId})`}</p>
        <p><strong>Chain ID:</strong> {chainId}</p>
        
        {chainId === 8453 && (
          <>
            <p><strong>✅ OceanManga Orchestrator:</strong></p>
            <p className="contract-address">
              <code>{orchestratorAddress}</code>
              <a 
                href={`https://basescan.org/address/${orchestratorAddress}`}
                target="_blank" 
                rel="noopener noreferrer"
                className="explorer-link"
              >
                📊 View on BaseScan
              </a>
            </p>
            <p className="status">🚀 <strong>Ready for minting!</strong></p>
            {/* Debug info */}
            <div className="debug-info">
              <p><small>Debug: Wagmi Chain ID: {chainId}</small></p>
            </div>
          </>
        )}
        
        {chainId === 137 && (
          <>
            <p><strong>⏳ Polygon Network:</strong></p>
            <div className="status warning">
              <p>Orchestrator deployment pending due to network congestion</p>
              <p>💡 Switch to Base network for optimal experience</p>
            </div>
            <div className="cost-comparison">
              <p><strong>💰 Cost Comparison:</strong></p>
              <p>• Polygon: ~$2-5 per mint (high congestion)</p>
              <p>• Base: ~$0.0002 per mint (ultra-low fees)</p>
              <p>• <strong>Save 99.99%</strong> switching to Base! 🚀</p>
            </div>
            <button 
              onClick={handleSwitchToBase}
              disabled={isPending}
              className="switch-button"
            >
              {isPending ? '🔄 Switching...' : '🚀 Switch to Base Network'}
            </button>
          </>
        )}
        
        {chainId !== 8453 && chainId !== 137 && (
          <>
            <div className="status warning">
              ⚠️ Please switch to Base network for OceanManga minting
            </div>
            <button 
              onClick={handleSwitchToBase}
              disabled={isPending}
              className="switch-button"
            >
              {isPending ? '🔄 Switching...' : '🚀 Switch to Base Network'}
            </button>
          </>
        )}

        {/* Always show switch button for debugging */}
        <div className="debug-section">
          <h4>🔧 Network Debug & Controls</h4>
          <p><strong>Detected Chain ID:</strong> {chainId}</p>
          <p><strong>Expected:</strong> 8453 (Base)</p>
          {chainId !== 8453 && (
            <div className="status warning">
              ⚠️ Chain ID mismatch detected!
            </div>
          )}
          <button 
            onClick={handleSwitchToBase}
            disabled={isPending}
            className="switch-button"
            style={{marginTop: '8px'}}
          >
            {isPending ? '🔄 Force Switching to Base...' : '🚀 Force Switch to Base Network'}
          </button>
        </div>
      </div>

      <style jsx>{`
        .network-info {
          background: #f5f5f5;
          border: 1px solid #ddd;
          border-radius: 8px;
          padding: 16px;
          margin: 16px 0;
        }
        
        .network-details {
          display: flex;
          flex-direction: column;
          gap: 8px;
        }
        
        .contract-address {
          display: flex;
          align-items: center;
          gap: 8px;
          flex-wrap: wrap;
        }
        
        .contract-address code {
          background: #e0e0e0;
          padding: 4px 8px;
          border-radius: 4px;
          font-family: monospace;
          font-size: 12px;
          word-break: break-all;
        }
        
        .explorer-link {
          color: #0066cc;
          text-decoration: none;
          font-size: 14px;
        }
        
        .explorer-link:hover {
          text-decoration: underline;
        }
        
        .status {
          font-weight: bold;
          padding: 8px;
          border-radius: 4px;
          background: #e8f5e8;
          border: 1px solid #4caf50;
        }
        
        .status.warning {
          background: #fff3cd;
          border: 1px solid #ffc107;
          color: #856404;
        }
        
        .switch-button {
          background: linear-gradient(45deg, #0052ff, #0066ff);
          color: white;
          border: none;
          padding: 12px 24px;
          border-radius: 8px;
          font-size: 16px;
          font-weight: bold;
          cursor: pointer;
          transition: all 0.3s ease;
          margin-top: 12px;
          box-shadow: 0 2px 8px rgba(0, 82, 255, 0.3);
        }
        
        .switch-button:hover:not(:disabled) {
          background: linear-gradient(45deg, #0066ff, #007fff);
          transform: translateY(-2px);
          box-shadow: 0 4px 12px rgba(0, 82, 255, 0.4);
        }
        
        .switch-button:disabled {
          opacity: 0.6;
          cursor: not-allowed;
          transform: none;
        }
        
        .switch-button:active {
          transform: translateY(0);
        }
        
        .cost-comparison {
          background: #f8f9fa;
          border: 1px solid #dee2e6;
          border-radius: 6px;
          padding: 12px;
          margin: 12px 0;
          font-size: 14px;
        }
        
        .cost-comparison p {
          margin: 4px 0;
        }
        
        .debug-section {
          background: #fff5f5;
          border: 1px solid #fed7d7;
          border-radius: 6px;
          padding: 12px;
          margin: 16px 0;
        }
        
        .debug-section h4 {
          margin: 0 0 8px 0;
          color: #c53030;
        }
        
        .debug-info {
          background: #f7fafc;
          border: 1px solid #e2e8f0;
          border-radius: 4px;
          padding: 8px;
          margin: 8px 0;
          font-family: monospace;
        }
      `}</style>
    </div>
  );
}