// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;


interface IPriceOracle {
    function getFTConversionRate() external view returns (uint256);
}

interface IFTToken {
    function burn(address from, uint256 amount) external;
    function mint(address to, uint256 amount) external;
}

contract FTConversionManager {
    struct FTLock {
        uint256 amount;
        uint256 unlockedAmount;
        uint256 lockStart;
    }
    mapping(address => FTLock) public ftLocks;
    uint256 public constant WAIT_PERIOD = 7 days;
    uint256 public constant FREE_CONVERSION_PERCENT = 10; // 10%

    event FTRequested(address indexed user, uint256 amount);
    event FTConverted(address indexed user, uint256 amount);
    event FTConversionQuote(address indexed user, uint256 amount, uint256 rate, uint256 estimatedGasCost);

    // Chiamata dal contratto FT quando vengono mintati nuovi token
    function notifyFTMint(address user, uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        FTLock storage lock = ftLocks[user];
        lock.amount += amount;
        lock.unlockedAmount += (amount * FREE_CONVERSION_PERCENT) / 100;
        lock.lockStart = block.timestamp;
        emit FTRequested(user, amount);
    }

    address public priceOracle;

    function setPriceOracle(address _oracle) external {
        // Solo owner in produzione
        priceOracle = _oracle;
    }

    function getConversionQuote(uint256 amount) external returns (uint256 rate, uint256 estimatedGasCost) {
        require(priceOracle != address(0), "Oracle not set");
        rate = IPriceOracle(priceOracle).getFTConversionRate();
        estimatedGasCost = tx.gasprice * 21000; // Stima minima, da migliorare
        emit FTConversionQuote(msg.sender, amount, rate, estimatedGasCost);
        return (rate, estimatedGasCost);
    }

    // Conversione libera fino al 10% subito, il resto dopo 7 giorni
    function convertFT(uint256 amount) external {
        FTLock storage lock = ftLocks[msg.sender];
        require(lock.amount >= amount, "Not enough FT");
        uint256 available;
        if (block.timestamp < lock.lockStart + WAIT_PERIOD) {
            available = lock.unlockedAmount;
        } else {
            available = lock.amount;
        }
        require(amount <= available, "Amount exceeds available for conversion");
        lock.amount -= amount;
        if (block.timestamp < lock.lockStart + WAIT_PERIOD) {
            lock.unlockedAmount -= amount;
        }
        // ...conversion logic (es. burn FT, mint stablecoin)...
        // Informo l'utente del costo gas
        uint256 estimatedGasCost = tx.gasprice * 21000;
        emit FTConversionQuote(msg.sender, amount, 0, estimatedGasCost);
        emit FTConverted(msg.sender, amount);
    }

    // 5. Notifica di cambio tasso
    mapping(address => uint256) public userRateAlerts;
    event RateAlertTriggered(address indexed user, uint256 rate);

    function setRateAlert(uint256 minRate) external {
        userRateAlerts[msg.sender] = minRate;
    }

    function checkRateAlert(address user) external {
        require(priceOracle != address(0), "Oracle not set");
        uint256 rate = IPriceOracle(priceOracle).getFTConversionRate();
        if (rate >= userRateAlerts[user] && userRateAlerts[user] > 0) {
            emit RateAlertTriggered(user, rate);
        }
    }

    // 6. Conversione tra diversi FT


    function convertFTtoFT(address fromToken, address toToken, uint256 amount) external {
        require(fromToken != toToken, "Tokens must differ");
        IFTToken(fromToken).burn(msg.sender, amount);
        // Simulazione: 1:1, in produzione usare oracolo o pool
        IFTToken(toToken).mint(msg.sender, amount);
        // Storico conversioni
        userConversionHistory[msg.sender].push(Conversion({from: fromToken, to: toToken, amount: amount, timestamp: block.timestamp}));
        emit FTConverted(msg.sender, amount);
    }

    // 7. Storico conversioni
    struct Conversion {
        address from;
        address to;
        uint256 amount;
        uint256 timestamp;
    }
    mapping(address => Conversion[]) public userConversionHistory;

    function getConversionHistory(address user) external view returns (Conversion[] memory) {
        return userConversionHistory[user];
    }
}
