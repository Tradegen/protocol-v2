// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IUsers {
    /**
    * @dev Given the address of a user, returns the user's profile NFT ID.
    * @notice If the user hasn't minted an NFT profile, the function returns 0.
    * @param userAddress Address of the user.
    * @return uint The user's NFT ID.
    */
    function getUser(address userAddress) external view returns (uint);

    /**
    * @dev Mints an NFT representing the user's profile.
    * @notice attributeNames must match the required attributes in the same order.
    * @param attributeNames name of each attribute to initialize.
    * @param attributeValues value of each attribute to initialize.
    */
    function createProfile(bytes32[] memory attributeNames, bytes[] memory attributeValues) external;
}