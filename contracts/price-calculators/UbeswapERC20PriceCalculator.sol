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

    function getUSDPrice(address asset) external view override returns (uint) {
        require(asset != address(0), "UbeswapERC20PriceCalculator: invalid asset address");

        address ubeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapAdapter");
        return IUbeswapAdapter(ubeswapAdapterAddress).getPrice(asset);
    }
}