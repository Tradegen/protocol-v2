// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IPool {
    /**
    * @notice Returns the pool manager's address.
    */
    function manager() external view returns (address);

    /**
    * @dev Returns the value of the pool in USD.
    */
    function getPoolValue() external view returns (uint256);

    /**
    * @notice Deposits the given depositAsset amount into the pool.
    * @dev Call depositAsset.approve() before calling this function.
    * @param _depositAsset address of the asset to deposit.
    * @param _amount Amount of depositAsset to deposit into the pool.
    */
    function deposit(address _depositAsset, uint256 _amount) external;

    /**
    * @notice Withdraws the given number of pool tokens from the user.
    * @param _numberOfPoolTokens Number of pool tokens to withdraw.
    */
    function withdraw(uint256 _numberOfPoolTokens) external;

    /**
    * @notice Returns the USD value of the asset.
    * @param _asset Address of the asset.
    * @param _assetHandlerAddress Address of AssetHandler contract.
    */
    function getAssetValue(address _asset, address _assetHandlerAddress) external view returns (uint256);

    /**
    * @notice Returns the price of the pool's token.
    */
    function tokenPrice() external view returns (uint256);

    /**
    * @notice Initializes the pool's PoolManagerLogic contract.
    * @dev Only the Registry contract can call this function.
    * @dev This function is meant to only be called once, when creating the pool.
    * @param _poolManagerLogicAddress Address of the PoolManagerLogic contract.
    */
    function setPoolManagerLogic(address _poolManagerLogicAddress) external;
}