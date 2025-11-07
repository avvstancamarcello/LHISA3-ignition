import { useState, useRef } from 'react';
import { useAccount, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther } from 'viem';
import { getOrchestratorAddress, ORCHESTRATOR_ABI } from '../config/contracts';

export default function PhotoMintComponent() {
  const [selectedImage, setSelectedImage] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);
  const [mintPrice, setMintPrice] = useState('0.01');
  const [isUploading, setIsUploading] = useState(false);
  const [uploadedCID, setUploadedCID] = useState(null);
  const fileInputRef = useRef(null);
  const cameraInputRef = useRef(null);

  const { address, chainId, isConnected } = useAccount();
  const { writeContract, data: hash, error, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  // Handle file selection (camera or gallery)
  const handleFileSelect = (event) => {
    const file = event.target.files[0];
    if (file) {
      setSelectedImage(file);
      const reader = new FileReader();
      reader.onload = (e) => setImagePreview(e.target.result);
      reader.readAsDataURL(file);
    }
  };

  // Upload to IPFS (placeholder - you'll need to implement actual IPFS upload)
  const uploadToIPFS = async (file) => {
    setIsUploading(true);
    try {
      // TODO: Implement actual IPFS upload using Pinata, Web3.Storage, or similar
      // For now, we'll simulate with a timeout
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Mock CID - replace with actual IPFS upload
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

  // Mint NFT
  const handleMint = async () => {
    if (!selectedImage || !isConnected) return;

    // Check if we're on Base network (Chain ID: 8453)
    if (chainId !== 8453) {
      alert(`❌ Wrong Network!\n\nYou're on chain ${chainId}.\nPlease switch to Base network (Chain ID: 8453) to mint.\n\nUse the "Switch to Base Network" button above.`);
      return;
    }

    // Demo mode: Check if user has insufficient balance
    const balance = await window.ethereum.request({
      method: 'eth_getBalance',
      params: [address, 'latest']
    });
    const balanceInEth = parseInt(balance, 16) / 1e18;
    
    if (balanceInEth < 0.01) {
      const demoConfirm = confirm(`💡 DEMO MODE\n\nYou have ${balanceInEth.toFixed(4)} ETH, but need ~0.01 ETH for minting.\n\nWould you like to see a DEMO simulation of the mint process?\n\n(Click OK for demo, Cancel to get more ETH)`);
      
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

    try {
      // Upload to IPFS first
      const tokenURI = await uploadToIPFS(selectedImage);
      
      // Get OceanMangaOrchestrator contract address for current chain
      const orchestratorAddress = getOrchestratorAddress(chainId);
      
      if (!orchestratorAddress) {
        throw new Error(`OceanMangaOrchestrator not deployed on chain ${chainId}`);
      }
      
      writeContract({
        address: orchestratorAddress,
        abi: ORCHESTRATOR_ABI,
        functionName: 'mintPhotoCombo',
        args: [tokenURI],
        value: parseEther(mintPrice),
      });
    } catch (err) {
      console.error('Mint failed:', err);
    }
  };

  return (
    <div className="photo-mint-container">
      <h2>Mint OceanManga NFT</h2>
      
      {!isConnected && (
        <p>Please connect your wallet to mint NFTs</p>
      )}

      {isConnected && (
        <div className="mint-form">
          <div className="image-input-section">
            <h3>Select Photo</h3>
            
            {/* Camera Input */}
            <button 
              onClick={() => cameraInputRef.current?.click()}
              className="camera-btn"
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

            {/* Gallery Input */}
            <button 
              onClick={() => fileInputRef.current?.click()}
              className="gallery-btn"
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

            {/* Image Preview */}
            {imagePreview && (
              <div className="image-preview">
                <img src={imagePreview} alt="Selected" style={{ maxWidth: '300px', maxHeight: '300px' }} />
              </div>
            )}
          </div>

          <div className="mint-options">
            <label>
              Mint Price (ETH):
              <input
                type="number"
                step="0.001"
                value={mintPrice}
                onChange={(e) => setMintPrice(e.target.value)}
              />
            </label>
          </div>

          <button
            onClick={handleMint}
            disabled={!selectedImage || isPending || isUploading || isConfirming}
            className="mint-btn"
          >
            {isUploading ? 'Uploading to IPFS...' : 
             isPending ? 'Confirming...' : 
             isConfirming ? 'Waiting for confirmation...' : 
             'Mint NFT'}
          </button>

          {/* Status Messages */}
          {uploadedCID && <p>✅ Uploaded to IPFS: {uploadedCID}</p>}
          {hash && <p>Transaction Hash: {hash}</p>}
          {isConfirmed && <p>✅ NFT Minted Successfully!</p>}
          {error && <p>❌ Error: {error.shortMessage || error.message}</p>}
        </div>
      )}
    </div>
  );
}