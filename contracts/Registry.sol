// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// OpenZeppelin.
import "./openzeppelin-solidity/contracts/Ownable.sol";

// Interfaces.
import './interfaces/ICappedPoolNFTFactory.sol';
import './interfaces/ICappedPoolFactory.sol';
import './interfaces/ISettings.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/IPoolManager.sol';
import './interfaces/IPoolFactory.sol';
import './interfaces/ICappedPool.sol';
import './interfaces/IPool.sol';

// Inheritance.
import './interfaces/IRegistry.sol';

contract Registry is IRegistry, Ownable {
    IAddressResolver public immutable addressResolver;

    constructor(address _addressResolver) Ownable() {
        addressResolver = IAddressResolver(_addressResolver);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Deploys a CappedPool contract and its NFT.
    * @param _name Name of the pool.
    * @param _seedPrice The initial pool token price.
    * @param _supplyCap Maximum number of pool tokens that can be minted.
    * @param _performanceFee The percentage of profits that the pool manager receives whenever users withdraw for a profit. Denominated by 10000.
    */
    function createCappedPool(string memory _name, uint256 _seedPrice, uint256 _supplyCap, uint256 _performanceFee) external override {
        address cappedPoolFactoryAddress = addressResolver.getContractAddress("CappedPoolFactory");
        address poolManagerLogicFactoryAddress = addressResolver.getContractAddress("PoolManagerLogicFactory");
        address cappedPoolNFTFactoryAddress = addressResolver.getContractAddress("CappedPoolNFTFactory");

        address poolAddress = ICappedPoolFactory(cappedPoolFactoryAddress).createCappedPool(msg.sender, _name, _supplyCap, _seedPrice, _performanceFee);
        address poolManagerLogicAddress = IPoolManagerLogicFactory(poolManagerLogicFactoryAddress).createPoolManagerLogic(poolAddress, msg.sender, _performanceFee);
        address NFTAddress = ICappedPoolNFTFactory(cappedPoolNFTFactoryAddress).createCappedPoolNFT(poolAddress, _supplyCap);

        ICappedPool(poolAddress).initializeContracts(NFTAddress, poolManagerLogicAddress);
        IPoolManager(poolManagerAddress).registerPool(poolAddress, _seedPrice);

        emit CreatedCappedPool(poolAddress, msg.sender, _name, _seedPrice, _supplyCap, _performanceFee);
    }

    /**
    * @notice Deploys a new Pool contract.
    * @param _poolName Name of the pool.
    * @param _performanceFee Performance fee for the pool.
    */
    function createPool(string memory _poolName, uint256 _performanceFee) external override {
        address poolFactoryAddress = addressResolver.getContractAddress("PoolFactory");
        address poolManagerLogicFactoryAddress = addressResolver.getContractAddress("PoolManagerLogicFactory");

        address poolAddress = IPoolFactory(poolFactoryAddress).createPool(_poolName, _performanceFee);
        address poolManagerLogicAddress = IPoolManagerLogicFactory(poolManagerLogicFactoryAddress).createPoolManagerLogic(poolAddress, msg.sender, _performanceFee);

        IPool(poolAddress).setPoolManagerLogic(poolManagerLogicAddress);

        emit CreatedPool(poolAddress, msg.sender, _poolName, _performanceFee);
    }

    /* ========== EVENTS ========== */

    event CreatedCappedPool(address poolAddress, address manager, string name, uint256 seedprice, uint256 supplyCap, uint256 performanceFee);
    event CreatedPool(address poolAddress, address manager, string name, uint256 performanceFee);
}