// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IRegistry {

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the number of tokens available for each class.
    * @param _cappedPool Address of the CappedPool contract.
    * @return (uint256, uint256, uint256, uint256) Number of available C1, C2, C3, and C4 tokens.
    */
    function getAvailableTokensPerClass(address _cappedPool) external view returns (uint256, uint256, uint256, uint256);

    /**
    * @notice Given the address of a user, returns the number of tokens the user has for each class.
    * @param _cappedPool Address of the CappedPool contract.
    * @param _user Address of the user.
    * @return (uint256, uint256, uint256, uint256) Number of available C1, C2, C3, and C4 tokens.
    */
    function getTokenBalancePerClass(address _cappedPool, address _user) external view returns (uint256, uint256, uint256, uint256);

    /**
    * @notice Returns the amount of stablecoin the pool, or capped pool, has to invest.
    */
    function getAvailableFunds(address _pool) external view returns (uint256);

    /**
    * @notice Returns the balance of the user in USD.
    */
    function getUSDBalance(address _user, address _pool, bool _isCappedPool) external view returns (uint256);

    /**
    * @notice Returns the currency address and balance of each position the pool has, as well as the cumulative value.
    * @param _pool Address of the pool, or capped pool.
    * @return (address[], uint256[], uint256) Currency address and balance of each position the pool has, and the cumulative value of positions.
    */
    function getPositionsAndTotal(address _pool) external view returns (address[] memory, uint256[] memory, uint256);

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