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
    // Tokens minted per 1 ETH (scaled to token decimals). Example: 1000e18 => 1 ETH mints 1000 tokens
    uint256 public tokensPerEth;

    event MintedWithEth(address indexed to, uint256 ethIn, uint256 amountOut);
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
    tokensPerEth = 1000 ether; // default: 1 ETH => 1000 tokens (18 decimals)
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

    // Payable mint linked to ETH payment; callable by MINTER_ROLE (e.g., orchestrator)
    function mintWithEth(address to, uint256 minOut) external payable onlyRole(MINTER_ROLE) returns (uint256 out) {
        require(msg.value > 0, "No ETH sent");
        require(to != address(0), "to=0");
        out = (msg.value * tokensPerEth) / 1 ether;
        require(out >= minOut, "slippage");
        _mint(to, out);
        emit MintedWithEth(to, msg.value, out);
    }

    function setTokensPerEth(uint256 newRate) external onlyRole(MANAGER_ROLE) {
        require(newRate > 0, "rate=0");
        tokensPerEth = newRate;
    }

    function withdrawEther(address payable to, uint256 amount) external onlyRole(MANAGER_ROLE) {
        require(to != address(0), "to=0");
        uint256 bal = address(this).balance;
        require(amount <= bal, "insufficient");
        to.transfer(amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}
