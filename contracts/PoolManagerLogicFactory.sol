// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Interfaces
import './interfaces/IAddressResolver.sol';
import './interfaces/IPoolManagerLogicFactory.sol';

//Internal references
import './PoolManagerLogic.sol';

contract PoolManagerLogicFactory is IPoolManagerLogicFactory {
    IAddressResolver public immutable ADDRESS_RESOLVER;

    mapping(address => address) public poolManagerLogics; // Pool address => PoolManagerLogic address

    constructor(address _addressResolver) {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Returns the address of the pool's PoolManagerLogic contract.
    * @param _poolAddress address of the pool.
    * @return address Address of the pool's PoolManagerLogic contract.
    */
    function getPoolManagerLogic(address _poolAddress) external view override returns (address) {
        require(_poolAddress != address(0), "PoolManagerLogicFactory: invalid pool address.");

        return poolManagerLogics[_poolAddress];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @dev Creates a PoolManagerLogic contract.
    * @notice This function is meant to be called by PoolFactory or CappedPoolFactory.
    * @param _poolAddress address of the pool.
    * @param _manager address of the pool's manager.
    * @return address The address of the newly created contract.
    */
    function createPoolManagerLogic(address _poolAddress, address _manager) external override onlyWhitelistedContracts returns (address) {
        require(_poolAddress != address(0), "PoolManagerLogicFactory: invalid pool address.");
        require(_manager != address(0), "PoolManagerLogicFactory: invalid manager address.");
        require(poolManagerLogics[_poolAddress] == address(0), "PoolManagerLogicFactory: pool already has a PoolManagerLogic contract.");

        address poolManagerLogicAddress = address(new PoolManagerLogic(_manager, _poolAddress, address(ADDRESS_RESOLVER)));

        poolManagerLogics[_poolAddress] = poolManagerLogicAddress;

        emit CreatedPoolManagerLogic(_poolAddress, poolManagerLogicAddress);

        return poolManagerLogicAddress;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyWhitelistedContracts() {
        require(msg.sender == ADDRESS_RESOLVER.getContractAddress("PoolFactory") || msg.sender == ADDRESS_RESOLVER.getContractAddress("CappedPoolFactory"), "PoolManagerLogicFactory: only whitelisted contracts can call this function.");
        _;
    }

    /* ========== EVENTS ========== */

    event CreatedPoolManagerLogic(address indexed poolAddress, address poolManagerLogicAddress);
}