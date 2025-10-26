// components/GameUniverseSelector.jsx
import React from 'react';

const GameUniverseSelector = ({ onUniverseSelect, selectedUniverse }) => {
  const gameUniverses = [
    {
      id: 'pokemon',
      name: 'Pokémon',
      icon: '⚡',
      description: 'Carte Pokémon originali',
      color: '#FF0000'
    },
    {
      id: 'magic',
      name: 'Magic: The Gathering',
      icon: '🔥',
      description: 'Planeswalker e incantesimi',
      color: '#0000FF'
    },
    {
      id: 'yugioh',
      name: 'Yu-Gi-Oh!',
      icon: '🐉',
      description: 'Mostri e magie',
      color: '#FFFF00'
    },
    {
      id: 'digimon',
      name: 'Digimon',
      icon: '💻',
      description: 'Digimon digitali',
      color: '#00FF00'
    },
    {
      id: 'onepiece',
      name: 'One Piece',
      icon: '🏴‍☠️',
      description: 'Carte dei pirati',
      color: '#800000'
    }
  ];

  return (
    <div className="game-universe-selector">
      <h3>🎮 Seleziona Universo di Gioco</h3>
      <div className="universes-grid">
        {gameUniverses.map(universe => (
          <div
            key={universe.id}
            className={`universe-card ${selectedUniverse === universe.id ? 'selected' : ''}`}
            onClick={() => onUniverseSelect(universe.id)}
            style={{ borderColor: universe.color }}
          >
            <div className="universe-icon" style={{ color: universe.color }}>
              {universe.icon}
            </div>
            <h4>{universe.name}</h4>
            <p>{universe.description}</p>
          </div>
        ))}
      </div>
    </div>
  );
};

export default GameUniverseSelector;
