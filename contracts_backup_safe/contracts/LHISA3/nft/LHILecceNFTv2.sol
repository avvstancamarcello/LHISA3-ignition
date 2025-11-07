// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// © Copyright Marcello Stanca, Firenze, Italy


import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract LHILecceNFTv2 is Initializable, ERC1155SupplyUpgradeable, AccessControlUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    bytes32 public constant ADMIN_ROLE = DEFAULT_ADMIN_ROLE;
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address public fungibleManager;
    address public nonFungibleManager;

    event ManagerSet(string managerType, address indexed managerAddr);

    function initialize(string memory uri_, address admin) public initializer {
        __ERC1155_init(uri_);
        __ERC1155Supply_init();
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _grantRole(ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
    }

    function setURI(string memory newuri) public onlyRole(ADMIN_ROLE) {
        _setURI(newuri);
    }

    function setFungibleManager(address _manager) public onlyRole(ADMIN_ROLE) {
        require(_manager != address(0), "Invalid manager address");
        fungibleManager = _manager;
        emit ManagerSet("FUNGIBLE", _manager);
    }

    function setNonFungibleManager(address _manager) public onlyRole(ADMIN_ROLE) {
        require(_manager != address(0), "Invalid manager address");
        nonFungibleManager = _manager;
        emit ManagerSet("NON_FUNGIBLE", _manager);
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data) public whenNotPaused {
        require(
            hasRole(MANAGER_ROLE, msg.sender) ||
            msg.sender == fungibleManager ||
            msg.sender == nonFungibleManager,
            "Caller is not authorized"
        );
        _mint(to, id, amount, data);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC1155Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(ADMIN_ROLE) {}
}
