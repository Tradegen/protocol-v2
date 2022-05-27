// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IRegistry {

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Deploys a CappedPool contract and its NFT.
    * @param _name Name of the pool.
    * @param _seedPrice The initial pool token price.
    * @param _supplyCap Maximum number of pool tokens that can be minted.
    * @param _performanceFee The percentage of profits that the pool manager receives whenever users withdraw for a profit. Denominated by 10000.
    */
    function createCappedPool(string memory _name, uint256 _seedPrice, uint256 _supplyCap, uint256 _performanceFee) external;

    /**
    * @notice Deploys a new Pool contract.
    * @param _poolName Name of the pool.
    * @param _performanceFee Performance fee for the pool.
    */
    function createPool(string memory _poolName, uint256 _performanceFee) external;
}