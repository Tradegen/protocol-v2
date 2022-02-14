// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IPoolManagerLogic {
    struct AssetInfo {
        bool isAvailable;
        bool useForDeposits;
    }

    /**
    * @dev Returns a list of assets that can be deposited into the pool.
    */
    function getDepositAssets() external view returns (address[] memory);

    /**
    * @dev Returns a list of assets that the pool can hold.
    */
    function getAvailableAssets() external view returns (address[] memory);

    /**
    * @dev Returns the pool's performance fee.
    */
    function performanceFee() external view returns (uint);

    /**
    * @dev Adds a new asset to the list of acceptable assets for deposits.
    * @param _asset Address of the asset.
    */
    function addDepositAsset(address _asset) external;

    /**
    * @dev Removes an asset from the list of acceptable assets for deposits.
    * @param _asset Address of the asset.
    */
    function removeDepositAsset(address _asset) external;

    /**
    * @dev Updates the pool's performance fee.
    * @param _performanceFee The new performance fee.
    */
    function setPerformanceFee(uint _performanceFee) external;

    /**
    * @dev Adds a new asset to the list of assets the pool can hold.
    * @param _asset Address of the asset.
    */
    function addAvailableAsset(address _asset) external;

    /**
    * @dev Removes an asset from the list of assets the pool can hold.
    * @param _asset Address of the asset.
    */
    function removeAvailableAsset(address _asset) external;
}