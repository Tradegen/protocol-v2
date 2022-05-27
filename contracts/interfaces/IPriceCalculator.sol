// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IPriceCalculator {
    /**
    * @notice Returns the USD price of the given asset.
    * @param _asset Address of the asset.
    * @return uint256 USD price of the asset.
    */
    function getUSDPrice(address _asset) external view returns (uint256);
}