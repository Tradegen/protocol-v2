// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface ISwap {
    /**
     * @notice Get the virtual price, to help calculate profit
     * @return the virtual price, scaled to the POOL_PRECISION_DECIMALS
     */
    function getVirtualPrice() external view returns (uint256);

    /**
        @notice Returns address of lp token
        @return address of lp token
     */
     function getLpToken() external view returns (address);
}