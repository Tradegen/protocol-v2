// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

library TradegenMath {
  /**
  * @notice Calculates sqrt using the Babylonian Method.
  * @dev (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method).
  */
  function sqrt(uint256 y) internal pure returns (uint256 z) {
      if (y > 3) {
          z = y;
          uint x = y / 2 + 1;
          while (x < z) {
              z = x;
              x = (y / x + x) / 2;
          }
      } else if (y != 0) {
          z = 1;
      }
  }

  /**
    * @dev Scales a value based on the ratio of time elapsed to period duration.
    * @dev scalar = (currentTimestamp - startTimestamp) / duration
    * @dev x = (currentValue * scalar) + (previousValue * (1 - scalar))
    * @param currentValue value of a metric for the current period.
    * @param previousValue value of a metric for the previous period.
    * @param currentTimestamp the current timestamp; most likely "block.timestamp".
    * @param startTimestamp the timestamp at the start of the current period.
    * @param duration length of the period.
    * @return time-scaled value.
    */
    function scaleByTime(uint256 currentValue, uint256 previousValue, uint256 currentTimestamp, uint256 startTimestamp, uint256 duration) internal pure returns (uint256) {
        // Prevent division by 0
        if (duration == 0) {
            return 0;
        }

        // Prevent underflow
        if (startTimestamp > currentTimestamp) {
            return 0;
        }

        // Prevent underflow
        if (duration + startTimestamp < currentTimestamp) {
            return 0;
        }

        return ((currentValue * (currentTimestamp - startTimestamp)) + (previousValue * (duration + startTimestamp - currentTimestamp))) / duration;
    }

    /**
    * @dev Calculate log2(x) rounding down, where x is unsigned 256-bit integer number.
    * @param x unsigned 256-bit integer number.
    * @return result log2(x) unsigned 256-bit integer number.
    */
    function log(uint256 x) internal pure returns (uint256 result) {
        result = 0;

        while (x > 1) {
            if (x >= 2**128) { x >>= 128; result += 128; }
            if (x >= 2**64) { x >>= 64; result += 64; }
            if (x >= 2**32) { x >>= 32; result += 32; }
            if (x >= 2**16) { x >>= 16; result += 16; }
            if (x >= 2**8) { x >>= 8; result += 8; }
            if (x >= 2**4) { x >>= 4; result += 4; }
            if (x >= 2**2) { x >>= 2; result += 2; }
            if (x >= 2**1) { x >>= 1; result += 1; }
        }

        return result;
    }
}