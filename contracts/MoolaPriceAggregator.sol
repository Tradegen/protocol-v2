// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Inheritance
import './interfaces/IPriceAggregator.sol';

//Interfaces
import './interfaces/IMoolaAdapter.sol';
import './interfaces/IAddressResolver.sol';

contract MoolaPriceAggregator is IPriceAggregator {

    IAddressResolver public ADDRESS_RESOLVER;

    constructor(address _addressResolver) {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    function getUSDPrice(address asset) external view override returns (uint) {
        require(asset != address(0), "MoolaTokenPriceAggregator: invalid asset address.");

        address moolaAdapterAddress = ADDRESS_RESOLVER.getContractAddress("MoolaAdapter");

        return IMoolaAdapter(moolaAdapterAddress).getPrice(asset);
    }
}