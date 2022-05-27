// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface ISettings {
    /**
    * @notice Returns the value of the given parameter.
    * @param _parameter The name of the parameter.
    * @return uint256 The value of the given parameter.
    */
    function getParameterValue(string memory _parameter) external view returns (uint256);
}