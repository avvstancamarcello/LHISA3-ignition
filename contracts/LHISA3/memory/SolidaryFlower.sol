// © Copyright Marcello Stanca, lawyer in Florence, Italy

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SolidaryFlower – Pianeta della Rinascita nell’Arcobaleno
/// @author Marcello Stanca
/// @notice Custode simbolico: Il Piccolo Principe
/// @dev Ogni fiore mintato rappresenta una memoria affettiva eterna

contract SolidaryFlower {
    struct Memorial {
        string flowerType;        // Tipo di fiore scelto
        string memoryText;        // Testo commemorativo
        string imageMain;         // Immagine della persona commemorata
        string imagePartner;      // Immagine del coniuge
        string imageBrother;      // Immagine del fratello
        string imageSister;       // Immagine della sorella
        string imageFriend;       // Immagine dell’amico/a
        string imagePet;          // Immagine dell’animale domestico
        string symbolicGesture;   // Gesto simbolico: "Star planted by the Little Prince"
    }

    mapping(uint256 => Memorial) public memorials;
    uint256 public nextId = 1;

    string public symbolicGardener = "The Little Prince";

    event FlowerPlanted(
        uint256 indexed id,
        address indexed planter,
        string flowerType,
        string memoryText,
        string symbolicGardener
    );

    /// @notice Pianta un fiore commemorativo con immagini affettive
    function plantFlower(
        string memory flowerType,
        string memory memoryText,
        string memory imageMain,
        string memory imagePartner,
        string memory imageBrother,
        string memory imageSister,
        string memory imageFriend,
        string memory imagePet
    ) external {
        memorials[nextId] = Memorial(
            flowerType,
            memoryText,
            imageMain,
            imagePartner,
            imageBrother,
            imageSister,
            imageFriend,
            imagePet,
            "Star planted by the Little Prince"
        );

        emit FlowerPlanted(
            nextId,
            msg.sender,
            flowerType,
            memoryText,
            symbolicGardener
        );

        nextId++;
    }

    /// @notice Recupera i dati di una commemorazione
    function getMemorial(uint256 id) external view returns (Memorial memory) {
        return memorials[id];
    }
}
