// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// © Copyright Marcello Stanca - Italy - Florence. Author and owner of the Solidary.it ecosystem and this smart contract. The ecosystem and its logical components (.sol files and scripts) are protected by copyright.


library SolidaryHubUtils {
    // Calcolo punteggio salute ecosistema
    function calculateEcosystemHealthScore(
        uint256 totalUsers,
        uint256 totalImpact,
        uint256 globalReputation
    ) internal pure returns (uint256) {
        // Logica semplice: somma pesata
        return totalUsers + totalImpact + globalReputation;
    }

    // Conversione address in string
    function addressToString(address addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(addr)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    // Conversione uint in string
    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            bstr[k] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
    // Utility IPFS upload simulation
    function uploadToIPFS(bytes memory data) internal pure returns (string memory) {
        bytes32 h = keccak256(data);
        return string(abi.encodePacked("simulated:ipfs:", toHexString(uint256(h), 32)));
    }

    // Hex conversion utility
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _hexChar(value & 0xf);
            value >>= 4;
        }
        return string(buffer);
    }
    function _hexChar(uint256 value) private pure returns (bytes1) {
        return value < 10 ? bytes1(uint8(value) + 48) : bytes1(uint8(value) + 87);
    }
}
