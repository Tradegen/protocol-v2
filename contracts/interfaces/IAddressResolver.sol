// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IAddressResolver {
    /**
    * @notice Given a contract name, returns the address of the contract.
    * @param _contractName The name of the contract.
    * @return address The address associated with the given contract name.
    */
    function getContractAddress(string memory _contractName) external view returns (address);

    /**
    * @notice Given an address, returns whether the address belongs to a pool.
    * @param _poolAddress The address to validate.
    * @return bool Whether the given address is a valid pool address.
    */
    function checkIfPoolAddressIsValid(address _poolAddress) external view returns (bool);

    /**
    * @notice Adds a new pool address.
    * @dev This function can only be called by the PoolFactory contract.
    * @param _poolAddress The address of the pool.
    */
    function addPoolAddress(address _poolAddress) external;

    /**
    * @notice Returns the verifier for the given contract.
    */
    function contractVerifiers(address) external view returns (address);

    /**
    * @notice Returns the verifier for the given asset type.
    */
    function assetVerifiers(uint) external view returns (address);
}