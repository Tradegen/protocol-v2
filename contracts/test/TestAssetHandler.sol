// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract TestAssetHandler {

    address public stableCoinAddress;
    mapping (address => uint256) public assetTypes;
    mapping (uint256 => address[]) public assets;
    mapping (address => address) public verifiers;
    mapping (address => uint256) public balances;

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

    function getUSDPrice(address) external view returns (uint256) {
        return 1e18;
    }

    function getBalance(address, address _asset) external view returns (uint256) {
        return balances[_asset];
    }

    function getDecimals(address) external view returns (uint256) {
        return 18;
    }

    function setVerifier(address _asset, address _verifier) external {
        verifiers[_asset] = _verifier;
    }

    function getVerifier(address _asset) external view returns (address) {
        return verifiers[_asset];
    }

    function setBalance(address _asset, uint256 _amount) external {
        balances[_asset] = _amount;
    }

    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }
}