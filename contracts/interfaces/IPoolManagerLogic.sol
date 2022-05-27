// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IPoolManagerLogic {
    struct AssetInfo {
        bool isAvailable;
        bool useForDeposits;
    }

     /**
    * @notice Returns whether this pool can hold the given asset.
    * @param _asset Address of the asset.
    * @return bool Whether this pool can hold the asset.
    */
    function isAvailableAsset(address _asset) external view returns (bool);

    /**
    * @notice Returns whether the pool accepts the given asset for deposits.
    * @param _asset Address of the asset.
    * @return bool Whether this pool can accept the asset for deposits.
    */
    function isDepositAsset(address _asset) external view returns (bool);

    /**
    * @notice Returns a list of assets that can be deposited into the pool.
    */
    function getDepositAssets() external view returns (address[] memory);

    /**
    * @notice Returns a list of assets that the pool can hold.
    */
    function getAvailableAssets() external view returns (address[] memory);

    /**
    * @notice Returns the pool's performance fee.
    */
    function performanceFee() external view returns (uint256);

    /**
    * @notice Adds a new asset to the list of acceptable assets for deposits.
    * @param _asset Address of the asset.
    */
    function addDepositAsset(address _asset) external;

    /**
    * @notice Removes an asset from the list of acceptable assets for deposits.
    * @param _asset Address of the asset.
    */
    function removeDepositAsset(address _asset) external;

    /**
    * @notice Updates the pool's performance fee.
    * @param _performanceFee The new performance fee.
    */
    function setPerformanceFee(uint256 _performanceFee) external;

    /**
    * @notice Adds a new asset to the list of assets the pool can hold.
    * @param _asset Address of the asset.
    */
    function addAvailableAsset(address _asset) external;

    /**
    * @notice Removes an asset from the list of assets the pool can hold.
    * @param _asset Address of the asset.
    */
    function removeAvailableAsset(address _asset) external;
}