// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract TestUniswapPair {

    address public token0_;
    address public token1_;
    uint256 public totalSupply_;
    uint256 public reserve0;
    uint256 public reserve1;

    constructor() {}

    function getReserves() external view returns (uint112, uint112, uint32) {
        return (uint112(reserve0), uint112(reserve1), uint32(0));
    }

    function setToken0(address _token0) external {
        token0_ = _token0;
    }

    function setToken1(address _token1) external {
        token1_ = _token1;
    }

    function setTotalSupply(uint256 _totalSupply) external {
        totalSupply_ = _totalSupply;
    }

    function setReserve0(uint256 _reserve0) external {
        reserve0 = _reserve0;
    }

    function setReserve1(uint256 _reserve1) external {
        reserve1 = _reserve1;
    }

    function token0() external view returns (address) {
        return token0_;
    }

    function token1() external view returns (address) {
        return token1_;
    }

    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }
}
