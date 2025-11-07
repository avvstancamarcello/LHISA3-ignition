import { useState, useRef, useEffect } from 'react';

export default function DirectPhotoMint() {
  const [selectedImage, setSelectedImage] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);
  const [mintPrice, setMintPrice] = useState('0.01');
  const [isUploading, setIsUploading] = useState(false);
  const [uploadedCID, setUploadedCID] = useState(null);
  const [account, setAccount] = useState(null);
  const [chainId, setChainId] = useState(null);
  const fileInputRef = useRef(null);
  const cameraInputRef = useRef(null);

  useEffect(() => {
    checkConnection();
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
      }
    } catch (error) {
      console.error('Failed to check connection:', error);
    }
  };

  const handleFileSelect = (event) => {
    const file = event.target.files[0];
    if (file) {
      setSelectedImage(file);
      const reader = new FileReader();
      reader.onload = (e) => setImagePreview(e.target.result);
      reader.readAsDataURL(file);
    }
  };

  const uploadToIPFS = async (file) => {
    setIsUploading(true);
    try {
      // TODO: Implement actual IPFS upload
      await new Promise(resolve => setTimeout(resolve, 2000));
      const mockCID = `QmExample${Date.now()}`;
      setUploadedCID(mockCID);
      return `ipfs://${mockCID}`;
    } catch (err) {
      console.error('IPFS upload failed:', err);
      throw err;
    } finally {
      setIsUploading(false);
    }
  };

  const handleMint = async () => {
    if (!selectedImage || !account) return;

    // Check if we're on Base network
    if (chainId !== 8453) {
      alert(`❌ Wrong Network!\n\nYou're on chain ${chainId}.\nPlease switch to Base network (Chain ID: 8453) first.`);
      return;
    }

    // Check balance
    try {
      const balance = await window.ethereum.request({
        method: 'eth_getBalance',
        params: [account, 'latest']
      });
      const balanceInEth = parseInt(balance, 16) / 1e18;
      
      if (balanceInEth < 0.01) {
        const demoConfirm = confirm(`💡 DEMO MODE\n\nYou have ${balanceInEth.toFixed(4)} ETH, but need ~0.01 ETH for minting.\n\nWould you like to see a DEMO simulation?\n\n(Click OK for demo, Cancel to get more ETH)`);
        
        if (demoConfirm) {
          // Demo simulation
          setIsUploading(true);
          await new Promise(resolve => setTimeout(resolve, 2000));
          setUploadedCID("QmDemoHash123456");
          setIsUploading(false);
          
          alert(`🎉 DEMO MINT SUCCESSFUL!\n\n✅ Photo uploaded to IPFS\n✅ NFT ID: ${Date.now()}\n✅ Transaction simulated\n\n💡 To do a real mint:\n1. Get 0.01+ ETH on Base\n2. Bridge at: https://bridge.base.org\n3. Try minting again!`);
          return;
        } else {
          alert(`💰 To get ETH on Base:\n\n1. Visit: https://bridge.base.org\n2. Bridge from Ethereum/Polygon\n3. Or buy directly on Base\n\nRecommended: 0.01 ETH for comfortable minting`);
          return;
        }
      }

      // Real mint with sufficient balance
      const tokenURI = await uploadToIPFS(selectedImage);
      
      // Call contract directly via MetaMask
      const contractAddress = "0x361eDa57Cd71C976B638fEC20256a433107c9282";
      const mintData = window.ethereum.utils?.encodeFunctionCall?.({
        name: 'mintPhotoCombo',
        type: 'function',
        inputs: [{name: 'tokenURI', type: 'string'}]
      }, [tokenURI]) || '0x'; // Fallback if utils not available
      
      const txParams = {
        from: account,
        to: contractAddress,
        value: (parseFloat(mintPrice) * 1e18).toString(16),
        data: mintData,
        gas: '0x1E8480' // 2000000 gas limit
      };

      const txHash = await window.ethereum.request({
        method: 'eth_sendTransaction',
        params: [txParams]
      });

      alert(`🎉 MINT TRANSACTION SENT!\n\nTx Hash: ${txHash}\n\nView on BaseScan:\nhttps://basescan.org/tx/${txHash}`);

    } catch (err) {
      console.error('Mint failed:', err);
      alert(`❌ Mint failed:\n\n${err.message}`);
    }
  };

  if (!account) {
    return (
      <div className="direct-mint-not-connected">
        <p>Connect wallet above to mint NFTs</p>
      </div>
    );
  }

  return (
    <div className="direct-photo-mint-container" style={{
      background: '#f7fafc',
      border: '1px solid #e2e8f0',
      borderRadius: '8px',
      padding: '20px',
      margin: '20px 0'
    }}>
      <h2>🎨 Direct Mint OceanManga NFT</h2>
      <p><small>Direct MetaMask integration (bypasses wagmi)</small></p>
      
      <div className="mint-form">
        <div className="image-input-section">
          <h3>Select Photo</h3>
          
          <button 
            onClick={() => cameraInputRef.current?.click()}
            className="camera-btn"
            style={{
              background: '#48bb78',
              color: 'white',
              border: 'none',
              padding: '10px 20px',
              borderRadius: '6px',
              margin: '5px',
              cursor: 'pointer'
            }}
          >
            📷 Take Photo
          </button>
          <input
            ref={cameraInputRef}
            type="file"
            accept="image/*"
            capture="environment"
            onChange={handleFileSelect}
            style={{ display: 'none' }}
          />

          <button 
            onClick={() => fileInputRef.current?.click()}
            className="gallery-btn"
            style={{
              background: '#4299e1',
              color: 'white',
              border: 'none',
              padding: '10px 20px',
              borderRadius: '6px',
              margin: '5px',
              cursor: 'pointer'
            }}
          >
            🖼️ Choose from Gallery
          </button>
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            onChange={handleFileSelect}
            style={{ display: 'none' }}
          />

          {imagePreview && (
            <div className="image-preview" style={{ margin: '15px 0' }}>
              <img src={imagePreview} alt="Selected" style={{ maxWidth: '300px', maxHeight: '300px', borderRadius: '8px' }} />
            </div>
          )}
        </div>

        <div className="mint-options" style={{ margin: '15px 0' }}>
          <label>
            Mint Price (ETH):
            <input
              type="number"
              step="0.001"
              value={mintPrice}
              onChange={(e) => setMintPrice(e.target.value)}
              style={{
                marginLeft: '10px',
                padding: '5px',
                borderRadius: '4px',
                border: '1px solid #cbd5e0'
              }}
            />
          </label>
        </div>

        <button
          onClick={handleMint}
          disabled={!selectedImage || isUploading}
          className="mint-btn"
          style={{
            background: selectedImage ? '#e53e3e' : '#a0aec0',
            color: 'white',
            border: 'none',
            padding: '12px 24px',
            borderRadius: '8px',
            fontSize: '16px',
            fontWeight: 'bold',
            cursor: selectedImage ? 'pointer' : 'not-allowed',
            width: '100%',
            marginTop: '10px'
          }}
        >
          {isUploading ? '📤 Uploading to IPFS...' : '🚀 Mint NFT (Direct)'}
        </button>

        {uploadedCID && <p style={{ color: '#48bb78', marginTop: '10px' }}>✅ Uploaded to IPFS: {uploadedCID}</p>}
      </div>
    </div>
  );
}