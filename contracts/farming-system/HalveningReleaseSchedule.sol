// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "../openzeppelin-solidity/contracts/SafeMath.sol";

import "../interfaces/farming-system/IReleaseSchedule.sol";

/**
 * A release schedule with a "halvening" event occuring every 26 weeks.
 * Halvening events last indefinitely.
 */
contract HalveningReleaseSchedule is IReleaseSchedule {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    uint256 public constant override cycleDuration = 26 weeks;
    uint256 public immutable firstCycleDistribution;
    uint256 public immutable distributionStartTime;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @param firstCycleDistribution_ Number of tokens to distribute in the first cycle.
     */
    constructor(uint256 firstCycleDistribution_, uint256 startTime_) {
        distributionStartTime = startTime_;
        firstCycleDistribution = firstCycleDistribution_;
    }

    /* ========== VIEWS ========== */

    /**
     * @dev Returns the total number of tokens that will be released in the given cycle.
     * @param _cycleIndex index of the cycle to check.
     * @return (uint256) total number of tokens released during the given cycle.
     */
    function getTokensForCycle(uint256 _cycleIndex) public view override returns (uint256) {
        return (_cycleIndex > 0) ? firstCycleDistribution.div(2 ** _cycleIndex.sub(1)) : 0;
    }

    /**
     * @dev Returns the index of the current cycle.
     * @return (uint256) index of the current cycle.
     */
    function getCurrentCycle() public view override returns (uint256) {
        return (block.timestamp >= distributionStartTime) ? ((block.timestamp.sub(distributionStartTime)).div(cycleDuration)).add(1) : 0;
    }

    /**
     * @dev Returns the starting timestamp of the given cycle.
     * @param _cycleIndex index of the cycle to check.
     * @return (uint256) starting timestamp of the cycle.
     */
    function getStartOfCycle(uint256 _cycleIndex) public view override returns (uint256) {
        return (_cycleIndex > 0) ? distributionStartTime.add((_cycleIndex.sub(1)).mul(cycleDuration)) : 0;
    }

    /**
     * @dev Given the index of a cycle, returns the number of tokens unlocked per second during the cycle.
     * @param _cycleIndex index of the cycle to check.
     * @return (uint256) number of tokens per second.
     */
    function getRewardRate(uint256 _cycleIndex) public view override returns (uint256) {
        return getTokensForCycle(_cycleIndex).div(cycleDuration);
    }

    /**
     * @dev Returns the number of tokens unlocked per second in the current cycle.
     * @return (uint256) number of tokens per second.
     */
    function getCurrentRewardRate() public view override returns (uint256) {
        return getRewardRate(getCurrentCycle());
    }

    /**
     * @dev Returns the starting timestamp of the current cycle.
     * @return (uint256) starting timestamp.
     */
    function getStartOfCurrentCycle() public view override returns (uint256) {
        return getStartOfCycle(getCurrentCycle());
    }

    /**
     * @dev Returns the amount of rewards available, based on the given timestamp.
     * @param _lastClaimTime The timestamp of last rewards claim; used for calculating elapsed time.
     * @return (uint256) number of tokens available.
     */
    function availableRewards(uint256 _lastClaimTime) external view override returns (uint256) {
        if (_lastClaimTime < distributionStartTime) {
            return 0;
        }

        // Check for cross-cycle rewards
        if (_lastClaimTime < getStartOfCurrentCycle()) {
            return ((getStartOfCurrentCycle().sub(_lastClaimTime)).mul(getCurrentRewardRate().mul(2))).add((block.timestamp.sub(getStartOfCurrentCycle())).mul(getCurrentRewardRate()));
        }
        
        return (block.timestamp.sub(_lastClaimTime)).mul(getCurrentRewardRate());
    }
}