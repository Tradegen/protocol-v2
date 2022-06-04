// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract TestMoolaAdapter {

    mapping (address => uint256) public prices;
    address public underlyingAsset;

    constructor() {}

    function setPrice(address _asset, uint256 _price) external {
        prices[_asset] = _price;
    }

    function getPrice(address _asset) external view returns (uint256) {
        // Simulate reverted transaction in the actual MoolaAdapter.
        require(prices[_asset] > 0, "TestMoolaAdapter: Asset is not supported.");

        return prices[_asset];
    }

    function setUnderlyingAsset(address _asset) external {
        underlyingAsset = _asset;
    }

    function getUnderlyingAsset(address) external view returns (address) {
        return underlyingAsset;
    }

    function getAssetsForLendingPool(address) external view returns (address, address) {
        return (underlyingAsset, underlyingAsset);
    }
}