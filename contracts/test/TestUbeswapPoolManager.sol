// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "../interfaces/Ubeswap/IUbeswapPoolManager.sol";

contract TestUbeswapPoolManager is IUbeswapPoolManager {

    uint256 public override poolsCount;
    mapping (uint256 => address) public override poolsByIndex;
    mapping (address => PoolInfo) public override pools;

    constructor() {}

    function setPoolsCount(uint256 _count) external {
        poolsCount = _count;
    }

    function setPoolsByIndex(uint256 _index, address _poolAddress) external {
        poolsByIndex[_index] = _poolAddress;
    }

    function setPools(uint256 _index, address _stakingTokenAddress, address _poolAddress, uint256 _weight, uint256 _nextPeriod) external {
        pools[_poolAddress] = PoolInfo({
            index: _index,
            stakingToken: _stakingTokenAddress,
            poolAddress: _poolAddress,
            weight: _weight,
            nextPeriod: _nextPeriod
        });
    }
}