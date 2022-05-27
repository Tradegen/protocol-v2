// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract TestMobiusSwap {

    uint256 public price;
    address public lpToken;

    constructor() {}

    function setVirtualPrice(uint256 _price) external {
        price = _price;
    }

    function getVirtualPrice() external view returns (uint256) {
        return price;
    }

    function setLPToken(address _token) external {
        lpToken = _token;
    }

    function getLpToken() external view returns (address) {
        return lpToken;
    }
}

