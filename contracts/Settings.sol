// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Interfaces
import './interfaces/ISettings.sol';

//Inheritance
import './openzeppelin-solidity/contracts/Ownable.sol';

contract Settings is ISettings, Ownable {
    // (parameter name => parameter value).
    mapping (string => uint256) public parameters;

    constructor() Ownable() {}

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the value of the given parameter.
    * @param _parameter The name of the parameter.
    * @return uint256 The value of the given parameter.
    */
    function getParameterValue(string memory _parameter) external view override returns (uint256) {
        return parameters[_parameter];
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Updates the address for the given contract.
    * @dev This function can only be called by the owner of the Settings contract.
    * @param _parameter The name of the parameter to change
    * @param _newValue The new value of the given parameter
    */
    function setParameterValue(string memory _parameter, uint256 _newValue) external onlyOwner {
        require(_newValue >= 0, "Settings: Value cannot be negative.");

        uint256 oldValue = parameters[_parameter];
        parameters[_parameter] = _newValue;

        emit SetParameterValue(_parameter, oldValue, _newValue);
    }

    /* ========== MODIFIERS ========== */

    modifier isValidAddress(address _addressToCheck) {
        require(_addressToCheck != address(0), "Settings: Address is not valid.");
        _;
    }

    /* ========== EVENTS ========== */

    event SetParameterValue(string parameter, uint256 oldValue, uint256 newValue);
}