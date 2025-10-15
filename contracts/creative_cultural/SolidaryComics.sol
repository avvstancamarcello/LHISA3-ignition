// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

// Copyright © 2025 Avv. Marcello Stanca - Firenze, Italia. All Rights Reserved.
//
// Hoc contractum, pars 'Solidary System', ab Auctore Marcello Stanca Caritati Internationali (MCMLXXVI) gratis conceditur.
// (This smart contract, part of the 'Solidary System', is granted for free use to Caritas Internationalis (1976) by the author, Marcello Stanca.)

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../core_justice/RefundManager.sol";

/**
 * @title SolidaryComics_StellaDoppia
 * @author Avv. Marcello Stanca - Architectus Fabularum (Architect of Stories)
 */
contract SolidaryComics_StellaDoppia is Initializable, ERC1155Upgradeable, ERC1155SupplyUpgradeable, AccessControlUpgradeable, UUPSUpgradeable, RefundManager {

    uint256 public constant FT_COMIX_ID = 0;
    uint256 public constant NFT_PASS_ID = 1;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public charityWallet;
    uint256 public feePercent;

    event ComicDonation(address indexed user, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialAdmin,
        address _charityWallet,
        uint256 _feePercent,
        address _creatorWallet,
        address _solidaryWallet,
        uint256 _refundDeadline,
        uint256 _initialThreshold
    ) public initializer {
        __ERC1155_init("");
        __ERC1155Supply_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __RefundManager_init(_creatorWallet, _solidaryWallet, _refundDeadline, _initialThreshold);

        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(MINTER_ROLE, initialAdmin);

        charityWallet = _charityWallet;
        feePercent = _feePercent;
    }

    function acquistaAccesso() external payable {
        _recordContribution(msg.sender, msg.value);
        uint256 ftValue = (msg.value * 49) / 100;
        _mint(msg.sender, NFT_PASS_ID, 1, "");
        uint256 comixPrice = 0.01 ether;
        uint256 amountComixToMint = (ftValue * 1 ether) / comixPrice;
        _mint(msg.sender, FT_COMIX_ID, amountComixToMint, "");
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal virtual override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        if (from != address(0) && to != address(0)) {
             for (uint i = 0; i < ids.length; i++) {
                if (ids[i] == FT_COMIX_ID) {
                    uint256 fee = (values[i] * feePercent) / 100;
                    if (fee > 0) {
                        super._update(from, charityWallet, ids[i], fee);
                        emit ComicDonation(from, fee);
                        values[i] -= fee;
                    }
                }
            }
        }
        super._update(from, to, ids, values);
    }

    function setFeePercent(uint256 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newFee <= 10, "Fee too high");
        feePercent = newFee;
    }

    function updateCharityWallet(address newWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        charityWallet = newWallet;
    }

    function setURI(string memory newuri) public onlyRole(MINTER_ROLE) {
        _setURI(newuri);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    function _authorizeUpgrade(address newImplementation) internal override(UUPSUpgradeable, RefundManager) onlyRole(DEFAULT_ADMIN_ROLE) {}
}
