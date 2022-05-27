// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract TestUbeswapAdapter {

    mapping (address => mapping (address => address)) public pairs;
    mapping (address => uint256) public prices;

    constructor() {}

    function getPair(address _tokenA, address _tokenB) external view returns (address) {
        return pairs[_tokenA][_tokenB];
    }

    function setPair(address _tokenA, address _tokenB, address _lpToken) external {
        pairs[_tokenA][_tokenB] = _lpToken;
    }

    function setPrice(address _asset, uint256 _price) external {
        prices[_asset] = _price;
    }

    function getPrice(address _asset) external view returns (uint256) {
        // Simulate reverted transaction in the actual UbeswapAdapter.
        require(prices[_asset] > 0, "TestUbeswapAdapter: Asset is not supported.");

        return prices[_asset];
    }
}