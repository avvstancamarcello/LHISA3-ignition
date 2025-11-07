    /// @notice Restituisce il ruolo manager per la governance esterna
    function MANAGER_ROLE() public pure returns (bytes32) {
        return keccak256("COSMIX_MANAGER_ROLE");
    }
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;


// Copyright Marcello Stanca, Lawyer, Italy, Florence.
// This smart contract is a modular element of the SolidarySystem ecosystem/project, deployed on Polygon and Base networks.

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title COSMIX Protocol Token (ERC20)
/// @notice Token fungibile principale dell'ecosistema LunaComics
contract CosmixProtocolToken is Initializable, ERC20Upgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    // Emergency Role
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("COSMIX_MINTER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("COSMIX_MANAGER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("COSMIX_UPGRADER_ROLE");


    function initialize(
        address admin,
        uint256 initialSupply,
        address treasury
    ) public initializer {
    __ERC20_init("COSMIX Protocol Token", "COSMIX");
    __AccessControl_init();
    __UUPSUpgradeable_init();

    require(admin != address(0), "Admin address cannot be zero");

    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(MINTER_ROLE, admin);
    _grantRole(MANAGER_ROLE, admin);
    _grantRole(UPGRADER_ROLE, admin);
    // Assegna EMERGENCY_ROLE a wallet alternativo (modifica qui l'indirizzo)
    _grantRole(EMERGENCY_ROLE, admin); // Sostituisci con wallet alternativo se necessario

    _mint(treasury, initialSupply);
    }
    // Funzione di emergenza: può essere chiamata solo da EMERGENCY_ROLE
    function emergencyPause() external onlyRole(EMERGENCY_ROLE) {
        // Implementa la logica di emergenza (es. pause, revoke, ecc.)
    }

    // Sponsor wallet: puoi usare un wallet alternativo per pagare gas
    // Basta connettere il contratto con ethers.getSigner(sponsorWallet)

    // Allows MANAGER to grant MINTER_ROLE to orchestrator or other contracts
    function grantMinterRole(address orchestrator) external onlyRole(MANAGER_ROLE) {
        _grantRole(MINTER_ROLE, orchestrator);
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyRole(MANAGER_ROLE) {
        _burn(from, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}
