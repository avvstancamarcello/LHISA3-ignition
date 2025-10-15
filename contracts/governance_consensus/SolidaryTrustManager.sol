// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

// Copyright © 2025 Avv. Marcello Stanca - Firenze, Italia. All Rights Reserved.
//
// Hoc contractum, pars 'Solidary System', ab Auctore Marcello Stanca Caritati Internationali (MCMLXXVI) gratis conceditur.
// (This smart contract, part of the 'Solidary System', is granted for free use to Caritas Internationalis (1976) by the author, Marcello Stanca.)

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title SolidaryTrustManager (Custos Fidei - The Guardian of Trust)
 * @author Avv. Marcello Stanca - Architectus Aequitatis
 * @notice Hoc est fundamentum fidei totius Oecosystematis. Hic, sigilla certitudinis imprimuntur et normae ethicae custodiuntur.
 * (English: This is the foundation of trust for the entire Ecosystem. Here, the seals of certainty are impressed and the ethical norms are guarded.)
 * @dev Sicut lapis angularis Cathedralis, hic contractus integritatem structuralem praestat. Unumquodque "neuron" (contractus) in nostra rete logica debet ab hoc Custode agnosci antequam operari possit. Est radix fiduciae ex qua omnis actio legitima oritur.
 * (English: Like the cornerstone of a Cathedral, this contract guarantees structural integrity. Every "neuron" (contract) in our logical network must be recognized by this Guardian before it can operate. It is the root of trust from which all legitimate action originates.)
 */
contract SolidaryTrustManager is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    struct Certificate {
        string name;
        address module;
        uint256 issuedAt;
        uint256 validUntil;
        bool revoked;
    }

    struct Policy {
        string description;
        uint256 createdAt;
        bool active;
    }

    mapping(address => Certificate) public certificates;
    mapping(bytes32 => Policy) public policies;

    event CertificateIssued(address indexed module, string name, uint256 validUntil);
    event CertificateRevoked(address indexed module);
    event PolicyAdded(bytes32 indexed policyId, string description);
    event PolicyRevoked(bytes32 indexed policyId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        // --- MODIFICA CORRETTIVA ---
        // Invochiamo __Ownable_init passando l'indirizzo del proprietario iniziale,
        // come richiesto dalle nuove versioni di OpenZeppelin per consacrare la proprietà.
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    // 🔐 Emissione certificato di fiducia
    function issueCertificate(address module, string memory name, uint256 validityDuration) external onlyOwner {
        require(module != address(0), "Modulo non potest esse inanis");
        uint256 validUntil = block.timestamp + validityDuration;
        certificates[module] = Certificate(name, module, block.timestamp, validUntil, false);
        emit CertificateIssued(module, name, validUntil);
    }

    // ❌ Revoca certificato
    function revokeCertificate(address module) external onlyOwner {
        require(certificates[module].module != address(0), "Certificatum non inventum");
        certificates[module].revoked = true;
        emit CertificateRevoked(module);
    }

    // ✅ Validazione certificato
    function validateCertificate(address module) external view returns (bool) {
        Certificate memory cert = certificates[module];
        return (
            cert.module != address(0) &&
            !cert.revoked &&
            block.timestamp <= cert.validUntil
        );
    }

    // 📜 Aggiunta policy globale
    function addPolicy(string memory description) external onlyOwner returns (bytes32) {
        bytes32 policyId = keccak256(abi.encodePacked(description, block.timestamp));
        policies[policyId] = Policy(description, block.timestamp, true);
        emit PolicyAdded(policyId, description);
        return policyId;
    }

    // 🕊️ Revoca policy
    function revokePolicy(bytes32 policyId) external onlyOwner {
        require(policies[policyId].active, "Norma non est activa");
        policies[policyId].active = false;
        emit PolicyRevoked(policyId);
    }

    // 🔍 Lettura stato policy
    function isPolicyActive(bytes32 policyId) external view returns (bool) {
        return policies[policyId].active;
    }

    // 🔄 AUCTORITAS EMENDANDI (UPGRADEABILITY)
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
