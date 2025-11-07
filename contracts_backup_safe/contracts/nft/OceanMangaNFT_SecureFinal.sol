// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title OceanMangaNFT_SecureFinal
 * @dev NFT contract with MANDATORY CUSTOM ROLES - AUTO-INITIALIZED
 * ZERO DEFAULT_ADMIN_ROLE (0x000...000) - GUARANTEED SECURITY
 */
contract OceanMangaNFT_SecureFinal is
    Initializable,
    ERC1155Upgradeable,
    ERC1155SupplyUpgradeable,
    ERC2981Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    // CUSTOM ROLES - GUARANTEED NON-ZERO!
    bytes32 public constant ADMIN_ROLE   = keccak256("OCEANMANGA_ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE  = keccak256("OCEANMANGA_MINTER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("OCEANMANGA_MANAGER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("OCEANMANGA_UPGRADER_ROLE");

    // Contract identity
    string public name;
    string public symbol;
    
    // IPFS mappings
    mapping(uint256 => string) public tokenIPFSCIDs;
    mapping(uint256 => string) public provenanceCIDs;
    mapping(uint256 => string) public voyageCIDs;
    mapping(uint256 => string) public auctionCIDs;

    // Events
    event TokenIPFSCIDSet(uint256 indexed tokenId, string cid);
    event SecureRolesAssigned(address indexed admin, bytes32[] roles);

    constructor() {
        // Disable initialization to prevent front-running
        _disableInitializers();
    }

    function initialize(
        address admin,
        string calldata initialURI,
        string calldata _name,
        string calldata _symbol,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator
    ) public initializer {
        require(admin != address(0), "Admin cannot be zero address");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_symbol).length > 0, "Symbol cannot be empty");
        
        __ERC1155_init(initialURI);
        __ERC1155Supply_init();
        __ERC2981_init();
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        name = _name;
        symbol = _symbol;

        // ASSIGN ALL CUSTOM ROLES - NO DEFAULT_ADMIN_ROLE!
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);

        // Set role admin relationships (ADMIN_ROLE manages all others)
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(MANAGER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(UPGRADER_ROLE, ADMIN_ROLE);
        
        // CRITICAL: DO NOT SET DEFAULT_ADMIN_ROLE AS ADMIN FOR ANY ROLE
        // This ensures ZERO DEFAULT_ADMIN_ROLE usage

        if (royaltyReceiver != address(0) && royaltyFeeNumerator > 0) {
            _setDefaultRoyalty(royaltyReceiver, royaltyFeeNumerator);
        }
        
        // Emit event for verification
        bytes32[] memory assignedRoles = new bytes32[](4);
        assignedRoles[0] = ADMIN_ROLE;
        assignedRoles[1] = MINTER_ROLE;
        assignedRoles[2] = MANAGER_ROLE;
        assignedRoles[3] = UPGRADER_ROLE;
        
        emit SecureRolesAssigned(admin, assignedRoles);
    }

    // Minting functions
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external onlyRole(MINTER_ROLE) {
        _mint(to, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    // IPFS management
    function setTokenIPFSCID(uint256 tokenId, string calldata cid)
        external
        onlyRole(MANAGER_ROLE)
    {
        tokenIPFSCIDs[tokenId] = cid;
        emit TokenIPFSCIDSet(tokenId, cid);
    }

    function setProvenanceCID(uint256 tokenId, string calldata cid)
        external
        onlyRole(MANAGER_ROLE)
    {
        provenanceCIDs[tokenId] = cid;
    }

    // URI function
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory tokenCID = tokenIPFSCIDs[tokenId];
        if (bytes(tokenCID).length > 0) {
            return string(abi.encodePacked("ipfs://", tokenCID));
        }
        return super.uri(tokenId);
    }

    // Admin functions
    function setURI(string calldata newuri) external onlyRole(ADMIN_ROLE) {
        _setURI(newuri);
    }

    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // Royalty management
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyRole(ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // Upgrade authorization - CUSTOM ROLE!
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    // Security verification functions
    function verifyNoDefaultAdminRole(address account) external view returns (bool) {
        bytes32 DEFAULT_ADMIN = 0x0000000000000000000000000000000000000000000000000000000000000000;
        return !hasRole(DEFAULT_ADMIN, account);
    }
    
    function getAllCustomRoles() external pure returns (bytes32[] memory) {
        bytes32[] memory roles = new bytes32[](4);
        roles[0] = ADMIN_ROLE;
        roles[1] = MINTER_ROLE;
        roles[2] = MANAGER_ROLE;
        roles[3] = UPGRADER_ROLE;
        return roles;
    }

    // Required overrides
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, ERC2981Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}