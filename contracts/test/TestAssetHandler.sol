// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract TestAssetHandler {

    address public stableCoinAddress;
    mapping (address => uint256) public assetTypes;

    constructor() {}

    function isValidAsset(address asset) external view returns (bool) {
        return (assetTypes[asset] > 0 || asset == stableCoinAddress);
    }

    function setValidAsset(address asset) external {
        assetTypes[asset] = 1;
    }

    function setStableCoinAddress(address asset) external {
        stableCoinAddress = asset;
    }
}