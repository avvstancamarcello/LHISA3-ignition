// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca - Italy - Florence. Author and owner of the Solidary.it ecosystem and this smart contract. The ecosystem and its logical components (.sol files and scripts) are protected by copyright.

/**
 * @title SolidaryModuleUtils
 * @author Avv. Marcello Stanca
 * @notice Contratto per la logica modulare e le inizializzazioni pesanti, per ridurre il bytecode del Core Hub.
 */
contract SolidaryModuleUtils {

    /**
     * @notice Genera lo snapshot iniziale dello stato dell'ecosistema.
     * @dev Questa funzione deve essere chiamata all'interno di initialize.
     * @return Una struct SolidarySystemEcosystemState codificata con tutti i campi a zero/default.
     */
    function setInitialEcosystemStateLogic()
        public
        pure
        returns (bytes memory)
    {
        return abi.encode(
            uint256(0),
            uint256(0),
            uint256(0),
            uint256(0),
            uint256(0),
            uint256(0),
            uint256(0),
            bool(false),
            string("")
        );
    }

    /**
     * @notice Calcola il numero di moduli attivi (Placeholder/Logica Semplificata).
     * @dev Sposta la logica complessa di iterazione del mapping fuori dal Hub.
     */
    function countActiveModulesLogic(
        uint256 _totalRegistrations,
        uint256 _totalInactive
    ) public pure returns (uint256) {
        return _totalRegistrations - _totalInactive;
    }
}