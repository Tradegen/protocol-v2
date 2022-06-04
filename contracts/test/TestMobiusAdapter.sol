// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract TestMobiusAdapter {

    mapping (address => uint256) public prices;
    address public swapAddress;

    constructor() {}

    function setPrice(address _asset, uint256 _price) external {
        prices[_asset] = _price;
    }

    function getPrice(address _asset) external view returns (uint256) {
        // Simulate reverted transaction in the actual MobiusAdapter.
        require(prices[_asset] > 0, "TestMobiusAdapter: Asset is not supported.");

        return prices[_asset];
    }

    function setSwapAddress(address _swap) external {
        swapAddress = _swap;
    }

    function getSwapAddress(address _pair) external view returns (address) {
        return swapAddress;
    }
}