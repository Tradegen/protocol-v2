// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface ICappedPoolFactory {

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Creates a new pool.
    * @param _manager Address of the pool's manager.
    * @param _poolName Name of the pool.
    * @param _maxSupply Maximum number of pool tokens.
    * @param _seedPrice Initial price of pool tokens.
    */
    function createCappedPool(address _manager, string memory _poolName, uint256 _maxSupply, uint256 _seedPrice) external returns (address);
}