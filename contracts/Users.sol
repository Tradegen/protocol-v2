// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import './openzeppelin-solidity/contracts/SafeMath.sol';

//Interfaces
import './interfaces/IExternalStorage.sol';

//Inheritance
import './interfaces/IUsers.sol';
import './openzeppelin-solidity/contracts/Ownable.sol';
import './openzeppelin-solidity/contracts/ERC1155/ERC1155.sol';

contract Users is IUsers, ERC1155, Ownable {
    using SafeMath for uint256;

    IExternalStorage public externalStorage;
    bytes32[] public requiredAttributes;

    mapping (address => uint) public profileIDs;
    uint public numberOfUsers;

    constructor(address _externalStorage) Ownable() {
        externalStorage = IExternalStorage(_externalStorage);
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Given the address of a user, returns the user's profile NFT ID.
    * @notice If the user hasn't minted an NFT profile, the function returns 0.
    * @param userAddress Address of the user.
    * @return uint The user's NFT ID.
    */
    function getUser(address userAddress) external view returns (uint) {
        require(userAddress != address(0), "Users: invalid user address.");

        return profileIDs[userAddress];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @dev Mints an NFT representing the user's profile.
    * @notice attributeNames must match the required attributes in the same order.
    * @param attributeNames name of each attribute to initialize.
    * @param attributeValues value of each attribute to initialize.
    */
    function createProfile(bytes32[] memory attributeNames, bytes[] memory attributeValues) external userDoesntHaveProfile externalStorageIsInitialized {
        require(profileIDs[msg.sender] == 0, "Users: already have a profile.");
        require(attributeNames.length == attributeValues.length, "Users: lengths must match.");

        for (uint i = 0; i < attributeNames.length; i++) {
            require(requiredAttributes[i] == attributeNames[i], "Users: missing required attribute.");
        }

        numberOfUsers = numberOfUsers.add(1);
        profileIDs[msg.sender] = numberOfUsers;

        require(externalStorage.initializeValues(numberOfUsers, attributeNames, attributeValues), "Users: error when initializing values.");

        emit CreatedProfile(msg.sender, numberOfUsers, attributeNames, attributeValues);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setExternalStorage(address _externalStorage) external onlyOwner externalStorageIsNotInitialized {
        require(_externalStorage != address(0), "Users: invalid address for ExternalStorage.");

        externalStorage = IExternalStorage(_externalStorage);

        emit SetExternalStorage(_externalStorage);
    }

    function addRequiredAttribute(bytes32 _attributeName) external onlyOwner {
        // Check if attribute already exists
        for (uint i = 0; i < requiredAttributes.length; i++) {
            if (requiredAttributes[i] == _attributeName) {
                return;
            }
        }

        requiredAttributes.push(_attributeName);

        emit AddedRequiredAttribute(_attributeName);
    }

    function removeRequiredAttribute(bytes32 _attributeName) external onlyOwner {
        uint index;
        for (index = 0; index < requiredAttributes.length; index++) {
            if (requiredAttributes[index] == _attributeName) {
                break;
            }
        }

        if (requiredAttributes.length == 0 || index == requiredAttributes.length) {
            return;
        }

        // Swap with attribute at the end of the array
        requiredAttributes[index] = requiredAttributes[requiredAttributes.length - 1];
        delete requiredAttributes[requiredAttributes.length - 1];

        emit RemovedRequiredAttribute(_attributeName);
    }

    /* ========== MODIFIERS ========== */

    modifier userDoesntHaveProfile() {
        require(profileIDs[msg.sender] == 0, "Users: user already has a profile.");
        _;
    }

    modifier externalStorageIsNotInitialized() {
        require(address(externalStorage) == address(0), "Users: ExternalStorage is already initialized.");
        _;
    }

    modifier externalStorageIsInitialized() {
        require(address(externalStorage) != address(0), "Users: ExternalStorage is not initialized.");
        _;
    }

    /* ========== EVENTS ========== */

    event CreatedProfile(address indexed user, uint profileID, bytes32[] attributeNames, bytes[] attributeValues);
    event SetExternalStorage(address externalStorage);
    event AddedRequiredAttribute(bytes32 attributeName);
    event RemovedRequiredAttribute(bytes32 attributeName);
}