// components/NFTPedigreeView.jsx
import React, { useState, useEffect } from 'react';

const NFTPedigreeView = ({ nftId, contract, onCertify }) => {
  const [pedigree, setPedigree] = useState(null);
  const [showCertification, setShowCertification] = useState(false);
  const [certifierData, setCertifierData] = useState({
    company: '',
    license: '',
    certificationDate: '',
    notes: ''
  });

  useEffect(() => {
    loadPedigreeData();
  }, [nftId, contract]);

  const loadPedigreeData = async () => {
    if (!contract) return;
    
    try {
      const pedigreeData = await contract.verifyAuthenticity(nftId);
      setPedigree({
        authenticityCode: pedigreeData.authenticityCode,
        provenance: pedigreeData.provenance,
        isCertified: pedigreeData.isCertified,
        certifier: pedigreeData.certifier
      });
    } catch (error) {
      console.error("Error loading pedigree:", error);
    }
  };

  const handleCertification = () => {
    onCertify(nftId, certifierData);
    setShowCertification(false);
  };

  if (!pedigree) return <div>Caricamento pedigree...</div>;

  return (
    <div className="pedigree-view">
      <div className="pedigree-header">
        <h4>📜 Certificato di Autenticità</h4>
        {!pedigree.isCertified && (
          <button 
            onClick={() => setShowCertification(true)}
            className="certify-btn"
          >
            🏅 Certifica Ora
          </button>
        )}
      </div>

      <div className="pedigree-details">
        <p><strong>🔐 Codice Hammer:</strong> {pedigree.authenticityCode}</p>
        <p><strong>🏢 Certificato da:</strong> 
          {pedigree.isCertified ? pedigree.certifier : 'Non certificato'}
        </p>
        
        <div className="provenance-timeline">
          <h5>📈 Storico Proprietà:</h5>
          {parseProvenance(pedigree.provenance).map((record, index) => (
            <div key={index} className="provenance-record">
              <div className="record-dot"></div>
              <div className="record-info">
                <span className="from-to">{record.from} → {record.to}</span>
                <span className="record-date">{record.date}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* 🏅 MODALE CERTIFICAZIONE */}
      {showCertification && (
        <div className="certification-modal">
          <div className="modal-content">
            <h3>🏅 Certifica Carta</h3>
            <div className="form-group">
              <label>Società Certificatrice:</label>
              <input 
                type="text"
                value={certifierData.company}
                onChange={(e) => setCertifierData({...certifierData, company: e.target.value})}
                placeholder="Es: CartaCert International"
              />
            </div>
            <div className="form-group">
              <label>Licenza:</label>
              <input 
                type="text"
                value={certifierData.license}
                onChange={(e) => setCertifierData({...certifierData, license: e.target.value})}
                placeholder="Numero licenza"
              />
            </div>
            <div className="form-actions">
              <button onClick={handleCertification}>Conferma Certificazione</button>
              <button onClick={() => setShowCertification(false)}>Annulla</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

// 🔧 FUNZIONE PARSING PROVENANCE
const parseProvenance = (provenanceString) => {
  if (!provenanceString) return [];
  
  return provenanceString.split('|').map(record => {
    const [from, to, timestamp] = record.split(':');
    return {
      from: from || 'Unknown',
      to: to || 'Unknown',
      date: new Date(parseInt(timestamp) * 1000).toLocaleDateString()
    };
  }).filter(record => record.from && record.to);
};

export default NFTPedigreeView;
