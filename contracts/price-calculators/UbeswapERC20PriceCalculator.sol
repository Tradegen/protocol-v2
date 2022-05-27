// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Inheritance
import '../interfaces/IPriceCalculator.sol';

//Interfaces
import '../interfaces/IUbeswapAdapter.sol';
import '../interfaces/IAddressResolver.sol';

contract UbeswapERC20PriceCalculator is IPriceCalculator {

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
        address ubeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapAdapter");

        return IUbeswapAdapter(ubeswapAdapterAddress).getPrice(_asset);
    }
}