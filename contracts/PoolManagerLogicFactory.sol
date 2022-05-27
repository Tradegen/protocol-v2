// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Interfaces.
import './interfaces/IAddressResolver.sol';
import './interfaces/IPoolManagerLogicFactory.sol';

// Internal references.
import './PoolManagerLogic.sol';

contract PoolManagerLogicFactory is IPoolManagerLogicFactory {
    IAddressResolver public immutable ADDRESS_RESOLVER;

    // (Pool address => PoolManagerLogic address)
    mapping (address => address) public poolManagerLogics;

    constructor(address _addressResolver) {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the address of the pool's PoolManagerLogic contract.
    * @param _poolAddress address of the pool.
    * @return address Address of the pool's PoolManagerLogic contract.
    */
    function getPoolManagerLogic(address _poolAddress) external view override returns (address) {
        return poolManagerLogics[_poolAddress];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Creates a PoolManagerLogic contract.
    * @dev This function can only be called by the Registry contract.
    * @dev Check _performanceFee in the calling contract.
    * @param _poolAddress Address of the pool.
    * @param _manager Address of the pool's manager.
    * @param _performanceFee The pool's performance fee.
    * @return address The address of the newly created contract.
    */
    function createPoolManagerLogic(address _poolAddress, address _manager, uint256 _performanceFee) external override onlyRegistry returns (address) {
        require(poolManagerLogics[_poolAddress] == address(0), "PoolManagerLogicFactory: pool already has a PoolManagerLogic contract.");

        // Create the PoolManagerLogic contract.
        address poolManagerLogicAddress = address(new PoolManagerLogic(_manager, _performanceFee, address(ADDRESS_RESOLVER)));

        poolManagerLogics[_poolAddress] = poolManagerLogicAddress;

        emit CreatedPoolManagerLogic(_poolAddress, poolManagerLogicAddress, _manager, _performanceFee);

        return poolManagerLogicAddress;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyRegistry() {
        require(msg.sender == ADDRESS_RESOLVER.getContractAddress("Registry"), "PoolManagerLogicFactory: Only the Registry contract can call this function.");
        _;
    }

    /* ========== EVENTS ========== */

    event CreatedPoolManagerLogic(address poolAddress, address poolManagerLogicAddress, address manager, uint256 performanceFee);
}