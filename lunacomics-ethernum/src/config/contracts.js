// Contract addresses for different chains
export const CONTRACT_ADDRESSES = {
  137: { // Polygon
    LunaComicsFT: "0xE82CCA2448C87c4B07e489714eC16684209D7D58",
    OceanMangaNFT: "0xBeC80BF2ef21597c0b40106D8eF70d03fEE44C79",
    SponsorVault: "0xB19Ee3A16554d339111028fe3a76fEE5AE45E8A3"
  },
  8453: { // Base - DEPLOYED AND ACTIVE
    OceanMangaOrchestrator: "0xe062015E8284344750Aa02956B77CFd5A952Fb08", // Last deployed orchestrator
    LunaComicsFT: "0x828fFB61A666e86860482D79620A23DD990eE3F8", // Real FT proxy
    OceanMangaNFT: "0x0FA3668c23017D6Eb4a07A265c0d8849095f1323"  // Real NFT contract
  }
};

// Chain configurations
export const CHAINS = {
  137: {
    name: "Polygon",
    rpcUrl: "https://polygon-rpc.com",
    blockExplorer: "https://polygonscan.com"
  },
  8453: {
    name: "Base",
    rpcUrl: "https://mainnet.base.org",
    blockExplorer: "https://basescan.org"
  }
};

// Get contract address by chain ID
export const getContractAddress = (chainId, contractName) => {
  return CONTRACT_ADDRESSES[chainId]?.[contractName];
};

// Get orchestrator address (prefer env variable)
export const getOrchestratorAddress = (chainId) => {
  // First try environment variable
  const envAddress = import.meta.env.VITE_ORCHESTRATOR_CONTRACT_ADDRESS;
  if (envAddress && envAddress !== '0x0000000000000000000000000000000000000000') {
    return envAddress;
  }
  
  // Fallback to chain-specific address
  return getContractAddress(chainId, 'OceanMangaOrchestrator');
};

// Default to Base network
export const DEFAULT_CHAIN_ID = 8453;

// Orchestrator ABI (main function we need)
export const ORCHESTRATOR_ABI = [
  {
    "inputs": [{"name": "tokenURI", "type": "string"}],
    "name": "mintPhotoCombo",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "creator",
    "outputs": [{"name": "", "type": "address"}],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "charityFund",
    "outputs": [{"name": "", "type": "address"}],
    "stateMutability": "view",
    "type": "function"
  }
];