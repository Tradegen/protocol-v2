// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Interfaces.
import './interfaces/ISettings.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/IPoolManagerLogicFactory.sol';
import './interfaces/IPoolManager.sol';

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
    * @param _performanceFee Performance fee for the pool.
    */
    function createCappedPool(address _manager, string memory _poolName, uint256 _maxSupply, uint256 _seedPrice, uint256 _performanceFee) external override onlyRegistry returns (address) {
        address settingsAddress = ADDRESS_RESOLVER.getContractAddress("Settings");
        address poolManagerAddress = ADDRESS_RESOLVER.getContractAddress("PoolManager");
        address poolManagerLogicFactoryAddress = ADDRESS_RESOLVER.getContractAddress("PoolManagerLogicFactory");
        
        require(bytes(_poolName).length < 50, "CappedPoolFactory: Pool name must have less than 50 characters.");
        require(_maxSupply <= ISettings(settingsAddress).getParameterValue("MaximumNumberOfCappedPoolTokens"), "CappedPoolFactory: Cannot exceed max supply cap.");
        require(_maxSupply >= ISettings(settingsAddress).getParameterValue("MinimumNumberOfCappedPoolTokens"), "CappedPoolFactory: Cannot have less than min supply cap.");
        require(_seedPrice >= ISettings(settingsAddress).getParameterValue("MinimumCappedPoolSeedPrice"), "CappedPoolFactory: Seed price must be greater than min seed price.");
        require(_seedPrice <= ISettings(settingsAddress).getParameterValue("MaximumCappedPoolSeedPrice"), "CappedPoolFactory: Seed price must be less than max seed price.");
        require(_performanceFee <= ISettings(settingsAddress).getParameterValue("MaximumPerformanceFee"), "PoolFactory: Cannot exceed maximum performance fee.");
        require(_performanceFee >= 0, "PoolFactory: Performance fee must be positive.");
        
        // Create a CappedPool contract.
        address poolAddress = address(new CappedPool(_poolName, _seedPrice, _maxSupply, _manager, address(ADDRESS_RESOLVER), poolManagerAddress));

        ADDRESS_RESOLVER.addPoolAddress(poolAddress);

        return poolAddress;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyRegistry() {
        require(msg.sender == addressResolver.getContractAddress("Registry"),
                "CappedPoolFactory: Only the Registry contract can call this function.");
        _;
    }
}