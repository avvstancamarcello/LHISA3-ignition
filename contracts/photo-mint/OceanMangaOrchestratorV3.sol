// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

// Copyright Marcello Stanca, Lawyer, Italy, Florence.
// This smart contract is a modular element of the SolidarySystem ecosystem/project, deployed on Polygon and Base networks.

/*
OceanMangaOrchestratorV3 - Doppia Tracciabilità NFT+FT & Prezzo Suggerito

Questa versione dell'orchestrator integra:
- Doppia tracciabilità tra NFT e FT: ogni NFT mintato è associato al corrispondente FT tramite mapping, e viceversa.
- Funzione di prezzo suggerito: dopo la conversione del FT, il prezzo suggerito dell'NFT può essere aggiornato, mantenendo trasparenza e flessibilità.
- Gestione flessibile: NFT e FT possono essere trasferiti/venduti insieme o separatamente, senza vincoli.
- Eventi e getter per tracciare associazioni e aggiornamenti di prezzo.

Flusso operativo:
1. Mint NFT+FT: l'orchestrator crea entrambi e li collega tramite mapping.
2. Conversione FT: l'utente può convertire il FT in altra valuta/token.
3. Aggiornamento prezzo NFT: dopo la conversione, il prezzo suggerito dell'NFT può essere aggiornato tramite orchestrator.
4. Tracciabilità: chiunque può verificare l'associazione NFT↔FT e il prezzo suggerito on-chain.

Questa architettura protegge la trasparenza e la libertà del mercato, permettendo la gestione evoluta di asset digitali e reali.
*/

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface ICosmixSolidaryToken {
    function mint(address to, uint256 amount) external;
}

interface IOceanMangaNFT {
    function mint(address to, uint256 id, uint256 amount, bytes calldata data) external;
    function linkNFTtoFT(uint256 tokenId, address ftAddress) external;
    function updateSuggestedPrice(uint256 tokenId, uint256 newPrice) external;
}

