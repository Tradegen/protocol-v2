// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IPoolManagerLogicFactory {
    /**
    * @notice Returns the address of the pool's PoolManagerLogic contract.
    * @param _poolAddress address of the pool.
    * @return address Address of the pool's PoolManagerLogic contract.
    */
    function getPoolManagerLogic(address _poolAddress) external view returns (address);

    /**
    * @notice Creates a PoolManagerLogic contract.
    * @dev This function can only be called by the Registry contract.
    * @dev Check _performanceFee in the calling contract.
    * @param _poolAddress Address of the pool.
    * @param _manager Address of the pool's manager.
    * @param _performanceFee The pool's performance fee.
    * @return address The address of the newly created contract.
    */
    function createPoolManagerLogic(address _poolAddress, address _manager, uint256 _performanceFee) external returns (address);
}