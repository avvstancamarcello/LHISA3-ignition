// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca - Italy - Florence. Author and owner of the Solidary.it ecosystem and this smart contract. The ecosystem and its logical components (.sol files and scripts) are protected by copyright.


// Questa libreria contiene le funzioni di utilità che non cambiano lo stato del contratto.
library SolidaryIpfsUtils {

    // Funzioni helper di basso livello per la conversione esadecimale/stringa.
    // Queste sono le tue implementazioni originali.

    function _nibble(bytes1 b) internal pure returns (bytes1 c) {
        uint8 v = uint8(b);
        return v < 10 ? bytes1(v + 0x30) : bytes1(v + 0x57);
    }

    function _bytes32ToHexString(bytes32 v) internal pure returns (string memory) {
        bytes memory s = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            bytes1 b = v[i];
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) % 16);
            s[2*i]   = _nibble(hi);
            s[2*i+1] = _nibble(lo);
        }
        return string(s);
    }
    
    function _uint2str(uint256 x) internal pure returns (string memory) {
        if (x == 0) return "0";
        uint256 j = x; uint256 len;
        while (j != 0) { len++; j /= 10; }
        bytes memory b = new bytes(len);
        uint256 k = len; uint256 y = x;
        while (y != 0) { k--; b[k] = bytes1(uint8(48 + y % 10)); y /= 10; }
        return string(b);
    }

    /**
     * @notice Simula l'upload di dati su IPFS e restituisce un CID basato su hash.
     * @param data Dati da hashashare per il CID.
     * @param timestamp Timestamp corrente.
     * @param totalCIDs Contatore per aggiungere entropia (deve essere passato come parametro).
     */
    function generateSimulatedCID(
        bytes memory data,
        uint256 timestamp,
        uint256 totalCIDs
    )
        internal
        pure
        returns (string memory cid)
    {
        // Usa le funzioni helper che sono definite sopra in questa libreria.
        bytes32 hash = keccak256(abi.encodePacked(data, timestamp, totalCIDs)); 

        cid = string(abi.encodePacked("simulated:ipfs:", _bytes32ToHexString(hash)));
        return cid;
    }
}