contract OceanMangaOrchestratorV3 is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    // Traccia il valore di mint per ogni NFT
    mapping(uint256 => uint256) public mintValueOf;

    event NFTLiquidated(uint256 indexed tokenId, address owner, uint256 mintValue, uint256 finalValue, uint256 creatorRoyalty, uint256 charityRoyalty, uint256 payout);
    // Permetti ai wallet proprietari di ritirare il residuo rimasto nel contratto
    function withdrawResidue(address to) external nonReentrant whenNotPaused {
        require(to != address(0), "withdrawResidue: invalid address");
        uint256 residue = address(this).balance;
        require(residue > 0, "withdrawResidue: nothing to withdraw");
        payable(to).transfer(residue);
    }
    // Traccia se la distribuzione post-lock è già avvenuta per ogni tokenId
    mapping(uint256 => bool) public distributedPostLock;

    event PostLockDistributed(uint256 indexed tokenId, address creator, uint256 creatorAmount, address charity, uint256 charityAmount);
    function distributePostLock(uint256 tokenId) external nonReentrant whenNotPaused {
        require(!isNFTLocked(tokenId), "distributePostLock: NFT still locked");
        require(!distributedPostLock[tokenId], "distributePostLock: already distributed");
        distributedPostLock[tokenId] = true;
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "distributePostLock: nothing to distribute");
        // Calcola le quote da distribuire
        uint256 creatorAmount = (contractBalance * CREATOR_SHARE) / 1000;
        uint256 charityAmount = (contractBalance * CHARITY_SHARE) / 1000;
        payable(creator).transfer(creatorAmount);
        payable(charityFund).transfer(charityAmount);
        emit PostLockDistributed(tokenId, creator, creatorAmount, charityFund, charityAmount);
    }
    IOceanMangaNFT public oceanMangaNFT;
    ICosmixSolidaryToken public cosmixFT;
    address public creator;
    address public charityFund;

    uint256 public constant NFT_SHARE = 550;      // 55%
    uint256 public constant FT_SHARE = 450;       // 45%
    uint256 public constant CREATOR_SHARE = 25;   // 2.5%
    uint256 public constant CHARITY_SHARE = 25;   // 2.5%
    uint256 public ftRatio;
    uint256 public nextTokenId;

    // Lock/staking logic
    mapping(uint256 => uint256) public nftLockEnd;
    uint256 public lockPeriod;

    event PhotoMinted(address indexed user, uint256 ethPaid, uint256 nftId, uint256 ftAmount, bool locked);
    event LockPeriodChanged(uint256 newPeriod);
    event DebugStep(string step, address actor, uint256 value);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _nft,
        address _ft,
        address _creator,
        address _charity
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        oceanMangaNFT = IOceanMangaNFT(_nft);
        cosmixFT = ICosmixSolidaryToken(_ft);
        creator = _creator;
        charityFund = _charity;
        ftRatio = 1000;
        nextTokenId = 1;
        lockPeriod = 90 days;
    }

    function mintPhotoCombo(string memory tokenURI, address ftAddress) external payable nonReentrant whenNotPaused {
    require(msg.value > 0, "mintPhotoCombo: Payment required");
    uint256 total = msg.value;
    uint256 currentTokenId = nextTokenId++;
    mintValueOf[currentTokenId] = total;
    // Mint NFT
    oceanMangaNFT.mint(msg.sender, currentTokenId, 1, abi.encode(tokenURI));
    // Lock NFT
    nftLockEnd[currentTokenId] = block.timestamp + lockPeriod;
    // Mint FT
    uint256 ftAmount = (total * FT_SHARE) / 1000;
    uint256 ftTokensToMint = (ftAmount * ftRatio) / 1 ether;
    cosmixFT.mint(msg.sender, ftTokensToMint);
    // Associa NFT e FT
    oceanMangaNFT.linkNFTtoFT(currentTokenId, ftAddress);

    // Distribuisci pagamenti
    uint256 creatorAmount = (total * CREATOR_SHARE) / 1000;
    uint256 charityAmount = (total * CHARITY_SHARE) / 1000;
    payable(creator).transfer(creatorAmount);
    payable(charityFund).transfer(charityAmount);

    emit PhotoMinted(msg.sender, total, currentTokenId, ftTokensToMint, true);
    }

    // Funzione di liquidazione post-lock
    function liquidateNFT(uint256 tokenId, uint256 finalValue) external nonReentrant whenNotPaused {
        require(!isNFTLocked(tokenId), "liquidateNFT: NFT still locked");
        uint256 mintValue = mintValueOf[tokenId];
        require(mintValue > 0, "liquidateNFT: mint value not found");
        address owner = msg.sender;
        require(finalValue >= mintValue, "liquidateNFT: final value must be >= mint");
        uint256 gain = finalValue - mintValue;
        uint256 creatorRoyalty = 0;
        uint256 charityRoyalty = 0;
        if (gain > 0) {
            creatorRoyalty = (gain * 25) / 1000; // 2.5%
            charityRoyalty = (gain * 20) / 1000; // 2%
            payable(creator).transfer(creatorRoyalty);
            payable(charityFund).transfer(charityRoyalty);
        }
        uint256 payout = finalValue - creatorRoyalty - charityRoyalty;
        payable(owner).transfer(payout);
        emit NFTLiquidated(tokenId, owner, mintValue, finalValue, creatorRoyalty, charityRoyalty, payout);
    }


    function isNFTLocked(uint256 tokenId) public view returns (bool) {
        return block.timestamp < nftLockEnd[tokenId];
    }

    function setLockPeriod(uint256 newPeriod) external onlyOwner {
        lockPeriod = newPeriod;
        emit LockPeriodChanged(newPeriod);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function updateNFTSuggestedPrice(uint256 tokenId, uint256 newPrice) external {
        // Può essere chiamata dal proprietario, orchestrator, o chi converte FT
        oceanMangaNFT.updateSuggestedPrice(tokenId, newPrice);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
