// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract OceanMangaNFT_Simple is Initializable, ERC721Upgradeable, AccessControlUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address defaultAdmin) initializer public {
        __ERC721_init("OceanMangaNFT Simple", "OMNSS");
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, defaultAdmin); // Admin can also mint by default
    }

    event DebugNFTMint(address caller, address to, uint256 nextTokenId);

    function safeMint(address to, string memory /* uri */) public {
        require(hasRole(MINTER_ROLE, msg.sender), "OceanMangaNFT_Simple: must have MINTER_ROLE");
        emit DebugNFTMint(msg.sender, to, _tokenIdCounter.current());
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        // _setTokenURI(tokenId, uri); // Token URI logic omitted for simplicity
    }

    // Compatibilità con l'interfaccia IOceanMangaNFT
    function mint(address to, uint256 id, uint256 amount, bytes calldata data) external {
        // Ignora id, amount, data per semplicità: chiama safeMint
        safeMint(to, "");
    }

    function burn(uint256 tokenId) public {
        // In a real scenario, you'd check for ownership or approval.
        // For this mock, we allow anyone with access to burn for simplicity,
        // assuming the orchestrator is the one calling it.
        _burn(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "http://example.com/";
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
