// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title SolidarySystemHub
 * @author Avv. Marcello Stanca
 * @notice Un hub centrale e semplice per registrare e gestire i moduli del Solidary System.
 * @dev Utilizza UUPS per l'aggiornabilità e Ownable per il controllo degli accessi.
 */
contract SolidarySystemHub is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    /**
     * @dev Struttura per rappresentare un "Modulo di Solidarietà", composto da tre contratti.
     */
    struct SolidarityModule {
        address orchestrator; // L'orchestratore del modulo
        address ft;           // Il token fungibile (es. Cosmix)
        address nft;          // Il token non fungibile (es. OceanManga)
        bool isActive;        // Stato del modulo
    }

    // Mapping per memorizzare i moduli tramite un ID univoco.
    mapping(bytes32 => SolidarityModule) public modules;
    // Array di ID per iterare sui moduli registrati.
    bytes32[] public moduleIds;

    // Indirizzo del contratto TokenRouter di sistema.
    address public tokenRouter;

    // Eventi per tracciare le modifiche allo stato del contratto.
    event ModuleRegistered(bytes32 indexed moduleId, address indexed orchestrator);
    event ModuleRemoved(bytes32 indexed moduleId);
    event TokenRouterSet(address indexed routerAddress);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Inizializza il contratto, impostando il deployer come proprietario.
     */
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /**
     * @notice Imposta l'indirizzo del contratto SolidarySystemTokenRouter.
     * @param _routerAddress L'indirizzo del contratto TokenRouter.
     * @dev Solo il proprietario può chiamare questa funzione.
     */
    function setTokenRouter(address _routerAddress) external onlyOwner {
        require(_routerAddress != address(0), "Hub: Router address cannot be zero");
        tokenRouter = _routerAddress;
        emit TokenRouterSet(_routerAddress);
    }

    /**
     * @notice Registra un nuovo modulo di solidarietà nel sistema.
     * @param _moduleId Un ID univoco per il nuovo modulo.
     * @param _orchestrator L'indirizzo del contratto orchestratore.
     * @param _ft L'indirizzo del contratto del token fungibile.
     * @param _nft L'indirizzo del contratto del token non fungibile.
     * @dev Solo il proprietario può chiamare questa funzione.
     */
    function registerModule(bytes32 _moduleId, address _orchestrator, address _ft, address _nft) external onlyOwner {
        require(modules[_moduleId].orchestrator == address(0), "Hub: Module ID already exists");
        require(_orchestrator != address(0), "Hub: Orchestrator address cannot be zero");

        modules[_moduleId] = SolidarityModule({
            orchestrator: _orchestrator,
            ft: _ft,
            nft: _nft,
            isActive: true
        });
        moduleIds.push(_moduleId);

        emit ModuleRegistered(_moduleId, _orchestrator);
    }

    /**
     * @notice Rimuove un modulo dal sistema.
     * @param _moduleId L'ID del modulo da rimuovere.
     * @dev Solo il proprietario può chiamare questa funzione. La rimozione è logica (disattivazione).
     */
    function removeModule(bytes32 _moduleId) external onlyOwner {
        require(modules[_moduleId].orchestrator != address(0), "Hub: Module not found");
        
        modules[_moduleId].isActive = false;
        // Nota: per semplicità, non rimuoviamo l'ID dall'array `moduleIds`.
        // Un'implementazione più complessa potrebbe gestire la compattazione dell'array.

        emit ModuleRemoved(_moduleId);
    }

    /**
     * @notice Restituisce i dettagli di un modulo specifico.
     * @param _moduleId L'ID del modulo da interrogare.
     * @return I dettagli del modulo.
     */
    function getModule(bytes32 _moduleId) external view returns (SolidarityModule memory) {
        return modules[_moduleId];
    }

    /**
     * @notice Restituisce l'elenco completo degli ID dei moduli registrati.
     * @return Un array di bytes32 contenente tutti gli ID dei moduli.
     */
    function getModuleIds() external view returns (bytes32[] memory) {
        return moduleIds;
    }

    /**
     * @notice Funzione richiesta da UUPS per autorizzare un aggiornamento.
     * @dev Solo il proprietario può autorizzare un aggiornamento.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
