// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract TestAssetVerifier {

    // (user address => asset address => balance).
    mapping (address => mapping (address => uint256)) public balances;

    constructor() {}

    function setBalance(address _user, address _asset, uint256 _balance) external {
        balances[_user][_asset] = _balance;
    }

    function getBalance(address _user, address _asset) external view returns (uint256) {
        return balances[_user][_asset];
    }

    function getDecimals(address _asset) external pure returns (uint256) {
        return 18;
    }
}

