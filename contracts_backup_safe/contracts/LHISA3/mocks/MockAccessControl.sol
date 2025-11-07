// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// © Copyright Marcello Stanca, lawyer in Florence, Italy

/// @title MockAccessControl – Simulazione di controllo accessi per test
contract MockAccessControl {
    mapping(address => mapping(string => bool)) public customRoles;

    /// @notice Assegna o rimuove un ruolo personalizzato a un utente
    /// @param account Indirizzo dell’utente
    /// @param roleKey Nome del ruolo da assegnare
    /// @param hasRole true se vuoi assegnare, false se vuoi rimuovere
    function setCustomRole(address account, string memory roleKey, bool hasRole) external {
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
