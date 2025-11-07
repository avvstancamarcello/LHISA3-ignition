// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SistinaSolidary is Ownable {
    struct Pianeta {
        string nome;
        address contratto;
        string descrizione;
    }

    string public nome = "Sistina Solidary";
    string public autore = "Michelangelo";
    string public affrescoIPFS;
    string public auraMusicale;
    string public voiceoverPoetico;

    Pianeta[] public pianetiConnessi;

    event Visita(address visitatore, uint256 timestamp);
    event Meditazione(address anima, string messaggio);
    event Rivelazione(address spirito, string luce);
    event PortaleAperto(string pianeta, address contratto);

    constructor(
        address initialOwner,
        string memory _affrescoIPFS,
        string memory _auraMusicale,
        string memory _voiceoverPoetico
    ) Ownable(initialOwner) {
        affrescoIPFS = _affrescoIPFS;
        auraMusicale = _auraMusicale;
        voiceoverPoetico = _voiceoverPoetico;
    }

    function visita() external {
        emit Visita(msg.sender, block.timestamp);
    }

    function medita(string memory messaggio) external {
        emit Meditazione(msg.sender, messaggio);
    }

    function rivela(string memory luce) external onlyOwner {
        emit Rivelazione(msg.sender, luce);
    }

    function aggiungiPortale(string memory _nome, address _contratto, string memory _descrizione) external onlyOwner {
        pianetiConnessi.push(Pianeta(_nome, _contratto, _descrizione));
        emit PortaleAperto(_nome, _contratto);
    }

    function elencoPianeti() external view returns (Pianeta[] memory) {
        return pianetiConnessi;
    }
}
