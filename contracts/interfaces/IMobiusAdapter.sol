// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IMobiusAdapter {
    /**
    * @dev Given an input asset address, returns the price of the asset in USD
    * @param currencyKey Address of the asset
    * @return uint Price of the asset
    */
    function getPrice(address currencyKey) external view returns (uint);

    /**
    * @dev Returns the staking token address for each available farm on Mobius
    * @return address[] The staking token address for each available farm
    */
    function getAvailableMobiusFarms() external view returns (address[] memory);

    /**
    * @dev Checks whether the given liquidity pair has a farm on Mobius
    * @param pair Address of the liquidity pair
    * @return bool Whether the pair has a farm
    */
    function checkIfLPTokenHasFarm(address pair) external view returns (bool);

    /**
    * @dev Returns the address of a token pair
    * @param tokenA First token in pair
    * @param tokenB Second token in pair
    * @return address The pair's address
    */
    function getPair(address tokenA, address tokenB) external view returns (address);

    /**
    * @dev Returns the amount of MOBI rewards available for the pool in the given farm
    * @param poolAddress Address of the pool
    * @param pid ID of the farm on Mobius
    * @return uint Amount of MOBI available
    */
    function getAvailableRewards(address poolAddress, uint pid) external view returns (uint);

    /**
    * @dev Calculates the amount of tokens in a pair
    * @param tokenA First token in pair
    * @param tokenB Second token in pair
    * @param numberOfLPTokens Number of LP tokens for the given pair
    * @return (uint, uint) The number of tokens for tokenA and tokenB
    */
    function getTokenAmountsFromPair(address tokenA, address tokenB, uint numberOfLPTokens) external view returns (uint, uint);
}