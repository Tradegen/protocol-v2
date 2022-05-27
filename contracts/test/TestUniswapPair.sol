// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract TestUniswapPair {

    mapping (address => address) public token0;
    mapping (address => address) public token1;
    mapping (address => uint256) public totalSupply;
    mapping (address => uint256) public reserve0;
    mapping (address => uint256) public reserve1;

    constructor() {}

    function getReserves(address _pair) external view returns (uint256, uint256) {
        return (reserve0[_pair], reserve1[_pair]);
    }

    function setToken0(address _pair, address _token0) external {
        token0[_pair] = _token0;
    }

    function setToken1(address _pair, address _token1) external {
        token1[_pair] = _token1;
    }

    function setTotalSupply(address _pair, uint256 _totalSupply) external {
        totalSupply[_pair] = _totalSupply;
    }

    function setReserve0(address _pair, uint256 _reserve0) external {
        reserve0[_pair] = _reserve0;
    }

    function setReserve1(address _pair, uint256 _reserve1) external {
        reserve1[_pair] = _reserve1;
    }
}
