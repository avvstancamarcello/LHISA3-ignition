// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

// --- INTERFACES ---
interface IMintLockModule {
    function mintPhotoCombo(address user, string calldata tokenURI) external payable;
    function isNFTLocked(uint256 tokenId) external view returns (bool);
}

interface IPostLockDistributionModule {
    function distributePostLock(uint256 tokenId) external;
}

// --- ORCHESTRATOR 1: Mint & Lock ---
contract OceanMangaOrchestratorMintLock {
    address public mintLockModule;
    constructor(address _mintLockModule) {
        mintLockModule = _mintLockModule;
    }
    function mintPhoto(string calldata tokenURI) external payable {
        IMintLockModule(mintLockModule).mintPhotoCombo(msg.sender, tokenURI);
    }
    function isLocked(uint256 tokenId) external view returns (bool) {
        return IMintLockModule(mintLockModule).isNFTLocked(tokenId);
    }
}

// --- ORCHESTRATOR 2: Post-Lock Distribution & Liquidation ---
contract OceanMangaOrchestratorPostLock {
    address public postLockModule;
    constructor(address _postLockModule) {
        postLockModule = _postLockModule;
    }
    function distribute(uint256 tokenId) external {
        IPostLockDistributionModule(postLockModule).distributePostLock(tokenId);
    }
}

// --- MODULE: Mint & Lock ---
contract MintLockModule is IMintLockModule {
    // ...mintPhotoCombo, isNFTLocked, storage...
    function mintPhotoCombo(address, string calldata) external payable override {
        // ...mint logic...
    }
    function isNFTLocked(uint256) external pure override returns (bool) {
        // ...lock logic...
        return false;
    }
}

// --- MODULE: Post-Lock Distribution ---
contract PostLockDistributionModule is IPostLockDistributionModule {
    // ...distributePostLock, storage...
    function distributePostLock(uint256) external pure override {
        // ...distribution logic...
    }
}

// --- NOTE ---
// Ogni orchestratore ha solo le funzioni essenziali e invoca il proprio modulo tramite indirizzo.
// I moduli possono essere deployati separatamente e aggiornati senza superare il limite di dimensione.
// Gli orchestratori possono comunicare tra loro tramite eventi, storage condiviso, o chiamate cross-contract.
