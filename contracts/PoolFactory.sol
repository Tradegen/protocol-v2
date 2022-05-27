// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Interfaces.
import './interfaces/ISettings.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/IPoolManagerLogicFactory.sol';

// Internal references.
import './Pool.sol';

contract PoolFactory {
    IAddressResolver public immutable ADDRESS_RESOLVER;

    constructor(address _addressResolver) {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Creates a new Pool contract.
    * @param _poolName Name of the pool.
    * @param _performanceFee Performance fee for the pool.
    * @return address The address of the deployed Pool contract.
    */
    function createPool(string memory _poolName, uint256 _performanceFee) external override onlyRegistry returns (address) {
        address settingsAddress = ADDRESS_RESOLVER.getContractAddress("Settings");
        address poolManagerLogicFactoryAddress = ADDRESS_RESOLVER.getContractAddress("PoolManagerLogicFactory");

        require(bytes(_poolName).length < 50, "PoolFactory: Pool name must have less than 50 characters.");
        require(_performanceFee <= ISettings(settingsAddress).getParameterValue("MaximumPerformanceFee"), "PoolFactory: Cannot exceed maximum performance fee.");
        require(_performanceFee >= 0, "PoolFactory: Performance fee must be positive.");

        // Create Pool contract.
        address poolAddress = address(new Pool(_poolName, msg.sender, address(ADDRESS_RESOLVER)));

        ADDRESS_RESOLVER.addPoolAddress(poolAddress);

        return poolAddress;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyRegistry() {
        require(msg.sender == addressResolver.getContractAddress("Registry"),
                "PoolFactory: Only the Registry contract can call this function.");
        _;
    }
}