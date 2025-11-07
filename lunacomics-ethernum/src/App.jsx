import { useState } from 'react'
import SimpleWalletConnect from './components/SimpleWalletConnect'
import SimplePhotoMint from './components/SimplePhotoMint'
import SimpleNetworkInfo from './components/SimpleNetworkInfo'
import './App.css'

function App() {
  // Removed wagmi dependency to eliminate all external API calls

  return (
    <div className="app">
      <header className="app-header">
        <h1>🌊 LunaComics Ethernum</h1>
        <p>Mint OceanManga NFTs from your photos</p>
      </header>

      <main className="app-main">
        <SimpleWalletConnect />
        <SimplePhotoMint />
        <SimpleNetworkInfo />
      </main>

      <footer className="app-footer">
        <p>Powered by Solidary System • Base Network Ready!</p>
        <p>
          🎭 Orchestrator: 
          <a 
            href="https://basescan.org/address/0x361eDa57Cd71C976B638fEC20256a433107c9282" 
            target="_blank" 
            rel="noopener noreferrer"
          >
            0x361e...9282
          </a>
        </p>
      </footer>
    </div>
  )
}

export default App
