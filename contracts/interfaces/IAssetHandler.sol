// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IAssetHandler {
    /**
    * @notice Given the address of an asset, returns the asset's price in USD.
    * @param _asset Address of the asset.
    * @return uint256 Price of the asset in USD.
    */
    function getUSDPrice(address _asset) external view returns (uint256);

    /**
    * @notice Given the address of an asset, returns whether the asset is supported on Tradegen.
    * @param _asset Address of the asset.
    * @return bool Whether the asset is supported.
    */
    function isValidAsset(address _asset) external view returns (bool);

    /**
    * @notice Given an asset type, returns the address of each supported asset for the type.
    * @param _assetType Type of asset.
    * @return address[] Address of each supported asset for the type.
    */
    function getAvailableAssetsForType(uint256 _assetType) external view returns (address[] memory);

    /**
    * @notice Returns the address of the stablecoin.
    * @return address The stable coin address.
    */
    function getStableCoinAddress() external view returns(address);

    /**
    * @notice Given the address of an asset, returns the asset's type.
    * @param _addressToCheck Address of the asset.
    * @return uint256 Type of the asset.
    */
    function getAssetType(address _addressToCheck) external view returns (uint256);

    /**
    * @notice Returns the pool's balance of the given asset.
    * @param _pool Address of the pool.
    * @param _asset Address of the asset.
    * @return uint256 Pool's balance of the asset.
    */
    function getBalance(address _pool, address _asset) external view returns (uint256);

    /**
    * @notice Returns the asset's number of decimals.
    * @param _asset Address of the asset.
    * @return uint256 Number of decimals.
    */
    function getDecimals(address _asset) external view returns (uint256);

    /**
    * @notice Given the address of an asset, returns the address of the asset's verifier.
    * @param _asset Address of the asset.
    * @return address Address of the asset's verifier.
    */
    function getVerifier(address _asset) external view returns (address);
}