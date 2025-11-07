// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca, Firenze, Italy

import "@openzeppelin/contracts/access/Ownable.sol";

interface IBluzelleStorage {
    function storeCID(address user, string memory cid) external;
}

interface IAlgorandBridge {
    function transferToAlgorand(address user, uint256 amount) external;
}

interface IBBTMTrust {
    function certify(address module, bytes memory certificate) external returns (bool);
}

contract RainbowBridgeAdapter is Ownable {
    IBluzelleStorage public bluzelle;
    IAlgorandBridge public algorand;
    IBBTMTrust public bbtm;

    event CIDStored(address indexed user, string cid);
    event AlgorandTransfer(address indexed user, uint256 amount);
    event CertificateValidated(address indexed module, bool success);
    event ImpactLogged(bytes32 indexed impactHash, string domain);

    constructor(
        address initialOwner,
        address bluzelleAddress,
        address algorandAddress,
        address bbtmAddress
    ) Ownable(initialOwner) {
        bluzelle = IBluzelleStorage(bluzelleAddress);
        algorand = IAlgorandBridge(algorandAddress);
        bbtm = IBBTMTrust(bbtmAddress);
    }

    function bridgeToBluzelle(address user, string memory cid) external onlyOwner {
        bluzelle.storeCID(user, cid);
        emit CIDStored(user, cid);
    }

    function bridgeToAlgorand(address user, uint256 amount) external onlyOwner {
        algorand.transferToAlgorand(user, amount);
        emit AlgorandTransfer(user, amount);
    }

    function certifyWithBBTM(address module, bytes memory certificate) external onlyOwner {
        bool success = bbtm.certify(module, certificate);
        emit CertificateValidated(module, success);
    }

    function logImpact(bytes32 impactHash, string memory domain) external onlyOwner {
        emit ImpactLogged(impactHash, domain);
    }
}
