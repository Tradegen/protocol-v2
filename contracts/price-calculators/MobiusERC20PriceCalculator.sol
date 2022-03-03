// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Inheritance
import '../interfaces/IPriceCalculator.sol';

//Interfaces
import '../interfaces/IMobiusAdapter.sol';
import '../interfaces/IAddressResolver.sol';

contract MobiusERC20PriceCalculator is IPriceCalculator {

    IAddressResolver public ADDRESS_RESOLVER;

    constructor(address _addressResolver) {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    function getUSDPrice(address asset) external view override returns (uint) {
        require(asset != address(0), "MobiusERC20PriceCalculator: invalid asset address");

        address mobiusAdapterAddress = ADDRESS_RESOLVER.getContractAddress("MobiusAdapter");
        return IMobiusAdapter(mobiusAdapterAddress).getPrice(asset);
    }
}