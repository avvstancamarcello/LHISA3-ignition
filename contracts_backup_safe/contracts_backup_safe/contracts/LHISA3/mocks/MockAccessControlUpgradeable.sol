// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca, lawyer in Florence, Italy

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/// @title MockAccessControlUpgradeable – Simulazione proxy di controllo accessi
contract MockAccessControlUpgradeable is Initializable, AccessControlUpgradeable {
    mapping(address => mapping(string => bool)) public customRoles;

    /// @notice Inizializza il contratto con ruoli base
    /// @param admin Indirizzo dell’amministratore iniziale
    function initialize(address admin) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @notice Assegna o rimuove un ruolo personalizzato a un utente
    /// @param account Indirizzo dell’utente
    /// @param roleKey Nome del ruolo da assegnare
    /// @param hasRole true se vuoi assegnare, false se vuoi rimuovere
    function setCustomRole(address account, string memory roleKey, bool hasRole) external onlyRole(DEFAULT_ADMIN_ROLE) {
        customRoles[account][roleKey] = hasRole;
    }

    /// @notice Verifica se un utente ha un ruolo personalizzato
    /// @param account Indirizzo dell’utente
    /// @param roleKey Nome del ruolo da verificare
    /// @return true se l’utente ha il ruolo
    function hasCustomRole(address account, string memory roleKey) external view returns (bool) {
        return customRoles[account][roleKey];
    }
}
