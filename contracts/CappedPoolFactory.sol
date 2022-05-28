// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Interfaces.
import './interfaces/IAddressResolver.sol';

// Internal references.
import './CappedPool.sol';

// Inheritance.
import './interfaces/ICappedPoolFactory.sol';

contract CappedPoolFactory is ICappedPoolFactory {
    IAddressResolver public immutable ADDRESS_RESOLVER;

    constructor(address _addressResolver) {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Creates a new capped pool.
    * @param _manager Address of the pool's manager.
    * @param _poolName Name of the pool.
    * @param _maxSupply Maximum number of pool tokens.
    * @param _seedPrice Initial price of pool tokens.
    */
    function createCappedPool(address _manager, string memory _poolName, uint256 _maxSupply, uint256 _seedPrice) external override onlyRegistry returns (address) {
        address poolManagerAddress = ADDRESS_RESOLVER.getContractAddress("PoolManager");
        
        // Create a CappedPool contract.
        address poolAddress = address(new CappedPool(_poolName, _seedPrice, _maxSupply, _manager, address(ADDRESS_RESOLVER), poolManagerAddress));

        ADDRESS_RESOLVER.addPoolAddress(poolAddress);

        return poolAddress;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyRegistry() {
        require(msg.sender == ADDRESS_RESOLVER.getContractAddress("Registry"),
                "CappedPoolFactory: Only the Registry contract can call this function.");
        _;
    }
}