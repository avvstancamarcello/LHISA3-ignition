// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract OceanMangaNFT is Initializable, ERC721Upgradeable, AccessControlUpgradeable {
    /// @dev Override richiesto da ERC721Upgradeable + AccessControlUpgradeable
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    // Emergency Role
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    address public orchestrator;

    function initialize(address _orchestrator) public initializer {
    __ERC721_init("OceanMangaNFT", "OMNFT");
    __AccessControl_init();
    orchestrator = _orchestrator;
    // Assegna EMERGENCY_ROLE a wallet alternativo (modifica qui l'indirizzo)
    _grantRole(EMERGENCY_ROLE, _orchestrator); // Sostituisci con wallet alternativo se necessario
    }
    // Funzione di emergenza: può essere chiamata solo da EMERGENCY_ROLE
    function emergencyPause() external onlyRole(EMERGENCY_ROLE) {
        // Implementa la logica di emergenza (es. pause, revoke, ecc.)
    }

    // Sponsor wallet: puoi usare un wallet alternativo per pagare gas
    // Basta connettere il contratto con ethers.getSigner(sponsorWallet)

    // Mapping inverso: TokenCID => tokenId
    mapping(string => uint256) public tokenCIDToId;

    // Doppia tracciabilità: mapping NFT <-> FT
    mapping(uint256 => address) public nftToFT;
    mapping(address => uint256[]) public ftToNFTs;

    // Prezzo suggerito per NFT (aggiornabile dopo conversione FT)
    mapping(uint256 => uint256) public suggestedPrice;
    event SuggestedPriceUpdated(uint256 indexed tokenId, uint256 newPrice, address updater);

    // Event per messaggistica
    event MessageSent(address indexed to, uint256 indexed tokenId, string message, address indexed from);

    // Funzione per inviare messaggio al proprietario di un NFT
    function sendMessageToOwner(string memory tokenCID, string memory message) external {
        uint256 tokenId = tokenCIDToId[tokenCID];
        require(tokenId != 0, "TokenCID non trovato");
        address owner = ownerOf(tokenId);
        emit MessageSent(owner, tokenId, message, msg.sender);
    }

    // Funzione per associare NFT e FT (chiamata dall'orchestrator al mint)
    function linkNFTtoFT(uint256 tokenId, address ftAddress) external {
        require(msg.sender == orchestrator, "Solo orchestrator");
        nftToFT[tokenId] = ftAddress;
        ftToNFTs[ftAddress].push(tokenId);
    }

    // Funzione per aggiornare il prezzo suggerito dell'NFT dopo conversione FT
    function updateSuggestedPrice(uint256 tokenId, uint256 newPrice) external {
        require(_isApprovedOrOwner(msg.sender, tokenId) || msg.sender == orchestrator, "Non autorizzato");
        suggestedPrice[tokenId] = newPrice;
        emit SuggestedPriceUpdated(tokenId, newPrice, msg.sender);
    }

    // Getter per tracciabilità
    function getNFTLinkedFT(uint256 tokenId) external view returns (address) {
        return nftToFT[tokenId];
    }
    function getFTLinkedNFTs(address ftAddress) external view returns (uint256[] memory) {
        return ftToNFTs[ftAddress];
    }

    // Aggiorna mapping inverso durante il mint
    function mintWithCID(address to, string memory tokenCID) public returns (uint256 tokenId) {
        tokenId = totalSupply() + 1;
        _safeMint(to, tokenId);
        tokenCIDToId[tokenCID] = tokenId;
        return tokenId;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdTracker;
    }

    uint256 private _tokenIdTracker;

    function _safeMint(address to, uint256 tokenId) internal override {
        _mint(to, tokenId);
        _tokenIdTracker++;
    }
}