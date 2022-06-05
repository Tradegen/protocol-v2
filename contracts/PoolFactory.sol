// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Interfaces.
import './interfaces/ISettings.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/IPoolManagerLogicFactory.sol';

// Internal references.
import './Pool.sol';

// Inheritance.
import './interfaces/IPoolFactory.sol';

contract PoolFactory is IPoolFactory {
    IAddressResolver immutable ADDRESS_RESOLVER;

    constructor(address _addressResolver) {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Creates a new Pool contract.
    * @param _poolName Name of the pool.
    * @param _manager Address of the pool's manager.
    * @return address The address of the deployed Pool contract.
    */
    function createPool(string memory _poolName, address _manager) external override returns (address) {
        require(msg.sender == ADDRESS_RESOLVER.getContractAddress("Registry"),
                "PoolFactory: Only the Registry contract can call this function.");

        // Create Pool contract.
        address poolAddress = address(new Pool(_poolName, _manager, address(ADDRESS_RESOLVER)));

        ADDRESS_RESOLVER.addPoolAddress(poolAddress);

        return poolAddress;
    }
}