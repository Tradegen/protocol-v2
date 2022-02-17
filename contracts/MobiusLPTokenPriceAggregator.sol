// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Inheritance
import './interfaces/IPriceAggregator.sol';

//Interfaces
import './interfaces/IMobiusAdapter.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/Mobius/ISwap.sol';

contract MobiusLPTokenPriceAggregator is IPriceAggregator {

    IAddressResolver public ADDRESS_RESOLVER;

    constructor(address _addressResolver) {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    function getUSDPrice(address pair) external view override returns (uint) {
        require(pair != address(0), "MobiusLPTokenPriceAggregator: invalid asset address");

        address mobiusAdapterAddress = ADDRESS_RESOLVER.getContractAddress("MobiusAdapter");
        address swapAddress = IMobiusAdapter(mobiusAdapterAddress).getSwapAddress(pair);

        return ISwap(swapAddress).getVirtualPrice();
    }
}