// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IMoolaAdapter {
    /**
    * @notice Given an input asset address, returns the price of the asset in USD.
    * @dev Returns 0 if the asset is not supported.
    * @param _currencyKey Address of the asset.
    * @return price Price of the asset.
    */
    function getPrice(address _currencyKey) external view returns (uint price);

    /**
    * @notice Returns the address of each lending pool available on Moola.
    * @return address[] The address of each lending pool on Moola.
    */
    function getAvailableMoolaLendingPools() external view returns (address[] memory);

    /**
    * @notice Checks whether the given token has a lending pool on Moola.
    * @param _token Address of the token.
    * @return bool Whether the token has a lending pool.
    */
    function checkIfTokenHasLendingPool(address _token) external view returns (bool);

    /**
    * @notice Returns the address of the token's lending pool contract, if it exists.
    * @param _token Address of the token.
    * @return address Address of the token's lending pool contract.
    */
    function getLendingPoolAddress(address _token) external view returns (address);

    /**
    * @notice Given the address of a lending pool, returns the lending pool's interest-bearing token and underlying token.
    * @param _lendingPoolAddress Address of the lending pool.
    * @return (address, address) Address of the lending pool's interest-bearing token and address of the underlying token.
    */
    function getAssetsForLendingPool(address _lendingPoolAddress) external view returns (address, address);

    /**
    * @notice Given the address of an interest-bearing token, returns the token's underlying asset.
    * @param _interestBearingToken Address of the interest-bearing token.
    * @return address Address of the token's underlying asset.
    */
    function getUnderlyingAsset(address _interestBearingToken) external view returns (address);
}