// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IUbeswapLPVerifier {
    /**
    * @notice Given the address of a farm, returns the farm's staking token and reward token.
    * @param _farmAddress Address of the farm.
    * @return (address, address) Address of the staking token and reward token.
    */
    function getFarmTokens(address _farmAddress) external view returns (address, address);
}