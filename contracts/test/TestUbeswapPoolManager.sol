// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

import "../interfaces/Ubeswap/IUbeswapPoolManager.sol";

contract TestUbeswapPoolManager is IUbeswapPoolManager {

    uint256 public override poolsCount;
    mapping (uint256 => address) public override poolsByIndex;
    mapping (address => PoolInfo) public poolInfos;

    constructor() {}

    function setPoolsCount(uint256 _count) external {
        poolsCount = _count;
    }

    function setPoolsByIndex(uint256 _index, address _poolAddress) external {
        poolsByIndex[_index] = _poolAddress;
    }

    function setPools(uint256 _index, address _stakingTokenAddress, address _poolAddress, uint256 _weight, uint256 _nextPeriod) external {
        poolInfos[_poolAddress] = PoolInfo({
            index: _index,
            stakingToken: _stakingTokenAddress,
            poolAddress: _poolAddress,
            weight: _weight,
            nextPeriod: _nextPeriod
        });
    }

    function pools(address _poolAddress) external view  override returns (PoolInfo memory) {
        return PoolInfo({
            index: poolInfos[_poolAddress].index,
            stakingToken: poolInfos[_poolAddress].stakingToken,
            poolAddress: poolInfos[_poolAddress].poolAddress,
            weight: poolInfos[_poolAddress].weight,
            nextPeriod: poolInfos[_poolAddress].nextPeriod
        });
    }
}