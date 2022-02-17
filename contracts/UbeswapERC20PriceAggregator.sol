// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Inheritance
import './interfaces/IPriceAggregator.sol';

//Interfaces
import './interfaces/IBaseUbeswapAdapter.sol';
import './interfaces/IAddressResolver.sol';

contract UbeswapERC20PriceAggregator is IPriceAggregator {

    IAddressResolver public ADDRESS_RESOLVER;

    constructor(address _addressResolver) {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    function getUSDPrice(address asset) external view override returns (uint) {
        require(asset != address(0), "UbeswapERC20PriceAggregator: invalid asset address");

        address baseUbeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("BaseUbeswapAdapter");
        return IBaseUbeswapAdapter(baseUbeswapAdapterAddress).getPrice(asset);
    }
}