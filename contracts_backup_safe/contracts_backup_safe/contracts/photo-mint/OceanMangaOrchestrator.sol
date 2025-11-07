// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// Interfacce corrette per i contratti deployati
interface IOceanMangaNFT {
    function mint(address to, uint256 id, uint256 amount, bytes calldata data) external;
}

interface ILunaComicsFT {
    function mint(address to, uint256 amount) external payable;
}

// Interfacce per conformità con i contratti esistenti
interface ISolidaryOrchestratorReadable {
    function nftPlanetContract() external view returns (address);
    function ftSatelliteContract() external view returns (address);
}

interface ISolidaryOrchestratorReadableFT {
    function nftPlanetContract() external view returns (address);
    function ftSatelliteContract() external view returns (address);
}

contract OceanMangaOrchestrator is OwnableUpgradeable, ReentrancyGuardUpgradeable, ISolidaryOrchestratorReadable, ISolidaryOrchestratorReadableFT {
    IOceanMangaNFT public oceanMangaNFT;
    ILunaComicsFT public lunaComicsFT;
    
    address public creator;
    address public charityFund;

    // Percentuali (base 1000 per maggiore precisione)
    uint256 public constant NFT_SHARE = 550;      // 55%
    uint256 public constant FT_SHARE = 450;       // 45%
    uint256 public constant CREATOR_SHARE = 25;   // 2.5%
    uint256 public constant CHARITY_SHARE = 25;   // 2.5%
    
    // Ratio FT per ETH (es: 1 ETH = 1000 FT)
    uint256 public ftRatio = 1000;
    
    // ID NFT incrementale
    uint256 public nextTokenId = 1;

    event PhotoMinted(
        address indexed user, 
        string tokenURI, 
        uint256 ethPaid, 
        uint256 nftId, 
        uint256 ftAmount
    );

    constructor(
        address _nft,
        address _ft,
        address _creator,
        address _charity
    ) {
        _transferOwnership(msg.sender);
        oceanMangaNFT = IOceanMangaNFT(_nft);
        lunaComicsFT = ILunaComicsFT(_ft);
        creator = _creator;
        charityFund = _charity;
    }

    function mintPhotoCombo(string memory tokenURI) external payable nonReentrant {
        require(msg.value > 0, "Payment required");

        uint256 total = msg.value;
        uint256 currentTokenId = nextTokenId++;
        
        // Calcola le quote
        // uint256 nftAmount = (total * NFT_SHARE) / 1000; // Unused for now
        uint256 ftAmount = (total * FT_SHARE) / 1000;
        uint256 creatorAmount = (total * CREATOR_SHARE) / 1000;
        uint256 charityAmount = (total * CHARITY_SHARE) / 1000;

        // 1. Mint NFT (ERC1155: id, amount, data)
        oceanMangaNFT.mint(msg.sender, currentTokenId, 1, abi.encode(tokenURI));

        // 2. Mint FT (calcola quantità basata su ETH ricevuto)
        uint256 ftTokensToMint = (ftAmount * ftRatio) / 1 ether;
        lunaComicsFT.mint{value: ftAmount}(msg.sender, ftTokensToMint);

        // 3. Distribuisci pagamenti
        uint256 remaining = total - ftAmount - creatorAmount - charityAmount;
        if (remaining > 0) {
            // Il resto rimane nel contratto orchestratore
        }
        payable(creator).transfer(creatorAmount);
        payable(charityFund).transfer(charityAmount);

        emit PhotoMinted(msg.sender, tokenURI, total, currentTokenId, ftTokensToMint);
    }
    
    // Implementazione delle interfacce
    function nftPlanetContract() external view override(ISolidaryOrchestratorReadable, ISolidaryOrchestratorReadableFT) returns (address) {
        return address(oceanMangaNFT);
    }
    
    function ftSatelliteContract() external view override(ISolidaryOrchestratorReadable, ISolidaryOrchestratorReadableFT) returns (address) {
        return address(lunaComicsFT);
    }

    function setFTRatio(uint256 _newRatio) external onlyOwner {
        ftRatio = _newRatio;
    }

    function setAddresses(
        address _creator,
        address _charity
    ) external onlyOwner {
        creator = _creator;
        charityFund = _charity;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}