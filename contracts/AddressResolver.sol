// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Inheritance.
import './interfaces/IAddressResolver.sol';

// OpenZeppelin.
import './openzeppelin-solidity/contracts/Ownable.sol';

contract AddressResolver is IAddressResolver, Ownable {

    // (pool or capped pool address => whether the pool is registered in the system).
    mapping (address => bool) public poolAddresses;

    // (external contract address => address of contract's verifier).
    mapping (address => address) public override contractVerifiers;

    // (asset type => address of asset's verifier).
    mapping (uint => address) public override assetVerifiers;

    // (contract name => contract address).
    mapping (string => address) public contractAddresses;

    constructor() Ownable() {}

    /* ========== VIEWS ========== */

    /**
    * @notice Given a contract name, returns the address of the contract.
    * @param _contractName The name of the contract.
    * @return address The address associated with the given contract name.
    */
    function getContractAddress(string memory _contractName) external view override returns(address) {        
        return contractAddresses[_contractName];
    }

    /**
    * @notice Given an address, returns whether the address belongs to a pool.
    * @param _poolAddress The address to validate.
    * @return bool Whether the given address is a valid pool address.
    */
    function checkIfPoolAddressIsValid(address _poolAddress) external view override returns(bool) {
        return poolAddresses[_poolAddress];
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Updates the address for the given contract.
    * @dev This function can only be called by the owner of the AddressResolver contract.
    * @param _contractName The name of the contract.
    * @param _newAddress The new address for the given contract.
    */
    function setContractAddress(string memory _contractName, address _newAddress) external onlyOwner isValidAddress(_newAddress) {
        address oldAddress = contractAddresses[_contractName];
        contractAddresses[_contractName] = _newAddress;

        emit UpdatedContractAddress(_contractName, oldAddress, _newAddress);
    }

    /**
    * @notice Updates the verifier for the given contract.
    * @dev This function can only be called by the owner of the AddressResolver contract.
    * @param _externalContract Address of the external contract.
    * @param _verifier Address of the contract's verifier.
    */
    function setContractVerifier(address _externalContract, address _verifier) external onlyOwner isValidAddress(_externalContract) isValidAddress(_verifier) {
        contractVerifiers[_externalContract] = _verifier;

        emit UpdatedContractVerifier(_externalContract, _verifier);
    }

    /**
    * @notice Updates the verifier for the given asset.
    * @dev This function can only be called by the owner of the AddressResolver contract.
    * @param _assetType Type of the asset.
    * @param _verifier Address of the contract's verifier.
    */
    function setAssetVerifier(uint256 _assetType, address _verifier) external onlyOwner isValidAddress(_verifier) {
        require(_assetType > 0, "AddressResolver: asset type must be greater than 0.");

        assetVerifiers[_assetType] = _verifier;

        emit UpdatedAssetVerifier(_assetType, _verifier);
    }

    /**
    * @notice Adds a new pool address.
    * @dev This function can only be called by the PoolFactory contract.
    * @param _poolAddress The address of the pool.
    */
    function addPoolAddress(address _poolAddress) external override onlyPoolFactory isValidAddress(_poolAddress) {
        require(!poolAddresses[_poolAddress], "AddressResolver: Pool already exists.");

        poolAddresses[_poolAddress] = true;

        emit AddedPoolAddress(_poolAddress);
    }

    /* ========== MODIFIERS ========== */

    modifier isValidAddress(address _addressToCheck) {
        require(_addressToCheck != address(0), "AddressResolver: Address is not valid.");
        _;
    }

    modifier onlyPoolFactory() {
        require(msg.sender == contractAddresses["PoolFactory"] || msg.sender == contractAddresses["CappedPoolFactory"], "AddressResolver: Only the PoolFactory or CappedPoolFactory contract can call this function.");
        _;
    }

    /* ========== EVENTS ========== */

    event UpdatedContractAddress(string contractName, address oldAddress, address newAddress);
    event AddedPoolAddress(address poolAddress);
    event UpdatedContractVerifier(address externalContract, address verifier);
    event UpdatedAssetVerifier(uint256 assetType, address verifier);
}