// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import './openzeppelin-solidity/contracts/SafeMath.sol';
import './openzeppelin-solidity/contracts/Ownable.sol';
import './openzeppelin-solidity/contracts/ERC20/SafeERC20.sol';

//Libraries
import "./libraries/TxDataUtils.sol";

//Interfaces
import "./interfaces/IExternalStorage.sol";
import "./interfaces/IUsers.sol";

contract ExternalStorage is IExternalStorage, TxDataUtils, Ownable {
    using SafeERC20 for IERC20;

    IUsers public immutable users;

    bytes32[] public attributeNames;
    IERC20 public feeToken;
    address public feeRecipient;
    address public operator; // User ERC1155 contract
    mapping(bytes32 => Attribute) public attributes;

    //Data storage
    //Maps from attribute name => NFT ID => data
    mapping(bytes32 => mapping (uint => uint)) internal uintStorage;
    mapping(bytes32 => mapping (uint => bool)) internal boolStorage;
    mapping(bytes32 => mapping (uint => address)) internal addressStorage;
    mapping(bytes32 => mapping (uint => bytes32)) internal bytes32Storage;
    mapping(bytes32 => mapping (uint => string)) internal stringStorage;

    //Used for checking if an attribute's value is unique
    //Maps from attribute name => data => NFT ID
    mapping(bytes32 => mapping (bytes => uint)) internal bytesData;

    constructor(address _feeToken, address _feeRecipient, address _users) Ownable() {
        require(_feeToken != address(0), "ExternalStorage: Invalid fee token.");
        require(_feeRecipient != address(0), "ExternalStorage: Invalid fee recipient.");

        feeToken = IERC20(_feeToken);
        feeRecipient = _feeRecipient;
        users = IUsers(_users);
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Given the name of an attribute, returns the attribute's variable type
    * @param _attributeName Name of the attribute
    * @return (string, uint) The attribute's variable type and update fee
    */
    function getAttribute(bytes32 _attributeName) external view override isValidAttributeName(_attributeName) returns (bytes32, uint) {
        return (attributes[_attributeName].variableType, attributes[_attributeName].updateFee);
    }

    /**
    * @dev Returns the name, variable type, and update fee for each attribute
    * @return (bytes32[], bytes32[], uint[]) The name, variable type, and update fee of each attribute
    */
    function getAttributes() external view override returns (bytes32[] memory, bytes32[] memory, uint[] memory) {
        bytes32[] memory names = attributeNames;
        bytes32[] memory types = new bytes32[](names.length);
        uint[] memory fees = new uint[](names.length);

        for (uint i = 0; i < names.length; i++) {
            types[i] = attributes[attributeNames[i]].variableType;
            fees[i] = attributes[attributeNames[i]].updateFee;
        }

        return (names, types, fees);
    }

    /**
    * @dev Returns the bytes data and variable type of an attribute
    * @dev The calling function needs to parse the bytes data based on the variable type
    * @param _id NFT id
    * @param _attributeName Name of the attribute
    * @return (bytes, bytes32) Bytes data of the attribute and the attribute's variable type
    */
    function getValue(uint _id, bytes32 _attributeName) external view override isValidId(_id) isValidAttributeName(_attributeName) returns (bytes memory, bytes32) {
        bytes32 variableType = attributes[_attributeName].variableType;
        bytes memory rawBytes;

        if (keccak256(abi.encodePacked(variableType)) == keccak256(abi.encodePacked("uint"))) {
            rawBytes = abi.encodePacked(uintStorage[_attributeName][_id]);
        }
        else if (keccak256(abi.encodePacked(variableType)) == keccak256(abi.encodePacked("bool"))) {
            rawBytes = abi.encodePacked(boolStorage[_attributeName][_id]);
        }
        else if (keccak256(abi.encodePacked(variableType)) == keccak256(abi.encodePacked("address"))) {
            rawBytes = abi.encodePacked(addressStorage[_attributeName][_id]);
        }
        else if (keccak256(abi.encodePacked(variableType)) == keccak256(abi.encodePacked("bytes32"))) {
            rawBytes = abi.encodePacked(bytes32Storage[_attributeName][_id]);
        }
        else if (keccak256(abi.encodePacked(variableType)) == keccak256(abi.encodePacked("string"))) {
            rawBytes = bytes(stringStorage[_attributeName][_id]);
        }

        return (rawBytes, variableType);
    }

    /**
    * @dev Returns the attribute's value as a uint
    * @dev Reverts if the attribute is not found or if the attribute doesn't have uint type
    * @param _id NFT id
    * @param _attributeName Name of the attribute
    * @return (uint) Value of the attribute
    */
    function getUintValue(uint _id, bytes32 _attributeName) external view override isValidId(_id) isValidAttributeName(_attributeName) returns (uint) {
        require(keccak256(abi.encodePacked(attributes[_attributeName].variableType)) == keccak256(abi.encodePacked("uint")), "ExternalStorage: Expected uint type.");

        return uintStorage[_attributeName][_id];
    }

    /**
    * @dev Returns the attribute's value as a bool
    * @dev Reverts if the attribute is not found or if the attribute doesn't have bool type
    * @param _id NFT id
    * @param _attributeName Name of the attribute
    * @return (bool) Value of the attribute
    */
    function getBoolValue(uint _id, bytes32 _attributeName) external view override isValidId(_id) isValidAttributeName(_attributeName) returns (bool) {
        require(keccak256(abi.encodePacked(attributes[_attributeName].variableType)) == keccak256(abi.encodePacked("bool")), "ExternalStorage: Expected bool type.");

        return boolStorage[_attributeName][_id];
    }

    /**
    * @dev Returns the attribute's value as a bytes32
    * @dev Reverts if the attribute is not found or if the attribute doesn't have bytes32 type
    * @param _id NFT id
    * @param _attributeName Name of the attribute
    * @return (bytes32) Value of the attribute
    */
    function getBytes32Value(uint _id, bytes32 _attributeName) external view override isValidId(_id) isValidAttributeName(_attributeName) returns (bytes32) {
        require(keccak256(abi.encodePacked(attributes[_attributeName].variableType)) == keccak256(abi.encodePacked("bytes32")), "ExternalStorage: Expected bytes32 type.");

        return bytes32Storage[_attributeName][_id];
    }

    /**
    * @dev Returns the attribute's value as an address
    * @dev Reverts if the attribute is not found or if the attribute doesn't have address type
    * @param _id NFT id
    * @param _attributeName Name of the attribute
    * @return (address) Value of the attribute
    */
    function getAddressValue(uint _id, bytes32 _attributeName) external view override isValidId(_id) isValidAttributeName(_attributeName) returns (address) {
        require(keccak256(abi.encodePacked(attributes[_attributeName].variableType)) == keccak256(abi.encodePacked("address")), "ExternalStorage: Expected address type.");

        return addressStorage[_attributeName][_id];
    }

    /**
    * @dev Returns the attribute's value as a string
    * @dev Reverts if the attribute is not found or if the attribute doesn't have string type
    * @param _id NFT id
    * @param _attributeName Name of the attribute
    * @return (string) Value of the attribute
    */
    function getStringValue(uint _id, bytes32 _attributeName) external view override isValidId(_id) isValidAttributeName(_attributeName) returns (string memory) {
        require(keccak256(abi.encodePacked(attributes[_attributeName].variableType)) == keccak256(abi.encodePacked("string")), "ExternalStorage: Expected string type.");

        return stringStorage[_attributeName][_id];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @dev Adds an attribute to the Template
    * @param _attributeName Name of the attribute to add
    * @param _attributeType The variable type of the attribute
    * @param _updateFee Fee that a user pays when updating an attribute
    * @param _canModify Whether the attribute value can be modified after it is initialized.
    * @return (bool) Whether the attribute was added successfully
    */
    function addAttribute(bytes32 _attributeName, bytes32 _attributeType, uint _updateFee, bool _unique, bool _canModify) external override onlyOwner returns (bool) {
        if (attributes[_attributeName].name == _attributeName) {
            return false;
        }

        attributes[_attributeName] = Attribute(_unique, _canModify, _updateFee, _attributeName, _attributeType);
        attributeNames.push(_attributeName);

        return true;
    }

    /**
    * @dev Adds multiple attributes to the Template
    * @param _attributeNames Names of the attributes to add
    * @param _attributeTypes The variable types of the attributes
    * @param _updateFees Fee that a user pays when updating each attribute
    * @param _unique Whether the attribute values must be unique throughout a Template
    * @param _canModify Whether the attribute values can be modified after they are initialized.
    * @return (bool) Whether the attributes were added successfully
    */
    function addAttributes(bytes32[] calldata _attributeNames, bytes32[] calldata _attributeTypes, uint[] calldata _updateFees, bool[] calldata _unique, bool[] calldata _canModify) external override onlyOwner returns (bool) {
        if (_attributeNames.length != _attributeTypes.length) {
            return false;
        }

        if (_attributeNames.length != _updateFees.length) {
            return false;
        }

        if (_attributeNames.length != _unique.length) {
            return false;
        }

        for (uint i = 0; i < _attributeNames.length; i++) {
            if (attributes[_attributeNames[i]].name == _attributeNames[i]) {
                return false;
            }

            attributes[_attributeNames[i]] = Attribute(_unique[i], _canModify[i], _updateFees[i], _attributeNames[i], _attributeTypes[i]);
            attributeNames.push(_attributeNames[i]);
        }

        emit AddedAttributes(_attributeNames, _attributeTypes, _updateFees, _unique);

        return true;
    }

    /**
    * @dev Sets the attribute's updateFee to the new fee
    * @param _attributeName Name of the attribute to add
    * @param _newFee The new updateFee
    * @return (bool) Whether the fee was updated successfully
    */
    function updateAttributeFee(bytes32 _attributeName, uint _newFee) external override onlyOwner returns (bool) {
        if (attributes[_attributeName].name != _attributeName) {
            return false;
        }

        if (_newFee < 0) {
            return false;
        }

        attributes[_attributeName].updateFee = _newFee;

        emit UpdatedAttributeFee(_attributeName, _newFee);

        return true;
    }

    /**
    * @dev Initializes an attribute to the given value; avoids paying the updateFee
    * @param _id NFT id
    * @param _attributeName Name of the attribute
    * @param _initialValue Initial value of the attribute
    * @return (bool) Whether the attribute was initialized successfully
    */
    function initializeValue(uint _id, bytes32 _attributeName, bytes calldata _initialValue) external override onlyOperator returns (bool) {
        if (attributes[_attributeName].name != _attributeName) {
            return false;
        }

        if (_id == 0) {
            return false;
        }

        //Check if attribute value already exists
        if (attributes[_attributeName].unique && bytesData[_attributeName][_initialValue] > 0) {
            return false;
        }

        return _setValueByType(_id, _attributeName, attributes[_attributeName].variableType, _initialValue);
    }

    /**
    * @dev Initializes multiple attributes
    * @param _id NFT id
    * @param _attributeNames Name of the attributes
    * @param _initialValues Initial values of the attributes
    * @return (bool) Whether the attributes were initialized successfully
    */
    function initializeValues(uint _id, bytes32[] calldata _attributeNames, bytes[] calldata _initialValues) external override onlyOperator returns (bool) {
        if (_id == 0) {
            return false;
        }

        for (uint i = 0; i < _attributeNames.length; i++) {
            if (attributes[_attributeNames[i]].name != _attributeNames[i]) {
                return false;
            }

            //Check if attribute value is unique
            if (attributes[_attributeNames[i]].unique && bytesData[_attributeNames[i]][_initialValues[i]] > 0) {
                return false;
            }

            if (!_setValueByType(_id, _attributeNames[i], attributes[_attributeNames[i]].variableType, _initialValues[i])) {
                return false;
            }
        }

        return true;
    }

    /**
    * @dev Sets the attribute's value to the new value
    * @param _attributeName Name of the attribute
    * @param _newValue New value of the attribute
    */
    function updateValue(bytes32 _attributeName, bytes calldata _newValue) external override {
        uint id = users.getUser(msg.sender);

        require(id > 0, "ExternalStorage: user has not created a profile yet.");
        require(!attributes[_attributeName].canModify, "ExternalStorage: attribute cannot be modified.");
        require(attributes[_attributeName].name == _attributeName, "ExternalStorage: attribute does not exist.");
        require(!(attributes[_attributeName].unique && bytesData[_attributeName][_newValue] > 0), "ExternalStorage: attribute must have a unique value.");

        // Pay fee for updating attribute value.
        feeToken.safeTransferFrom(msg.sender, feeRecipient, attributes[_attributeName].updateFee);

        require(_setValueByType(id, _attributeName, attributes[_attributeName].variableType, _newValue), "ExternalStorage: error when updating value.");

        emit UpdatedValue(msg.sender, id, _attributeName, _newValue);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _setValueByType(uint _id, bytes32 _attributeName, bytes32 _variableType, bytes calldata _newValue) internal returns (bool) {
        //Check if value already exists
        if (attributes[_attributeName].unique && bytesData[_attributeName][_newValue] > 0) {
            return false;
        }
        else {
            bytesData[_attributeName][_newValue] = _id;
        }

        if (keccak256(abi.encodePacked(_variableType)) == keccak256("uint")) {
            uintStorage[_attributeName][_id] = uint(read32(_newValue, 0, 32));
        }
        else if (keccak256(abi.encodePacked(_variableType)) == keccak256("bool")) {
            boolStorage[_attributeName][_id] = !(uint(read32(_newValue, 0, 32)) == 0);
        }
        else if (keccak256(abi.encodePacked(_variableType)) == keccak256("address")) {
            addressStorage[_attributeName][_id] = convert32toAddress(read32(_newValue, 0, 32));
        }
        else if (keccak256(abi.encodePacked(_variableType)) == keccak256("bytes32")) {
            bytes32Storage[_attributeName][_id] = read32(_newValue, 0, 32);
        }
        else if (keccak256(abi.encodePacked(_variableType)) == keccak256("string")) {
            stringStorage[_attributeName][_id] = string(_newValue);
        }
        else {
            return false;
        }

        emit SetAttributeValue(_attributeName, _variableType, _newValue);

        return true;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setOperator(address _operator) external onlyOwner operatorNotSet {
        require(_operator != address(0), "ExternalStorage: invalid operator address.");

        operator = _operator;

        emit SetOperator(_operator);
    }

    function setAttributeMutability(bytes32 _attributeName, bool _canModify) external onlyOwner isValidAttributeName(_attributeName) {
        attributes[_attributeName].canModify = _canModify;

        emit UpdatedAttributeMutability(_attributeName, _canModify);
    }

    /* ========== MODIFIERS ========== */

    modifier operatorNotSet() {
        require(operator == address(0), "ExternalStorage: operator has already been set.");
        _;
    }

    modifier isValidId(uint _id) {
        require(_id > 0, "ExternalStorage: Id is not valid");
        _;
    } 

    modifier isValidAttributeName(bytes32 _name) {
        require(_name == attributes[_name].name, "ExternalStorage: Attribute not found.");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "ExternalStorage: Only operator can call this function.");
        _;
    } 

    /* ========== EVENTS ========== */

    event AddedAttribute(bytes32 name, bytes32 variableType, uint updateFee, bool unique);
    event AddedAttributes(bytes32[] names, bytes32[] variableTypes, uint[] updateFees, bool[] unique);
    event UpdatedAttributeFee(bytes32 name, uint newFee);
    event SetAttributeValue(bytes32 name, bytes32 variableType, bytes value);
    event SetOperator(address operator);
    event UpdatedValue(address indexed user, uint indexed profileID, bytes32 attributeName, bytes value);
    event UpdatedAttributeMutability(bytes32 attributeName, bool canModify);
}