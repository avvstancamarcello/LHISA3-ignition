// components/ShippingDashboard.jsx
import React, { useState, useEffect } from 'react';
import ShipCard from './ShipCard';
import ContainerManager from './ContainerManager';
import NFTPedigreeView from './NFTPedigreeView';
import VoyageTracker from './VoyageTracker';

const ShippingDashboard = ({ contract, userNFTs, userContainers, availableShips, account }) => {
  const [selectedNFTs, setSelectedNFTs] = useState([]);
  const [selectedContainer, setSelectedContainer] = useState(null);
  const [activeVoyages, setActiveVoyages] = useState([]);

  // 🎯 CARICA VIAGGI ATTIVI
  useEffect(() => {
    loadActiveVoyages();
  }, [contract]);

  const loadActiveVoyages = async () => {
    if (!contract) return;
    
    const voyages = [];
    // Simula caricamento viaggi (implementa con contratto reale)
    setActiveVoyages(voyages);
  };

  const handleNFTCertification = async (nftId, certifierData) => {
    try {
      const tx = await contract.issueProfessionalCertificate(
        nftId,
        JSON.stringify(certifierData),
        "0x" // Signature del certificatore
      );
      await tx.wait();
      alert("Certificazione emessa con successo!");
    } catch (error) {
      console.error("Certification error:", error);
    }
  };

  const startNewVoyage = async (shipId, destinationPort) => {
    try {
      const tx = await contract.startVoyage(shipId, destinationPort);
      await tx.wait();
      alert("Viaggio iniziato! Le ricompense arriveranno al completamento.");
    } catch (error) {
      console.error("Voyage error:", error);
    }
  };

  return (
    <div className="shipping-dashboard">
      <div className="dashboard-header">
        <h2>🚢 La Tua Flotta Commerciale</h2>
        <div className="fleet-stats">
          <div className="stat-card">
            <span className="stat-number">{userContainers.length}</span>
            <span className="stat-label">Container</span>
          </div>
          <div className="stat-card">
            <span className="stat-number">{userNFTs.length}</span>
            <span className="stat-label">Carte in Viaggio</span>
          </div>
          <div className="stat-card">
            <span className="stat-number">{activeVoyages.length}</span>
            <span className="stat-label">Viaggi Attivi</span>
          </div>
        </div>
      </div>

      <div className="dashboard-content">
        {/* 🚢 SEZIONE NAVI DISPONIBILI */}
        <section className="ships-section">
          <h3>⛵ La Tua Flotta</h3>
          <div className="ships-grid">
            {availableShips.filter(ship => ship.captain === account).map(ship => (
              <ShipCard 
                key={ship.id}
                ship={ship}
                onStartVoyage={startNewVoyage}
                availablePorts={[1, 2, 3, 4]} // Porti disponibili
              />
            ))}
          </div>
        </section>

        {/* 📦 GESTIONE CONTAINER */}
        <section className="containers-section">
          <h3>📦 I Tuoi Container</h3>
          <ContainerManager 
            containers={userContainers}
            userNFTs={userNFTs}
            availableShips={availableShips}
            onContainerUpdate={() => loadUserData()} // Ricarica dati
          />
        </section>

        {/* 🎮 SELEZIONE NFT */}
        <section className="nft-selection">
          <h3>🎴 Le Tue Carte da Gioco</h3>
          <div className="nft-grid">
            {userNFTs.map(nft => (
              <div key={nft.id} className="nft-card">
                <img src={nft.image} alt={nft.name} />
                <div className="nft-info">
                  <h4>{nft.name}</h4>
                  <p>{nft.gameUniverse}</p>
                  <span className={`rarity rarity-${nft.rarity}`}>
                    {nft.rarity}
                  </span>
                </div>
                <NFTPedigreeView 
                  nftId={nft.id}
                  contract={contract}
                  onCertify={handleNFTCertification}
                />
                <button 
                  onClick={() => setSelectedNFTs(prev => [...prev, nft.id])}
                  disabled={selectedNFTs.includes(nft.id)}
                >
                  {selectedNFTs.includes(nft.id) ? 'Selezionato' : 'Seleziona'}
                </button>
              </div>
            ))}
          </div>
        </section>

        {/* ⏰ TRACCIAMENTO VIAGGI */}
        <section className="voyages-section">
          <h3>🧭 Viaggi in Corso</h3>
          <VoyageTracker 
            voyages={activeVoyages}
            contract={contract}
            onVoyageComplete={loadActiveVoyages}
          />
        </section>
      </div>
    </div>
  );
};

export default ShippingDashboard;
