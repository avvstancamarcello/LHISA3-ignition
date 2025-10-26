import { useState, useEffect } from 'react';
import Web3Service from '../utils/web3Service';

export const useWeb3 = () => {
  const [isConnected, setIsConnected] = useState(false);
  const [userAddress, setUserAddress] = useState('');
  const [balance, setBalance] = useState('0');
  const [nfts, setNfts] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  // Connetti wallet
  const connectWallet = async () => {
    setLoading(true);
    setError('');
    try {
      const address = await Web3Service.connectWallet();
      setUserAddress(address);
      setIsConnected(true);
      
      // Carica dati iniziali
      await loadUserData();
    } catch (err) {
      setError(err.message);
      console.error('Connection error:', err);
    } finally {
      setLoading(false);
    }
  };

  // Carica dati utente
  const loadUserData = async () => {
    if (!Web3Service.isConnected) return;
    
    try {
      const [tokenBalance, userNFTs] = await Promise.all([
        Web3Service.getTokenBalance(),
        Web3Service.getUserNFTs()
      ]);
      
      setBalance(tokenBalance);
      setNfts(userNFTs);
    } catch (err) {
      console.error('Error loading user data:', err);
    }
  };

  // Mint NFT
  const mintNFT = async (imageUri, emotion) => {
    setLoading(true);
    setError('');
    try {
      const receipt = await Web3Service.mintPhotoNFT(imageUri, emotion);
      await loadUserData(); // Ricarica dati
      return receipt;
    } catch (err) {
      setError(err.message);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  // Disconnetti
  const disconnect = () => {
    Web3Service.disconnect();
    setIsConnected(false);
    setUserAddress('');
    setBalance('0');
    setNfts([]);
  };

  // Auto-connect on app start
  useEffect(() => {
    const checkConnection = async () => {
      if (typeof window.ethereum !== 'undefined') {
        const accounts = await window.ethereum.request({ method: 'eth_accounts' });
        if (accounts.length > 0) {
          connectWallet();
        }
      }
    };

    checkConnection();
  }, []);

  return {
    isConnected,
    userAddress,
    balance,
    nfts,
    loading,
    error,
    connectWallet,
    disconnect,
    mintNFT,
    loadUserData
  };
};
