// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract TestAssetHandler {

    address public stableCoinAddress;
    mapping (address => uint256) public assetTypes;
    mapping (uint256 => address[]) public assets;

    constructor() {}

    function isValidAsset(address asset) external view returns (bool) {
        return (assetTypes[asset] > 0 || asset == stableCoinAddress);
    }

    function setValidAsset(address asset, uint256 _type) external {
        assetTypes[asset] = 1;
        assets[_type].push(asset);
    }

    function setStableCoinAddress(address asset) external {
        stableCoinAddress = asset;
    }

    function getAvailableAssetsForType(uint256 _type) external view returns (address[] memory) {
        address[] memory ret = new address[](assets[_type].length);

        for (uint256 i = 0; i < ret.length; i++) {
            ret[i] = assets[_type][i];
        }

        return ret;
    }

    function getStableCoinAddress() external view returns (address) {
        return stableCoinAddress;
    }
}