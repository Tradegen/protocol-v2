// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract TestPriceCalculator {

    mapping (address => uint256) public prices;

    constructor() {}

    function setPrice(address _asset, uint256 _price) external {
        prices[_asset] = _price;
    }

    function getUSDPrice(address _asset) external view returns (uint256) {
        return prices[_asset];
    }
}

