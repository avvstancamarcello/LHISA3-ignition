// © Copyright Marcello Stanca, lawyer in Florence, Italy

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

//
// © Copyright Marcello Stanca, Firenze, Italy

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SolidaryTrustManager is Initializable, OwnableUpgradeable {
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

    function initialize() public initializer {
        __Ownable_init();
    }

    // 🔐 Emissione certificato di fiducia
    function issueCertificate(address module, string memory name, uint256 validUntil) external onlyOwner {
        require(module != address(0), "Invalid module");
        certificates[module] = Certificate(name, module, block.timestamp, validUntil, false);
        emit CertificateIssued(module, name, validUntil);
    }

    // ❌ Revoca certificato
    function revokeCertificate(address module) external onlyOwner {
        require(certificates[module].module != address(0), "Certificate not found");
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
        require(policies[policyId].active, "Policy not active");
        policies[policyId].active = false;
        emit PolicyRevoked(policyId);
    }

    // 🔍 Lettura stato policy
    function isPolicyActive(bytes32 policyId) external view returns (bool) {
        return policies[policyId].active;
    }
}
