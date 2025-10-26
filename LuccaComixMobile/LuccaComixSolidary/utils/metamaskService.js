import { MetaMaskProvider } from '@metamask/sdk-react';

export const metamaskConfig = {
  apiKey: 'c690c86b64b74bd5a69ad2d32cf2a0c6',
  clientId: 'BPOZFh3Z8-D35OCK2tAPyeybjWmNA_GAlJ2pw-MSxZlDcMeit73G0PXEVE-EF9GWrX7DSpxktOulSTEuh4cR0fs',
  infuraUrl: 'https://polygon-mainnet.infura.io/v3/c690c86b64b74bd5a69ad2d32cf2a0c6',
  chains: [
    {
      chainId: '0x2105', // Base Mainnet
      chainName: 'Base Mainnet',
      rpcUrls: ['https://mainnet.base.org'],
      blockExplorerUrls: ['https://basescan.org'],
      nativeCurrency: {
        name: 'ETH',
        symbol: 'ETH',
        decimals: 18,
      },
    }
  ]
};

export const initializeMetaMask = async () => {
  try {
    // Configurazione MetaMask SDK
    const options = {
      infuraAPIKey: metamaskConfig.apiKey,
      dappMetadata: {
        name: 'Lucca Comix Solidary',
        url: 'https://luccacomics.com',
      },
      logging: {
        developerMode: false,
      },
      checkInstallationImmediately: false,
      modals: {
        install: ({ link }) => {
          return {
            // Custom install modal per mobile
            title: 'Installa MetaMask',
            description: 'Per una migliore esperienza Web3, installa MetaMask',
            link,
            buttonText: 'Installa MetaMask'
          };
        }
      }
    };

    return options;
  } catch (error) {
    console.error('Errore inizializzazione MetaMask:', error);
    throw error;
  }
};
