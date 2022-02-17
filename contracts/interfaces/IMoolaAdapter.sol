// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IMoolaAdapter {
    /**
    * @dev Given an input asset address, returns the price of the asset in USD
    * @notice Returns 0 if the asset is not supported
    * @param currencyKey Address of the asset
    * @return price Price of the asset
    */
    function getPrice(address currencyKey) external view returns (uint price);

    /**
    * @dev Returns the address of each lending pool available on Moola
    * @return address[] The address of each lending pool on Moola
    */
    function getAvailableMoolaLendingPools() external view returns (address[] memory);

    /**
    * @dev Checks whether the given token has a lending pool on Moola
    * @param token Address of the token
    * @return bool Whether the token has a lending pool
    */
    function checkIfTokenHasLendingPool(address token) external view returns (bool);

    /**
    * @dev Returns the address of the token's lending pool contract, if it exists
    * @param token Address of the token
    * @return address Address of the token's lending pool contract
    */
    function getLendingPoolAddress(address token) external view returns (address);
}