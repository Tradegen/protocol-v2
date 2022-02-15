// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Interfaces
import './interfaces/ISettings.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/IPoolManagerLogicFactory.sol';
import './interfaces/IPoolManager.sol';

//Internal references
import './CappedPool.sol';

contract CappedPoolFactory {
    IAddressResolver public immutable ADDRESS_RESOLVER;

    address[] public pools;
    mapping (address => uint[]) public userToManagedPools;
    mapping (address => uint) public addressToIndex; // maps to (index + 1); index 0 represents pool not found

    constructor(address _addressResolver) {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Returns the address of each pool the user manages
    * @param user Address of the user
    * @return address[] The address of each pool the user manages
    */
    function getUserManagedPools(address user) external view returns(address[] memory) {
        require(user != address(0), "Invalid address");

        address[] memory addresses = new address[](userToManagedPools[user].length);
        uint[] memory indexes = userToManagedPools[user];

        for (uint i = 0; i < addresses.length; i++)
        {
            uint index = indexes[i];
            addresses[i] = pools[index];
        }

        return addresses;
    }

    /**
    * @dev Returns the address of each available pool
    * @return address[] The address of each available pool
    */
    function getAvailablePools() external view returns(address[] memory) {
        return pools;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @dev Creates a new pool
    * @param _poolName Name of the pool
    * @param _maxSupply Maximum number of pool tokens
    * @param _seedPrice Initial price of pool tokens
    * @param _performanceFee Performance fee for the pool
    */
    function createPool(string memory _poolName, uint _maxSupply, uint _seedPrice, uint _performanceFee) external {
        address settingsAddress = ADDRESS_RESOLVER.getContractAddress("Settings");
        address poolManagerAddress = ADDRESS_RESOLVER.getContractAddress("PoolManager");
        address poolManagerLogicFactoryAddress = ADDRESS_RESOLVER.getContractAddress("PoolManagerLogicFactory");
        uint maximumNumberOfCappedPoolTokens = ISettings(settingsAddress).getParameterValue("MaximumNumberOfCappedPoolTokens");
        uint minimumNumberOfCappedPoolTokens = ISettings(settingsAddress).getParameterValue("MinimumNumberOfCappedPoolTokens");
        uint maximumCappedPoolSeedPrice = ISettings(settingsAddress).getParameterValue("MaximumCappedPoolSeedPrice");
        uint minimumCappedPoolSeedPrice = ISettings(settingsAddress).getParameterValue("MinimumCappedPoolSeedPrice");
        uint maximumNumberOfPoolsPerUser = ISettings(settingsAddress).getParameterValue("MaximumNumberOfPoolsPerUser");
        
        require(bytes(_poolName).length < 50, "CappedPoolFactory: Pool name must have less than 50 characters");
        require(_maxSupply <= maximumNumberOfCappedPoolTokens, "CappedPoolFactory: Cannot exceed max supply cap");
        require(_maxSupply >= minimumNumberOfCappedPoolTokens, "CappedPoolFactory: Cannot have less than min supply cap");
        require(_seedPrice >= minimumCappedPoolSeedPrice, "CappedPoolFactory: Seed price must be greater than min seed price");
        require(_seedPrice <= maximumCappedPoolSeedPrice, "CappedPoolFactory: Seed price must be less than max seed price");
        require(userToManagedPools[msg.sender].length < maximumNumberOfPoolsPerUser, "CappedPoolFactory: Cannot exceed maximum number of pools per user");
        
        //Create pool
        CappedPool temp = new CappedPool(_poolName, _seedPrice, _maxSupply, msg.sender, address(ADDRESS_RESOLVER), poolManagerAddress);
        address poolAddress = address(temp);

        //Initialize pool on external contracts
        address poolManagerLogicAddress = IPoolManagerLogicFactory(poolManagerLogicFactoryAddress).createPoolManagerLogic(address(temp), msg.sender, _performanceFee);
        temp.setPoolManagerLogic(poolManagerLogicAddress);
        IPoolManager(poolManagerAddress).registerPool(poolAddress, _seedPrice);

        //Update state variables
        pools.push(poolAddress);
        userToManagedPools[msg.sender].push(pools.length - 1);
        addressToIndex[poolAddress] = pools.length;
        ADDRESS_RESOLVER.addPoolAddress(poolAddress);

        emit CreatedCappedPool(msg.sender, poolAddress, pools.length - 1, _poolName, _maxSupply, _seedPrice, _performanceFee);
    }

    /* ========== EVENTS ========== */

    event CreatedCappedPool(address indexed managerAddress, address indexed poolAddress, uint poolIndex, string poolName, uint maxSupply, uint seedPrice, uint performanceFee);
}