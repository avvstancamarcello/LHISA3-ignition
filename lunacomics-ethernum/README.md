# 🌊 LunaComics Ethernum - OceanManga NFT Minting App

A React app for minting OceanManga NFTs from photos using camera or gallery input. **Now deployed and ready on Base Network!**

## ✨ Features

- 📱 Connect wallet (MetaMask, Coinbase Wallet, WalletConnect)
- 📷 Take photos with camera or select from gallery
- 🌐 Upload images to IPFS
- 🎭 Mint NFTs on Base network (ultra-low fees!)
- ⚡ Modern React with Vite, Wagmi, and Viem

## 🚀 Live Contract - Base Network

**OceanMangaOrchestrator**: `0x361eDa57Cd71C976B638fEC20256a433107c9282`
- 🔗 [View on BaseScan](https://basescan.org/address/0x361eDa57Cd71C976B638fEC20256a433107c9282)
- ⛽ Gas costs: ~0.002 gwei (almost free!)
- 🌐 Network: Base Mainnet (Chain ID: 8453)

## ⚙️ Setup

1. **Install dependencies:**
```bash
npm install
```

2. **Environment is pre-configured!**
The `.env` file is already set up with the deployed contract address:
```bash
VITE_ORCHESTRATOR_CONTRACT_ADDRESS=0x361eDa57Cd71C976B638fEC20256a433107c9282
VITE_NETWORK_NAME=base
VITE_CHAIN_ID=8453
```

3. **Add your API keys** (optional for basic testing):
```bash
# For IPFS uploads (can use mock for testing)
VITE_PINATA_API_KEY=your_pinata_api_key
VITE_PINATA_SECRET_KEY=your_pinata_secret_key

# For WalletConnect
VITE_WALLETCONNECT_PROJECT_ID=your_walletconnect_project_id
```

4. **Run development server:**
```bash
npm run dev
```

## 🎯 How It Works

1. **Connect Wallet**: Support for MetaMask, Coinbase, WalletConnect
2. **Select Base Network**: App guides users to Base for optimal experience
3. **Take/Select Photo**: Camera or gallery input
4. **Upload to IPFS**: Decentralized storage for metadata
5. **Mint NFT**: Calls `mintPhotoCombo()` on the orchestrator
6. **Dual Minting**: Creates both NFT and FT tokens in one transaction

## 🏗️ Contract Integration

The app integrates with **OceanMangaOrchestrator** which handles:
- ✅ **Dual minting**: NFT + FT tokens simultaneously
- 💰 **Payment distribution**: Creator and charity fees
- 📋 **IPFS metadata**: Decentralized storage
- 🔒 **Security**: Proper access controls and validation

## 🌐 Networks Support

| Network | Status | Features |
|---------|--------|----------|
| **Base Mainnet** | ✅ **LIVE** | Ultra-low fees, fast confirmations |
| Polygon | ⏳ Pending | High fees, network congestion |

## 🎨 UI Components

- **NetworkInfo**: Shows current network and contract status
- **PhotoMint**: Main minting interface
- **WalletConnect**: Multi-wallet connection support

## 🚀 Ready to Use!

The app is fully configured and ready for:
- ✅ Testing with real wallet connections
- ✅ Photo capture and upload
- ✅ NFT minting on Base network
- ✅ Production deployment

---

**Powered by Solidary System • Base Network Ready!**
