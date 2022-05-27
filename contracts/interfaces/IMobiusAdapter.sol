// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IMobiusAdapter {
    /**
    * @notice Given an input asset address, returns the price of the asset in USD.
    * @param _currencyKey Address of the asset.
    * @return price Price of the asset.
    */
    function getPrice(address _currencyKey) external view returns (uint256 price);

    /**
    * @notice Returns the staking token address for each available farm on Mobius.
    * @return (address[], uint256[]) The staking token address and farm ID for each available farm.
    */
    function getAvailableMobiusFarms() external view returns (address[] memory, uint256[] memory);

    /**
    * @notice Checks whether the given liquidity pair has a farm on Mobius.
    * @param _pair Address of the liquidity pair.
    * @return bool Whether the pair has a farm.
    */
    function checkIfLPTokenHasFarm(address _pair) external view returns (bool);

    /**
    * @notice Returns the address of a token pair.
    * @param _tokenA First token in pair.
    * @param _tokenB Second token in pair.
    * @return address The pair's address.
    */
    function getPair(address _tokenA, address _tokenB) external view returns (address);

    /**
    * @notice Returns the amount of MOBI rewards available for the pool in the given farm.
    * @param _poolAddress Address of the pool.
    * @param _pid ID of the farm on Mobius.
    * @return uint Amount of MOBI available.
    */
    function getAvailableRewards(address _poolAddress, uint256 _pid) external view returns (uint256);

    /**
    * @notice Returns the address of the LP token's Swap contract.
    * @param _pair Address of the liquidity pair.
    * @return address Address of the LP token's Swap contract.
    */
    function getSwapAddress(address _pair) external view returns (address);
}