// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract SaturnMarketplace is UUPSUpgradeable, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    enum StatoOfferta { Vendita, Affitto, Donazione }

    struct Offerta {
        uint256 id;
        string categoria;
        string descrizione;
        StatoOfferta stato;
        uint256 prezzo;
        address walletErede;
        string notaioRiferimento;
        string piattaformaWallet;
        bool confermataIdentita;
    }

    CountersUpgradeable.Counter private _offertaId;
    mapping(uint256 => Offerta) public offerte;

    event OffertaCreata(uint256 indexed id, string categoria, address indexed walletErede);
    event IdentitaConfermata(uint256 indexed id, address indexed walletErede);

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function creaOfferta(
        string memory categoria,
        string memory descrizione,
        StatoOfferta stato,
        uint256 prezzo,
        address walletErede,
        string memory notaioRiferimento,
        string memory piattaformaWallet
    ) public returns (uint256) {
        uint256 id = _offertaId.current();
        offerte[id] = Offerta({
            id: id,
            categoria: categoria,
            descrizione: descrizione,
            stato: stato,
            prezzo: prezzo,
            walletErede: walletErede,
            notaioRiferimento: notaioRiferimento,
            piattaformaWallet: piattaformaWallet,
            confermataIdentita: false
        });

        _offertaId.increment();
        emit OffertaCreata(id, categoria, walletErede);
        return id;
    }

    function confermaIdentita(uint256 id) public onlyOwner {
        offerte[id].confermataIdentita = true;
        emit IdentitaConfermata(id, offerte[id].walletErede);
    }

    function visualizzaOfferta(uint256 id) public view returns (Offerta memory) {
        return offerte[id];
    }
}
