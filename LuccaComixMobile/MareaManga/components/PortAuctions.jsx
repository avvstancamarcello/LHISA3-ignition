// components/PortAuctions.jsx
import React, { useState, useEffect } from 'react';

const PortAuctions = ({ contract, account }) => {
  const [activePorts, setActivePorts] = useState([]);
  const [portAuctions, setPortAuctions] = useState({});
  const [userBids, setUserBids] = useState({});

  useEffect(() => {
    loadActivePorts();
    loadPortAuctions();
  }, [contract]);

  const loadActivePorts = async () => {
    if (!contract) return;
    
    try {
      // Simula caricamento porti attivi
      const ports = await contract.getActivePorts();
      setActivePorts(ports);
    } catch (error) {
      console.error("Error loading ports:", error);
    }
  };

  const loadPortAuctions = async () => {
    if (!contract) return;
    
    // Carica aste per ogni porto attivo
    const auctions = {};
    for (const port of activePorts) {
      const portAuctions = await contract.getPortAuctions(port.id);
      auctions[port.id] = portAuctions;
    }
    setPortAuctions(auctions);
  };

  const placeBid = async (auctionId, bidAmount) => {
    try {
      const tx = await contract.placeBid(auctionId, {
        value: ethers.utils.parseEther(bidAmount.toString())
      });
      await tx.wait();
      
      alert("Offerta inviata con successo!");
      loadPortAuctions(); // Ricarica aste
    } catch (error) {
      console.error("Bid error:", error);
    }
  };

  const unloadContainerAtPort = async (containerId, portId) => {
    try {
      const port = activePorts.find(p => p.id === portId);
      const tx = await contract.unloadAtPort(containerId, portId, {
        value: ethers.utils.parseEther(port.entryFee.toString())
      });
      await tx.wait();
      
      alert("Container scaricato al porto! Asta iniziata.");
    } catch (error) {
      console.error("Unload error:", error);
    }
  };

  return (
    <div className="port-auctions">
      <div className="section-header">
        <h2>🏙️ Porti Commerciali Globali</h2>
        <p>Scarica i tuoi container e partecipa alle aste esclusive</p>
      </div>

      <div className="ports-grid">
        {activePorts.map(port => (
          <div key={port.id} className="port-card">
            <div className="port-header">
              <h3>{port.name}</h3>
              <span className="port-location">📍 {port.location}</span>
            </div>
            
            <div className="port-details">
              <p>⏰ Attivo per: {calculateTimeRemaining(port.activityEndTime)}</p>
              <p>💰 Fee ingresso: {port.entryFee} ETH</p>
              <p>🏆 Prestigio richiesto: {port.prestigeRequirement}</p>
            </div>

            <div className="port-actions">
              <button 
                onClick={() => unloadContainerAtPort(selectedContainer, port.id)}
                className="unload-btn"
              >
                🚚 Scarica Container
              </button>
            </div>

            {/* 🎪 ASTE ATTIVE NEL PORTO */}
            <div className="port-auctions-list">
              <h4>🎪 Aste Attive</h4>
              {portAuctions[port.id]?.map(auction => (
                <AuctionCard 
                  key={auction.id}
                  auction={auction}
                  onPlaceBid={placeBid}
                  userBids={userBids}
                />
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

// 🎯 COMPONENTE CARTA ASTA
const AuctionCard = ({ auction, onPlaceBid, userBids }) => {
  const [bidAmount, setBidAmount] = useState(auction.currentBid + 0.1);

  return (
    <div className="auction-card">
      <div className="auction-header">
        <h5>Lotto #{auction.id}</h5>
        <span className="time-remaining">
          ⏰ {calculateTimeRemaining(auction.endTime)}
        </span>
      </div>
      
      <div className="auction-nfts">
        {auction.nftIds.map(nftId => (
          <div key={nftId} className="auction-nft-preview">
            {/* Miniatura NFT */}
          </div>
        ))}
      </div>

      <div className="auction-details">
        <p>💵 Offerta attuale: {auction.currentBid} ETH</p>
        <p>👤 Offerente: {auction.currentBidder.slice(0, 8)}...</p>
      </div>

      <div className="bid-section">
        <input 
          type="number"
          value={bidAmount}
          onChange={(e) => setBidAmount(parseFloat(e.target.value))}
          min={auction.currentBid + 0.1}
          step="0.1"
        />
        <button 
          onClick={() => onPlaceBid(auction.id, bidAmount)}
          disabled={bidAmount <= auction.currentBid}
        >
          🎯 Fai Offerta
        </button>
      </div>
    </div>
  );
};

export default PortAuctions;
