// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IExternalStorage {
    struct Attribute {
        bool initialized;
        bool unique;
        uint index;
        uint updateFee;
        bytes32 name;
        bytes32 variableType;
    }

    /**
    * @dev Adds an attribute to the Template
    * @param _attributeName Name of the attribute to add
    * @param _attributeType The variable type of the attribute
    * @param _updateFee Fee that a user pays when updating an attribute
    * @param _unique Whether the attribute values must be unique throughout a Template
    * @return (bool) Whether the attribute was added successfully
    */
    function addAttribute(bytes32 _attributeName, bytes32 _attributeType, uint _updateFee, bool _unique) external returns (bool);

    /**
    * @dev Adds multiple attributes to the Template
    * @param _attributeNames Names of the attributes to add
    * @param _attributeTypes The variable types of the attributes
    * @param _updateFees Fee that a user pays when updating each attribute
    * @param _unique Whether the attribute values must be unique throughout a Template
    * @return (bool) Whether the attributes were added successfully
    */
    function addAttributes(bytes32[] memory _attributeNames, bytes32[] memory _attributeTypes, uint[] memory _updateFees, bool[] memory _unique) external returns (bool);

    /**
    * @dev Given the name of an attribute, returns the attribute's variable type
    * @param _attributeName Name of the attribute
    * @return (bytes32, uint) The attribute's variable type and update fee
    */
    function getAttribute(bytes32 _attributeName) external view returns (bytes32, uint);

    /**
    * @dev Returns the name, variable type, and update fee for each attribute of the Template
    * @return (bytes32[], bytes32[], uint[]) The name, variable type, and update fee of each attribute
    */
    function getAttributes() external view returns (bytes32[] memory, bytes32[] memory, uint[] memory);

    /**
    * @dev Sets the attribute's updateFee to the new fee
    * @param _attributeName Name of the attribute to add
    * @param _newFee The new updateFee
    * @return (bool) Whether the fee was updated successfully
    */
    function updateAttributeFee(bytes32 _attributeName, uint _newFee) external returns (bool);

    /**
    * @dev Initializes an attribute to the given value; avoids paying the updateFee
    * @param _id NFT id
    * @param _attributeName Name of the attribute
    * @param _initialValue Initial value of the attribute
    * @return (bool) Whether the attribute was initialized successfully
    */
    function initializeValue(uint _id, bytes32 _attributeName, bytes calldata _initialValue) external returns (bool);

    /**
    * @dev Initializes multiple attributes
    * @param _id NFT id
    * @param _attributeNames Name of the attributes
    * @param _initialValues Initial values of the attributes
    * @return (bool) Whether the attributes were initialized successfully
    */
    function initializeValues(uint _id, bytes32[] calldata _attributeNames, bytes[] calldata _initialValues) external returns (bool);

    /**
    * @dev Sets the attribute's value to the new value
    * @param _user Address of the NFT owner
    * @param _id NFT id
    * @param _attributeName Name of the attribute
    * @param _newValue New value of the attribute
    * @return (bool) Whether the attribute's value was updated successfully
    */
    function updateValue(address _user, uint _id, bytes32 _attributeName, bytes calldata _newValue) external returns (bool);

    /**
    * @dev Returns the bytes data and variable type of an attribute
    * @dev The calling function needs to parse the bytes data based on the variable type
    * @param _id NFT id
    * @param _attributeName Name of the attribute
    * @return (bytes, bytes32) Bytes data of the attribute and the attribute's variable type
    */
    function getValue(uint _id, bytes32 _attributeName) external view returns (bytes memory, bytes32);

    /**
    * @dev Returns the attribute's value as a uint
    * @dev Reverts if the attribute is not found or if the attribute doesn't have uint type
    * @param _id NFT id
    * @param _attributeName Name of the attribute
    * @return (uint) Value of the attribute
    */
    function getUintValue(uint _id, bytes32 _attributeName) external view returns (uint); 

    /**
    * @dev Returns the attribute's value as a bool
    * @dev Reverts if the attribute is not found or if the attribute doesn't have bool type
    * @param _id NFT id
    * @param _attributeName Name of the attribute
    * @return (bool) Value of the attribute
    */
    function getBoolValue(uint _id, bytes32 _attributeName) external view returns (bool); 

    /**
    * @dev Returns the attribute's value as a bytes32
    * @dev Reverts if the attribute is not found or if the attribute doesn't have bytes32 type
    * @param _id NFT id
    * @param _attributeName Name of the attribute
    * @return (bytes32) Value of the attribute
    */
    function getBytes32Value(uint _id, bytes32 _attributeName) external view returns (bytes32); 

    /**
    * @dev Returns the attribute's value as an address
    * @dev Reverts if the attribute is not found or if the attribute doesn't have address type
    * @param _id NFT id
    * @param _attributeName Name of the attribute
    * @return (address) Value of the attribute
    */
    function getAddressValue(uint _id, bytes32 _attributeName) external view returns (address); 

    /**
    * @dev Returns the attribute's value as a string
    * @dev Reverts if the attribute is not found or if the attribute doesn't have string type
    * @param _id NFT id
    * @param _attributeName Name of the attribute
    * @return (string) Value of the attribute
    */
    function getStringValue(uint _id, bytes32 _attributeName) external view returns (string memory); 
}