# 🌊 APP Ethernum - NFT & FT Minting Application

A comprehensive React application for minting NFTs and Fungible Tokens (FTs) governed by the OceanMangaOrchestrator smart contract on Base Network.

## ✨ Features

- 🔗 **Wallet Connection**: Connect MetaMask, Coinbase Wallet, or WalletConnect
- 🎨 **NFT Minting**: Create unique NFTs with custom metadata
- 💎 **FT Minting**: Simultaneously mint Fungible Tokens with each NFT
- 📊 **Real-time Estimates**: See FT distribution before minting
- 💰 **Balance Tracking**: View your FT and NFT balances
- 🌐 **Base Network**: Ultra-low fees and fast confirmations
- ⚡ **Modern Stack**: Built with React, Vite, Ethers.js v6

## 🚀 Live Contract - Base Network

**OceanMangaOrchestrator**: `0xe062015E8284344750Aa02956B77CFd5A952Fb08`
- 🔗 [View on BaseScan](https://basescan.org/address/0xe062015E8284344750Aa02956B77CFd5A952Fb08)
- ⛽ Gas costs: ~0.002 ETH per mint
- 🌐 Network: Base Mainnet (Chain ID: 8453)

**Contract Addresses**:
- **LunaComicsFT**: `0x828fFB61A666e86860482D79620A23DD990eE3F8`
- **OceanMangaNFT**: `0x0FA3668c23017D6Eb4a07A265c0d8849095f1323`

## ⚙️ Setup

1. **Install dependencies:**
```bash
npm install
```

2. **Environment Configuration:**
The `.env` file is pre-configured with deployed contract addresses:
```bash
VITE_ORCHESTRATOR_CONTRACT_ADDRESS=0xe062015E8284344750Aa02956B77CFd5A952Fb08
VITE_NETWORK_NAME=base
VITE_CHAIN_ID=8453
```

3. **Add your API keys** (optional):
```bash
# For WalletConnect
VITE_WALLETCONNECT_PROJECT_ID=your_walletconnect_project_id

# For IPFS uploads (optional)
VITE_PINATA_API_KEY=your_pinata_api_key
VITE_PINATA_SECRET_KEY=your_pinata_secret_key
```

4. **Run development server:**
```bash
npm run dev
```

5. **Build for production:**
```bash
npm run build
```

## 🎯 How It Works

### Dual Minting Process
1. **Connect Wallet**: Support for MetaMask, Coinbase, WalletConnect
2. **Select Base Network**: App guides users to Base for optimal experience
3. **Enter NFT Details**: Title, description, and optional IPFS image CID
4. **Set ETH Amount**: Minimum 0.0001 ETH required
5. **View Estimates**: See FT distribution before confirming
6. **Mint**: Creates both NFT and FT tokens in one transaction
7. **Receive Tokens**: NFT + net FT tokens sent to your wallet

### Fee Distribution
The Orchestrator contract automatically distributes fees:
- **45%** of ETH → Converted to FT tokens
- **2.5%** → Creator royalty (in FT)
- **2.5%** → Charity fund (in FT)
- **95%** of FT → User receives (net amount)

Example with 0.01 ETH:
- Gross FT minted: Based on tokensPerEth ratio
- User receives: 95% of FT
- Creator fee: 2.5% of FT
- Charity fee: 2.5% of FT

## 🏗️ Contract Integration

The app integrates with **OceanMangaOrchestrator** which handles:
- ✅ **Dual minting**: NFT + FT tokens simultaneously
- 💰 **Automatic fee distribution**: Creator and charity royalties
- 📋 **Metadata support**: Data URI or IPFS-based tokenURI
- 🔒 **Security**: ReentrancyGuard and proper access controls
- 📊 **Transparent tracking**: Events for all minting operations

### Contract Functions Used
```solidity
function mintPhotoCombo(string memory tokenURI) external payable
```
- Mints one NFT (ERC1155) with specified tokenURI
- Converts 45% of ETH to FT tokens via mintWithEth
- Distributes FT royalties to creator and charity
- Sends net FT amount to minter

## 🎨 APP Components

### EthernumApp (Main Component)
- **Wallet Management**: Connection, network switching, account display
- **Balance Display**: Real-time FT and NFT balance tracking
- **Contract Info**: Shows all relevant contract addresses
- **Minting Interface**: Complete form for NFT creation
- **Transaction Status**: Real-time feedback on minting progress

### Key Features
- **Responsive Design**: Works on desktop and mobile
- **Error Handling**: Clear error messages and recovery
- **Network Detection**: Prompts to switch to Base if on wrong network
- **Transaction Tracking**: Links to BaseScan for all transactions
- **Estimate Calculator**: Shows expected FT distribution before minting

## 🌐 Networks Support

| Network | Status | Contract Address |
|---------|--------|------------------|
| **Base Mainnet** | ✅ **ACTIVE** | `0xe062015E8284344750Aa02956B77CFd5A952Fb08` |
| Polygon | ⏸️ Not Used | N/A |

## 🛠️ Technology Stack

- **React 19**: Modern React with hooks
- **Vite**: Fast build tool and dev server
- **Ethers.js v6**: Ethereum interaction library
- **Wagmi**: React hooks for Ethereum (optional)
- **Base Network**: Low-cost L2 blockchain

## 📱 Usage Guide

### For Users
1. Visit the app in your browser
2. Click "Connect Wallet"
3. Approve connection in MetaMask
4. Ensure you're on Base Network
5. Fill in NFT details
6. Set ETH amount (min 0.0001)
7. Review FT estimate
8. Click "Mint NFT + FT"
9. Confirm transaction in wallet
10. Receive your NFT and FT tokens!

### For Developers
```javascript
// Import the component
import EthernumApp from './components/EthernumApp'

// Use in your app
function App() {
  return <EthernumApp />
}
```

## 🔐 Security Features

- ✅ ReentrancyGuard on all minting functions
- ✅ Minimum payment validation
- ✅ Network verification before transactions
- ✅ Balance verification after minting
- ✅ Event emission for transparency
- ✅ No external API dependencies for core functionality

## 🚀 Deployment

The app is production-ready and can be deployed to:
- Vercel
- Netlify
- GitHub Pages
- Any static hosting service

Build command: `npm run build`
Output directory: `dist`

## 📊 Example Transactions

View recent mints on BaseScan:
- [Orchestrator Contract](https://basescan.org/address/0xe062015E8284344750Aa02956B77CFd5A952Fb08)
- [NFT Contract](https://basescan.org/address/0x0FA3668c23017D6Eb4a07A265c0d8849095f1323)
- [FT Contract](https://basescan.org/address/0x828fFB61A666e86860482D79620A23DD990eE3F8)

## 🤝 Contributing

This is part of the LHISA3-ignition ecosystem. For contributions:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

MIT License - See LICENSE file for details

---

**🌟 Powered by Solidary System on Base Network**
**💖 Supporting creators and charity with every mint**
