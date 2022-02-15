// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IMobiusLPVerifier {
    /**
    * @dev Given the staking token of a farm, returns the farm's ID and the reward token.
    * @notice Returns address(0) for staking token if the farm ID is not valid.
    * @param _stakingToken Address of the farm's staking token.
    * @return (address, address) Address of the staking token and reward token.
    */
    function getFarmID(address _stakingToken) external view returns (uint, address);
}