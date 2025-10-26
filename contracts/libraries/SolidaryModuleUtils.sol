// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

/**
 * @title SolidaryModuleUtils
 * @author Avv. Marcello Stanca
 * @notice Libreria per la logica modulare e le inizializzazioni pesanti, per ridurre il bytecode del Core Hub.
 */
library SolidaryModuleUtils {

    // ═══════════════════════════════════════════════════════════════════════════════
    // Logica di Inizializzazione (SPOSTATA DA initialize())
    // ═══════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Genera lo snapshot iniziale dello stato dell'ecosistema.
     * @dev Questa funzione deve essere chiamata all'interno di initialize.
     * @return Una struct EnhancedEcosystemState codificata con tutti i campi a zero/default.
     */
    function setInitialEcosystemStateLogic()
        public
        pure
        returns (bytes memory) // Restituisce i dati codificati per l'assegnazione nel Hub
    {
        // Questo sposta il codice di allocazione degli struct fuori dal costruttore del Hub.
        return abi.encode(
            uint256(0), // totalUsers
            uint256(0), // totalImpact
            uint256(0), // globalReputation
            uint256(0), // totalTransactions
            uint256(0), // crossChainVolume
            uint256(0), // carbonFootprint
            uint256(0), // totalValueLocked
            bool(false), // emergencyMode
            string("") // stateCID
        );
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // Logica di Conteggio (SPOSTATA DA _countActiveModules)
    // ═══════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Calcola il numero di moduli attivi (Placeholder/Logica Semplificata).
     * @dev Sposta la logica complessa di iterazione del mapping fuori dal Hub.
     */
    function countActiveModulesLogic(
        uint256 _totalRegistrations,
        uint256 _totalInactive
    ) public pure returns (uint256) {
        // La logica complessa di calcolo (es. ciclo for) si sposta qui.
        return _totalRegistrations - _totalInactive;
    }
}
