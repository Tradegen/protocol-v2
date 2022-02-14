// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Interfaces
import './interfaces/ISettings.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/IPoolManagerLogicFactory.sol';

//Internal references
import './Pool.sol';

contract PoolFactory {
    IAddressResolver public immutable ADDRESS_RESOLVER;

    address[] public pools;
    mapping (address => uint[]) public userToManagedPools;
    mapping (address => uint) public addressToIndex; // maps to (index + 1); index 0 represents pool not found

    constructor(IAddressResolver addressResolver) {
        ADDRESS_RESOLVER = addressResolver;
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
    * @param _performanceFee Performance fee for the pool
    */
    function createPool(string memory _poolName, uint _performanceFee) external {
        address settingsAddress = ADDRESS_RESOLVER.getContractAddress("Settings");
        address poolManagerLogicFactoryAddress = ADDRESS_RESOLVER.getContractAddress("PoolManagerLogicFactory");
        address poolManagerAddress = ADDRESS_RESOLVER.getContractAddress("PoolManager");
        uint maximumPerformanceFee = ISettings(settingsAddress).getParameterValue("MaximumPerformanceFee");
        uint maximumNumberOfPoolsPerUser = ISettings(settingsAddress).getParameterValue("MaximumNumberOfPoolsPerUser");

        require(bytes(_poolName).length < 50, "PoolFactory: Pool name must have less than 50 characters");
        require(_performanceFee <= maximumPerformanceFee, "PoolFactory: Cannot exceed maximum performance fee");
        require(_performanceFee >= 0, "PoolFactory: Performance fee must be positive.");
        require(userToManagedPools[msg.sender].length < maximumNumberOfPoolsPerUser, "PoolFactory: Cannot exceed maximum number of pools per user");

        //Create pool
        Pool temp = new Pool(_poolName, msg.sender, address(ADDRESS_RESOLVER), poolManagerAddress);
        address poolManagerLogicAddress = IPoolManagerLogicFactory(poolManagerLogicFactoryAddress).createPoolManagerLogic(address(temp), msg.sender, _performanceFee);
        temp.setPoolManagerLogic(poolManagerLogicAddress);

        //Update state variables
        address poolAddress = address(temp);
        pools.push(poolAddress);
        userToManagedPools[msg.sender].push(pools.length - 1);
        addressToIndex[poolAddress] = pools.length;
        ADDRESS_RESOLVER.addPoolAddress(poolAddress);

        emit CreatedPool(msg.sender, poolAddress, pools.length - 1, block.timestamp);
    }

    /* ========== MODIFIERS ========== */

    modifier isValidPoolAddress(address poolAddress) {
        require(poolAddress != address(0), "PoolFactory: Invalid pool address");
        require(addressToIndex[poolAddress] > 0, "PoolFactory: Pool not found");
        _;
    }

    /* ========== EVENTS ========== */

    event CreatedPool(address indexed managerAddress, address indexed poolAddress, uint poolIndex, uint timestamp);
}