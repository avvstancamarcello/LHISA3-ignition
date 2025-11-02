// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../interfaces/IUniswapV2Router02.sol";

/**
 * @title SolidarySwapper
 * @author Avv. Marcello Stanca
 * @notice Contratto wrapper per scambiare token dell'ecosistema Solidary (es. FT) con altri token ERC20
 *         utilizzando un DEX come Uniswap V2.
 * @dev Questo contratto è aggiornabile (UUPS) e controllato da un proprietario (Ownable).
 */
contract SolidarySwapper is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    
    IUniswapV2Router02 public uniswapV2Router;

    event SwapExecuted(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Inizializza il contratto impostando l'indirizzo del router Uniswap V2.
     * @param _routerAddress L'indirizzo del contratto router del DEX (es. Uniswap V2).
     */
    function initialize(address _routerAddress) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        
        require(_routerAddress != address(0), "Swapper: Router address cannot be zero");
        uniswapV2Router = IUniswapV2Router02(_routerAddress);
    }

    /**
     * @notice Esegue uno scambio di token. L'utente deve prima approvare questo contratto
     *         per spendere i suoi `tokenIn`.
     * @param tokenIn L'indirizzo del token da scambiare (es. CosmixProtocolToken).
     * @param tokenOut L'indirizzo del token desiderato (es. WETH, USDC).
     * @param amountIn La quantità di `tokenIn` da scambiare.
     * @param amountOutMin La quantità minima di `tokenOut` che si è disposti ad accettare.
     * @param to L'indirizzo che riceverà i token scambiati.
     * @param deadline La scadenza della transazione.
     */
    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    ) external {
        // Trasferisce i token dall'utente a questo contratto.
        IERC20Upgradeable(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        // Approva il router a spendere i tokenIn di questo contratto.
        IERC20Upgradeable(tokenIn).approve(address(uniswapV2Router), amountIn);

        // Prepara il percorso di scambio. Per scambi diretti, è [tokenIn, tokenOut].
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        // Esegue lo scambio sul DEX.
        uint[] memory amounts = uniswapV2Router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );

        emit SwapExecuted(msg.sender, tokenIn, tokenOut, amounts[0], amounts[1]);
    }

    /**
     * @notice Funzione per aggiornare l'indirizzo del router del DEX.
     * @param _newRouterAddress Il nuovo indirizzo del router.
     */
    function setRouterAddress(address _newRouterAddress) external onlyOwner {
        require(_newRouterAddress != address(0), "Swapper: New router address cannot be zero");
        uniswapV2Router = IUniswapV2Router02(_newRouterAddress);
    }

    /**
     * @notice Funzione richiesta da UUPS per autorizzare un aggiornamento.
     * @dev Solo il proprietario può autorizzare un aggiornamento.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
