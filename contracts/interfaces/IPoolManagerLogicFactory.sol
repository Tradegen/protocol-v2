// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IPoolManagerLogicFactory {
    /**
    * @dev Returns the address of the pool's PoolManagerLogic contract.
    * @param _poolAddress address of the pool.
    * @return address Address of the pool's PoolManagerLogic contract.
    */
    function getPoolManagerLogic(address _poolAddress) external view returns (address);

    /**
    * @dev Creates a PoolManagerLogic contract.
    * @notice This function is meant to be called by PoolFactory or CappedPoolFactory.
    * @notice Check _performanceFee in the calling contract.
    * @param _poolAddress address of the pool.
    * @param _manager address of the pool's manager.
    * @param _performanceFee the pool's performance fee.
    * @return address The address of the newly created contract.
    */
    function createPoolManagerLogic(address _poolAddress, address _manager, uint _performanceFee) external returns (address);
}