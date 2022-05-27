// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

import './Ubeswap/IUniswapV2Router02.sol';

interface IUbeswapAdapter {
    function MAX_SLIPPAGE_PERCENT() external returns (uint256);

    /**
    * @notice Given an input asset address, returns the price of the asset in USD.
    * @param _currencyKey Address of the asset.
    * @return uint Price of the asset.
    */
    function getPrice(address _currencyKey) external view returns (uint256);

    /**
    * @notice Given an input asset amount, returns the maximum output amount of the other asset.
    * @dev Assumes numberOfTokens is multiplied by currency's decimals before function call.
    * @param _numberOfTokens Number of tokens.
    * @param _currencyKeyIn Address of the asset to be swap from.
    * @param _currencyKeyOut Address of the asset to be swap to.
    * @return uint256 Amount out of the asset.
    */
    function getAmountsOut(uint256 _numberOfTokens, address _currencyKeyIn, address _currencyKeyOut) external view returns (uint256);

    /**
    * @notice Given the target output asset amount, returns the amount of input asset needed.
    * @param _numberOfTokens Target amount of output asset.
    * @param _currencyKeyIn Address of the asset to be swap from.
    * @param _currencyKeyOut Address of the asset to be swap to.
    * @return uint256 Amount out input asset needed.
    */
    function getAmountsIn(uint256 _numberOfTokens, address _currencyKeyIn, address _currencyKeyOut) external view returns (uint256);

    /**
    * @notice Returns the address of each available farm on Ubeswap.
    * @return address[] memory The farm address for each available farm.
    */
    function getAvailableUbeswapFarms() external view returns (address[] memory);

    /**
    * @notice Returns the address of a token pair.
    * @param _tokenA First token in pair.
    * @param _tokenB Second token in pair.
    * @return address The pair's address.
    */
    function getPair(address _tokenA, address _tokenB) external view returns (address);

    /**
    * @notice Returns the amount of UBE rewards available for the pool in the given farm.
    * @param _poolAddress Address of the pool.
    * @param _farmAddress Address of the farm on Ubeswap.
    * @return uint256 Amount of UBE available.
    */
    function getAvailableRewards(address _poolAddress, address _farmAddress) external view returns (uint256);

    /**
    * @notice Calculates the amount of tokens in a pair.
    * @param _tokenA First token in pair.
    * @param _tokenB Second token in pair.
    * @param _numberOfLPTokens Number of LP tokens for the given pair.
    * @return (uint256, uint256) The number of tokens for _tokenA and _tokenB.
    */
    function getTokenAmountsFromPair(address _tokenA, address _tokenB, uint256 _numberOfLPTokens) external view returns (uint256, uint256);
}