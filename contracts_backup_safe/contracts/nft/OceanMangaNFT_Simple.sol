// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title OceanMangaNFT_Simple
 * @dev NFT contract with MANDATORY CUSTOM ROLES - NON-UPGRADEABLE
 * ZERO DEFAULT_ADMIN_ROLE (0x000...000) - GUARANTEED SECURITY
 */
contract OceanMangaNFT_Simple is
    ERC1155,
    ERC1155Supply,
    ERC2981,
    AccessControl,
    Pausable,
    ReentrancyGuard
{
    // CUSTOM ROLES - GUARANTEED NON-ZERO!
    bytes32 public constant ADMIN_ROLE   = keccak256("OCEANMANGA_ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE  = keccak256("OCEANMANGA_MINTER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("OCEANMANGA_MANAGER_ROLE");

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

    constructor(
        address admin,
        string memory initialURI,
        string memory _name,
        string memory _symbol,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator
    ) ERC1155(initialURI) {
        require(admin != address(0), "Admin cannot be zero address");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_symbol).length > 0, "Symbol cannot be empty");
        
        name = _name;
        symbol = _symbol;

        // ASSIGN ALL CUSTOM ROLES - NO DEFAULT_ADMIN_ROLE!
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);

        // Set role admin relationships (ADMIN_ROLE manages all others)
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(MANAGER_ROLE, ADMIN_ROLE);
        
        // CRITICAL: DO NOT SET DEFAULT_ADMIN_ROLE AS ADMIN FOR ANY ROLE
        // This ensures ZERO DEFAULT_ADMIN_ROLE usage

        if (royaltyReceiver != address(0) && royaltyFeeNumerator > 0) {
            _setDefaultRoyalty(royaltyReceiver, royaltyFeeNumerator);
        }
        
        // Emit event for verification
        bytes32[] memory assignedRoles = new bytes32[](3);
        assignedRoles[0] = ADMIN_ROLE;
        assignedRoles[1] = MINTER_ROLE;
        assignedRoles[2] = MANAGER_ROLE;
        
        emit SecureRolesAssigned(admin, assignedRoles);
    }

    // Role verification function
    function verifyNoDefaultAdminRole(address account) external view returns (bool) {
        bytes32 DEFAULT_ADMIN_ROLE = 0x0000000000000000000000000000000000000000000000000000000000000000;
        return !hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Minting function - only MINTER_ROLE
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyRole(MINTER_ROLE) {
        _mint(to, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    // Set IPFS CID for a token
    function setTokenIPFSCID(uint256 tokenId, string calldata cid) 
        external 
        onlyRole(MANAGER_ROLE) 
    {
        tokenIPFSCIDs[tokenId] = cid;
        emit TokenIPFSCIDSet(tokenId, cid);
    }

    // Batch set IPFS CIDs
    function setTokenIPFSCIDBatch(
        uint256[] calldata tokenIds, 
        string[] calldata cids
    ) external onlyRole(MANAGER_ROLE) {
        require(tokenIds.length == cids.length, "Arrays length mismatch");
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenIPFSCIDs[tokenIds[i]] = cids[i];
            emit TokenIPFSCIDSet(tokenIds[i], cids[i]);
        }
    }

    // Set provenance CID
    function setProvenanceCID(uint256 tokenId, string calldata cid) 
        external 
        onlyRole(MANAGER_ROLE) 
    {
        provenanceCIDs[tokenId] = cid;
    }

    // Set voyage CID
    function setVoyageCID(uint256 tokenId, string calldata cid) 
        external 
        onlyRole(MANAGER_ROLE) 
    {
        voyageCIDs[tokenId] = cid;
    }

    // Set auction CID
    function setAuctionCID(uint256 tokenId, string calldata cid) 
        external 
        onlyRole(MANAGER_ROLE) 
    {
        auctionCIDs[tokenId] = cid;
    }

    // Update base URI
    function setURI(string calldata newuri) external onlyRole(MANAGER_ROLE) {
        _setURI(newuri);
    }

    // Get token URI with IPFS CID
    function uri(uint256 tokenId) public view override returns (string memory) {
        if (bytes(tokenIPFSCIDs[tokenId]).length > 0) {
            return string(abi.encodePacked("https://ipfs.io/ipfs/", tokenIPFSCIDs[tokenId]));
        }
        return super.uri(tokenId);
    }

    // Pause functions
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // Emergency functions
    function emergencyWithdraw() external onlyRole(ADMIN_ROLE) nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    // Override required functions
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155, ERC1155Supply) {
        require(!paused(), "Token transfers paused");
        super._update(from, to, ids, values);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}