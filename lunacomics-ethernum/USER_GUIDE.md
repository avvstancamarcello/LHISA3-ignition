# 🌊 APP Ethernum - User Guide

## Overview
APP Ethernum is a decentralized application for minting NFTs and Fungible Tokens (FTs) on the Base Network, governed by the OceanMangaOrchestrator smart contract.

## Screenshots

### Initial View
![APP Ethernum Initial View](https://github.com/user-attachments/assets/9e83c76b-f7af-4939-ae47-5962b45e4bb5)

## Quick Start Guide

### 1. Connect Your Wallet
- Click the "🔗 Connect Wallet" button
- Approve the connection in MetaMask or your preferred Web3 wallet
- The app will automatically detect your network

### 2. Switch to Base Network (if needed)
- If you're not on Base Network, you'll see a warning
- Click "⚠️ Switch to Base Network"
- Approve the network switch in your wallet

### 3. View Your Balances
Once connected, you'll see:
- Your FT token balance
- The next NFT ID that will be minted
- All relevant contract addresses

### 4. Mint Your NFT + FT Combo

#### Fill in the Form:
- **Title**: Give your NFT a name
- **Description**: Describe your NFT
- **Image CID** (optional): IPFS CID if you've uploaded an image
- **ETH Amount**: Minimum 0.0001 ETH

#### Review the Estimate:
The app will show you:
- Gross FT tokens to be minted
- Net FT you'll receive (95%)
- Creator fee (2.5%)
- Charity fee (2.5%)

#### Confirm the Transaction:
- Click "✨ Mint NFT + FT"
- Approve the transaction in your wallet
- Wait for confirmation

### 5. View Your Results
After successful minting, you'll see:
- ✅ Transaction hash (click to view on BaseScan)
- Your new NFT ID
- Amount of FT tokens received
- Fee breakdown

## Contract Information

### Deployed Contracts (Base Network)
- **Orchestrator**: `0xe062015E8284344750Aa02956B77CFd5A952Fb08`
- **LunaComicsFT**: `0x828fFB61A666e86860482D79620A23DD990eE3F8`
- **OceanMangaNFT**: `0x0FA3668c23017D6Eb4a07A265c0d8849095f1323`

### Fee Structure
Every mint automatically distributes fees:
- **45%** of your ETH → Converted to FT tokens
- **55%** of your ETH → Reserved for NFT operations
- **2.5%** of FT → Creator royalty
- **2.5%** of FT → Charity fund
- **95%** of FT → You receive

## Technical Details

### How Minting Works
1. You send ETH to the Orchestrator contract
2. The contract mints an NFT (ERC1155) with your metadata
3. 45% of ETH is used to mint FT tokens via `mintWithEth`
4. Royalties (5%) are distributed to creator and charity
5. Net FT (95%) is sent to you
6. You receive both the NFT and FT tokens

### Security Features
- ✅ ReentrancyGuard protection
- ✅ Minimum payment validation (0.0001 ETH)
- ✅ Balance verification after minting
- ✅ Event emission for transparency
- ✅ No external API dependencies

### Supported Wallets
- MetaMask
- Coinbase Wallet
- WalletConnect
- Any Web3-compatible wallet

## Troubleshooting

### "Please install MetaMask"
- Install MetaMask browser extension
- Or use a browser with built-in Web3 support

### "Wrong network"
- Click "Switch to Base Network"
- Or manually switch to Base (Chain ID: 8453) in your wallet

### "Insufficient minting fee"
- Increase ETH amount to at least 0.0001 ETH
- Ensure you have enough ETH for gas fees

### Transaction Failed
- Check you have enough ETH for gas
- Verify you're on Base Network
- Try increasing gas limit in wallet settings

## Benefits

### For Users
- 💎 Own unique NFTs with FT rewards
- 💰 Receive 95% of FT tokens
- 🌐 Ultra-low fees on Base Network
- 📊 Transparent fee distribution
- 🔒 Secure smart contract interactions

### For Creators
- 💵 Automatic 2.5% royalty on every mint
- 📈 Growing FT token holdings
- 🎨 Support for custom metadata

### For Charity
- 💖 Automatic 2.5% donation on every mint
- 🌟 Transparent fund tracking
- 🤝 Community-supported giving

## Advanced Features

### Custom Metadata
You can provide:
- **Title**: NFT name
- **Description**: Detailed description
- **Image CID**: IPFS content identifier
- **Attributes**: Custom properties (coming soon)

### Token URI Options
- **Data URI** (default): Metadata embedded in token
- **IPFS**: Decentralized storage (requires image CID)

## Support

For issues or questions:
1. Check the [GitHub repository](https://github.com/avvstancamarcello/LHISA3-ignition)
2. Review contract code in `/contracts/photo-mint/OceanMangaOrchestrator.sol`
3. View transactions on [BaseScan](https://basescan.org)

## Links

- **BaseScan Orchestrator**: https://basescan.org/address/0xe062015E8284344750Aa02956B77CFd5A952Fb08
- **BaseScan FT Token**: https://basescan.org/address/0x828fFB61A666e86860482D79620A23DD990eE3F8
- **BaseScan NFT Contract**: https://basescan.org/address/0x0FA3668c23017D6Eb4a07A265c0d8849095f1323
- **Base Network Docs**: https://docs.base.org

---

**🌟 Built with ❤️ by the Solidary System team**
**💖 Supporting creators and charity with every mint**
