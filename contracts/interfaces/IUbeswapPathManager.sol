// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IUbeswapPathManager {
    /**
    * @notice Returns the path from '_fromAsset' to '_toAsset'.
    * @dev The path is found manually before being stored in this contract.
    * @param _fromAsset Token to swap from.
    * @param _toAsset Token to swap to.
    * @return address[] The pre-determined optimal path from '_fromAsset' to '_toAsset'.
    */
    function getPath(address _fromAsset, address _toAsset) external view returns (address[] memory);

    /**
    * @notice Sets the path from '_fromAsset' to '_toAsset'.
    * @dev The path is found manually before being stored in this contract.
    * @dev Only the contract owner can call this function.
    * @param _fromAsset Token to swap from.
    * @param _toAsset Token to swap to.
    * @param _newPath The pre-determined optimal path between the two assets.
    */
    function setPath(address _fromAsset, address _toAsset, address[] calldata _newPath) external;
}