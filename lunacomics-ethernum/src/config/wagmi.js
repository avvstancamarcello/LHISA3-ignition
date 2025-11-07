import { http, createConfig } from 'wagmi'
import { polygon, base } from 'wagmi/chains'
import { metaMask, coinbaseWallet, injected } from 'wagmi/connectors'

// Minimal config without WalletConnect to avoid 403 errors
export const config = createConfig({
  chains: [base, polygon],
  connectors: [
    // Generic injected for all browser wallets (most reliable)
    injected({
      target: {
        id: 'injected',
        name: 'Browser Wallet',
        provider: () => window.ethereum,
      },
    }),
    // MetaMask specific (backup)
    metaMask({
      dappMetadata: {
        name: 'LunaComics Ethernum',
      },
    }),
    // Coinbase Wallet (backup)
    coinbaseWallet({ 
      appName: 'LunaComics Ethernum',
    }),
    // Removed WalletConnect to eliminate 403/400 errors
  ],
  transports: {
    [base.id]: http(),
    [polygon.id]: http(),
  },
})