// App.js - APPLICAZIONE PRINCIPALE
import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import './App.css';

// 🎯 COMPONENTI PRINCIPALI
import ShippingDashboard from './components/ShippingDashboard';
import Marketplace from './components/Marketplace';
import PedigreeView from './components/PedigreeView';
import PortAuctions from './components/PortAuctions';
import UserProfile from './components/UserProfile';
import GameUniverseSelector from './components/GameUniverseSelector';

function App() {
  const [account, setAccount] = useState('');
  const [contract, setContract] = useState(null);
  const [currentView, setCurrentView] = useState('dashboard');
  const [userNFTs, setUserNFTs] = useState([]);
  const [userContainers, setUserContainers] = useState([]);
  const [availableShips, setAvailableShips] = useState([]);

  // 🔗 CONNESSIONE WALLET E CONTRATTO
  const connectWallet = async () => {
    if (window.ethereum) {
      try {
        const provider = new ethers.providers.Web3Provider(window.ethereum);
        await provider.send("eth_requestAccounts", []);
        const signer = provider.getSigner();
        const address = await signer.getAddress();
        setAccount(address);

        // 📜 CARICA CONTRATTO
        const contractAddress = "YOUR_CONTRACT_ADDRESS";
        const contractABI = [...]; // ABI del contratto
        const gameContract = new ethers.Contract(contractAddress, contractABI, signer);
        setContract(gameContract);

        // 📥 CARICA DATI INIZIALI
        loadUserData(gameContract, address);
      } catch (error) {
        console.error("Connection error:", error);
      }
    }
  };

  const loadUserData = async (contract, address) => {
    // 🎮 CARICA NFT UTENTE
    const nfts = await loadUserNFTs(contract, address);
    setUserNFTs(nfts);

    // 📦 CARICA CONTAINER
    const containers = await loadUserContainers(contract, address);
    setUserContainers(containers);

    // 🚢 CARICA NAVI DISPONIBILI
    const ships = await loadAvailableShips(contract);
    setAvailableShips(ships);
  };

  return (
    <div className="App">
      {/* 🎪 HEADER CON NAVIGAZIONE */}
      <header className="app-header">
        <div className="header-content">
          <h1>🌊 MareaManga Trading Fleet</h1>
          <nav className="main-nav">
            <button onClick={() => setCurrentView('dashboard')}>🚢 Dashboard</button>
            <button onClick={() => setCurrentView('marketplace')}>🏪 Marketplace</button>
            <button onClick={() => setCurrentView('auctions')}>🎪 Aste Porto</button>
            <button onClick={() => setCurrentView('profile')}>👤 Profilo</button>
          </nav>
          {!account ? (
            <button onClick={connectWallet} className="connect-wallet-btn">
              🔗 Connetti Wallet
            </button>
          ) : (
            <div className="wallet-info">
              <span>{account.slice(0, 6)}...{account.slice(-4)}</span>
            </div>
          )}
        </div>
      </header>

      {/* 🎯 CONTENUTO PRINCIPALE */}
      <main className="app-main">
        {!account ? (
          <div className="welcome-screen">
            <div className="welcome-content">
              <h2>🌍 Benvenuto nel Mercato Bilanciario Globale</h2>
              <p>Il primo ecosistema di trading gamificato per carte da collezione</p>
              <button onClick={connectWallet} className="cta-button">
                🚀 Inizia la Tua Avventura
              </button>
            </div>
          </div>
        ) : (
          <>
            {currentView === 'dashboard' && (
              <ShippingDashboard 
                contract={contract}
                userNFTs={userNFTs}
                userContainers={userContainers}
                availableShips={availableShips}
                account={account}
              />
            )}
            {currentView === 'marketplace' && (
              <Marketplace 
                contract={contract}
                userNFTs={userNFTs}
                account={account}
              />
            )}
            {currentView === 'auctions' && (
              <PortAuctions 
                contract={contract}
                account={account}
              />
            )}
            {currentView === 'profile' && (
              <UserProfile 
                contract={contract}
                account={account}
                userNFTs={userNFTs}
              />
            )}
          </>
        )}
      </main>
    </div>
  );
}

export default App;
