// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Inheritance.
import '../interfaces/IPriceCalculator.sol';

// Interfaces.
import '../interfaces/IMoolaAdapter.sol';
import '../interfaces/IAddressResolver.sol';

contract MoolaPriceCalculator is IPriceCalculator {

    IAddressResolver public ADDRESS_RESOLVER;

    constructor(address _addressResolver) {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the USD price of the given asset.
    * @param _asset Address of the asset.
    * @return uint256 USD price of the asset.
    */
    function getUSDPrice(address _asset) external view override returns (uint256) {
        require(_asset != address(0), "MoolaTokenPriceCalculator: Invalid asset address.");

        address moolaAdapterAddress = ADDRESS_RESOLVER.getContractAddress("MoolaAdapter");

        return IMoolaAdapter(moolaAdapterAddress).getPrice(_asset);
    }
}