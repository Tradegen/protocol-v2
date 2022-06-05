// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "../farming-system/PoolManager.sol";

contract TestPoolManager2 is PoolManager {
    constructor(address _rewardsToken, address _releaseSchedule, address _registry, address _stakingRewardsFactory, address _TGEN, address _xTGEN)
        PoolManager(_rewardsToken, _releaseSchedule, _registry, _stakingRewardsFactory, _TGEN, _xTGEN) {}

    function setPoolStatus(address _pool, bool _status) external {
        pools[_pool].isEligible = _status;
    }
}