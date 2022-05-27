// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Inheritance
import '../interfaces/IPriceCalculator.sol';

//Interfaces
import '../interfaces/IMobiusAdapter.sol';
import '../interfaces/IAddressResolver.sol';
import '../interfaces/Mobius/ISwap.sol';

contract MobiusLPTokenPriceCalculator is IPriceCalculator {

    IAddressResolver public ADDRESS_RESOLVER;

    constructor(address _addressResolver) {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the USD price of the given asset.
    * @param _pair Address of the liquidity pair.
    * @return uint256 USD price of the asset.
    */
    function getUSDPrice(address _pair) external view override returns (uint256) {
        require(_pair != address(0), "MobiusLPTokenPriceCalculator: Invalid asset address");

        address mobiusAdapterAddress = ADDRESS_RESOLVER.getContractAddress("MobiusAdapter");
        address swapAddress = IMobiusAdapter(mobiusAdapterAddress).getSwapAddress(_pair);

        return ISwap(swapAddress).getVirtualPrice();
    }
}