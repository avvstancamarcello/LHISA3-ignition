// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

// © Copyright Marcello Stanca - Italy - Florence. Author and owner of the Solidary.it ecosystem and this smart contract. The ecosystem and its logical components (.sol files and scripts) are protected by copyright.


/**
 * OceanMangaNFT (ERC1155 Upgradeable)
 *
 * Visione:
 * - NFT come “imbarcazioni” che navigano l’oceano (OceanManga),
 *   il cui livello energetico è influenzato dal token FT “LunaComics” (gravità),
 *   ma matematicamente bilanciato nel modello Solidary per non arrivare mai a zero.
 *
 * Obiettivi tecnici:
 * - ERC1155 upgradeable con ruoli (ADMIN, MINTER, MANAGER) e pausa
 * - Mapping CID IPFS: metadata / provenance / voyage / auction (upload off-chain → pointer on-chain)
 * - Royalties ERC-2981 (default e per token)
 * - Integrazione soft con Orchestrator (puntatore/lettura; nessun secret on-chain)
 * - Compatibile con Hardhat + OpenZeppelin Upgrades (UUPS)
 *
 * NOTE:
 * - Esegui gli upload dei contenuti su IPFS (NFT.Storage/Pinata) nel backend (es. Heroku)
 * - Poi registra i CID sul contratto con le funzioni *setToken*CID (MANAGER_ROLE)
 */

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface ISolidaryOrchestratorReadable {
    function nftPlanetContract() external view returns (address);
    function ftSatelliteContract() external view returns (address);
    // opzionale: altre funzioni di sola lettura
}

contract OceanMangaNFT is
    Initializable,
    ERC1155Upgradeable,
    ERC1155SupplyUpgradeable,
    ERC2981Upgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    // SolidaryMetrics contract address
    address public solidaryMetrics;

    event SolidaryMetricsUpdated(address indexed metrics);
    /**
     * Imposta l'indirizzo del contratto SolidaryMetrics
     */
    function setSolidaryMetrics(address metrics) external onlyRole(DEFAULT_ADMIN_ROLE) {
        solidaryMetrics = metrics;
        emit SolidaryMetricsUpdated(metrics);
    }
    // Ruoli
    bytes32 public constant MINTER_ROLE  = keccak256("MINTER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // Orchestrator (solo lettura/puntatore; nessun secret su chain)
    ISolidaryOrchestratorReadable public orchestrator;

    // Identità collezione (per UI/marketplaces)
    string public name;   // "OceanManga"
    string public symbol; // "OCEAN"

    // CIDs IPFS (pointer on-chain, dati off-chain)
    mapping(uint256 => string) public tokenIPFSCIDs;   // metadata JSON (es. ipfs://CID/metadata.json)
    mapping(uint256 => string) public provenanceCIDs;  // storia/provenienza
    mapping(uint256 => string) public voyageCIDs;      // contenuti narrativi di “viaggio”
    mapping(uint256 => string) public auctionCIDs;     // log aste / risultati

    // Eventi
    event OrchestratorUpdated(address indexed orchestrator);
    event TokenMetadataCIDSet(uint256 indexed tokenId, string cid);
    event TokenProvenanceCIDSet(uint256 indexed tokenId, string cid);
    event TokenVoyageCIDSet(uint256 indexed tokenId, string cid);
    event TokenAuctionCIDSet(uint256 indexed tokenId, string cid);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @param admin              address con DEFAULT_ADMIN_ROLE
     * @param initialURI         URI base ERC1155 (può essere vuoto o "ipfs://CID/{id}.json")
     * @param _name              "OceanManga"
     * @param _symbol            "OCEAN"
     * @param royaltyReceiver    destinatario royalties di default (treasury)
     * @param royaltyFeeNumerator fee in basis points (es. 500 = 5%)
     */
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

        name = _name;
        symbol = _symbol;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);

        if (royaltyReceiver != address(0) && royaltyFeeNumerator > 0) {
            _setDefaultRoyalty(royaltyReceiver, royaltyFeeNumerator);
        }
    }

    // ----------------- Admin / Config -----------------

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}

    function setOrchestrator(address _orchestrator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        orchestrator = ISolidaryOrchestratorReadable(_orchestrator);
        emit OrchestratorUpdated(_orchestrator);
    }

    // Royalties ERC-2981 (default / per token)
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
    function deleteDefaultRoyalty() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _deleteDefaultRoyalty();
    }
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }
    function resetTokenRoyalty(uint256 tokenId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _resetTokenRoyalty(tokenId);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) { _unpause(); }

    // ----------------- Mint / Burn -----------------
    address public trustManager;
    function setTrustManager(address _trustManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        trustManager = _trustManager;
    }

    function mint(address to, uint256 id, uint256 amount, bytes calldata data)
    external payable
    onlyRole(MINTER_ROLE)
    {
        _mint(to, id, amount, data);
        require(trustManager != address(0), "TrustManager not set");
        (bool success, ) = trustManager.call{value: msg.value}(abi.encodeWithSignature(
            "processMintAndNotify(address,address,uint256)", address(this), msg.sender, msg.value
        ));
        require(success, "TrustManager mint failed");
    }

    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data)
        external
        onlyRole(MINTER_ROLE)
    {
        _mintBatch(to, ids, amounts, data);
    }

    function burn(address from, uint256 id, uint256 amount) external {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "Not owner nor approved");
        _burn(from, id, amount);
    }

    function burnBatch(address from, uint256[] calldata ids, uint256[] calldata amounts) external {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "Not owner nor approved");
        _burnBatch(from, ids, amounts);
    }

    // ----------------- CID registration (upload off-chain → pointer on-chain) -----------------

    function setTokenMetadataCID(uint256 tokenId, string calldata cid) external onlyRole(MANAGER_ROLE) {
        tokenIPFSCIDs[tokenId] = cid;
        emit TokenMetadataCIDSet(tokenId, cid);
    }

    function setTokenProvenanceCID(uint256 tokenId, string calldata cid) external onlyRole(MANAGER_ROLE) {
        provenanceCIDs[tokenId] = cid;
        emit TokenProvenanceCIDSet(tokenId, cid);
    }

    function setTokenVoyageCID(uint256 tokenId, string calldata cid) external onlyRole(MANAGER_ROLE) {
        voyageCIDs[tokenId] = cid;
        emit TokenVoyageCIDSet(tokenId, cid);
    }

    function setTokenAuctionCID(uint256 tokenId, string calldata cid) external onlyRole(MANAGER_ROLE) {
        auctionCIDs[tokenId] = cid;
        emit TokenAuctionCIDSet(tokenId, cid);
    }

    // ----------------- URI logic -----------------

    /**
     * Strategia URI:
     * - Se è stato registrato un CID specifico per il token, ritorna quello
     * - Altrimenti usa l'URI base ERC1155 (con {id})
     */
    function uri(uint256 id) public view override returns (string memory) {
        string memory direct = tokenIPFSCIDs[id];
        if (bytes(direct).length > 0) {
            return direct;
        }
        return super.uri(id);
    }

    function setBaseURI(string calldata newURI) external onlyRole(MANAGER_ROLE) {
        _setURI(newURI);
    }

    // ----------------- Hooks & overrides -----------------

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
