// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IPoolFactory {

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Creates a new Pool contract.
    * @param _poolName Name of the pool.
    * @param _manager Address of the pool's manager.
    * @return address The address of the deployed Pool contract.
    */
    function createPool(string memory _poolName, address _manager) external returns (address);
}