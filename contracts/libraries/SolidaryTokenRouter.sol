// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol"; // Per la formattazione dei dati

/**
 * @title SolidaryTokenRouter
 * @author Avv. Marcello Stanca
 * @notice Libreria per la gestione della conversione e del routing di token (FT/NFT) verso valute esterne (USDC, DAI).
 * @dev Contiene la logica di calcolo per l'equipollenza senza accedere allo stato.
 */
library SolidaryTokenRouter {
    using StringsUpgradeable for uint256;

    // L'indirizzo del Router/Exchange reale (es. QuickSwap) sarà gestito dal Hub.
    
    // ───────────────────────────────── Costanti ──────────────────────────────────
    uint256 private constant BASIS_POINTS_DIVISOR = 10000;
    
    // ───────────────────────────────── Stella Doppia Logica ───────────────────────
    uint256 public constant FT_SHARE_BPS = 4500; // 45.00% in Basis Points (BPS)
    uint256 public constant NFT_SHARE_BPS = 5500; // 55.00% in Basis Points (BPS)

    /**
     * @notice Calcola la ripartizione del valore totale in base al protocollo Stella Doppia (45% FT / 55% NFT).
     * @param totalValue Il valore totale da ripartire (in unità intere).
     * @return ftValue La porzione destinata al token FT (45%).
     * @return nftValue La porzione destinata al token NFT (55%).
     */
    function calculateStellaDoppiaSplit(uint256 totalValue) public pure returns (uint256 ftValue, uint256 nftValue) {
        ftValue = (totalValue * FT_SHARE_BPS) / BASIS_POINTS_DIVISOR;
        nftValue = (totalValue * NFT_SHARE_BPS) / BASIS_POINTS_DIVISOR;
    }

    // ───────────────────────────────── Calcolo Valore / Conversione ────────────────
    
    /**
     * @notice Simula il calcolo del valore per una conversione (es. da LUNA a USDC).
     * @dev Questa è la logica centrale che definisce l'equipollenza.
     * @param amount L'ammontare del token da convertire.
     * @param rate La tariffa di conversione (es. 1e18 per un tasso di 1:1, 0.5e18 per un tasso di 1:0.5).
     * @return Il valore equivalente nella valuta target.
     */
    function calculateConversionValue(uint256 amount, uint256 rate) public pure returns (uint256) {
        // La logica complessa di scambio e slippage verrebbe aggiunta qui, ma manteniamo la purezza per il bytecode.
        return (amount * rate) / 1e18; 
    }
}
