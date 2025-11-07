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

interface ISolidaryOrchestratorReadable {
    function nftPlanetContract() external view returns (address);
    function ftSatelliteContract() external view returns (address);
}

/**
 * @title OceanMangaNFT_FixedRoles
 * @dev NFT contract with CUSTOM ROLES ONLY - NO DEFAULT_ADMIN_ROLE (0x000...000)
 */
contract OceanMangaNFT_FixedRoles is
    Initializable,
    ERC1155Upgradeable,
    ERC1155SupplyUpgradeable,
    ERC2981Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    // CUSTOM ROLES - NO ZERO VALUES!
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
    event ProvenanceCIDSet(uint256 indexed tokenId, string cid);
    event VoyageCIDSet(uint256 indexed tokenId, string cid);
    event AuctionCIDSet(uint256 indexed tokenId, string cid);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
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
        __ERC1155_init(initialURI);
        __ERC1155Supply_init();
        __ERC2981_init();
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        name = _name;
        symbol = _symbol;

        // ASSIGN CUSTOM ROLES ONLY - NO DEFAULT_ADMIN_ROLE!
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);

        // Set role admin relationships
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(MANAGER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(UPGRADER_ROLE, ADMIN_ROLE);

        if (royaltyReceiver != address(0) && royaltyFeeNumerator > 0) {
            _setDefaultRoyalty(royaltyReceiver, royaltyFeeNumerator);
        }
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
        emit ProvenanceCIDSet(tokenId, cid);
    }

    function setVoyageCID(uint256 tokenId, string calldata cid)
        external
        onlyRole(MANAGER_ROLE)
    {
        voyageCIDs[tokenId] = cid;
        emit VoyageCIDSet(tokenId, cid);
    }

    function setAuctionCID(uint256 tokenId, string calldata cid)
        external
        onlyRole(MANAGER_ROLE)
    {
        auctionCIDs[tokenId] = cid;
        emit AuctionCIDSet(tokenId, cid);
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

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator)
        external
        onlyRole(ADMIN_ROLE)
    {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    // Upgrade authorization - CUSTOM ROLE!
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

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