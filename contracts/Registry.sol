// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// OpenZeppelin.
import "./openzeppelin-solidity/contracts/Ownable.sol";
import "./openzeppelin-solidity/contracts/SafeMath.sol";
import "./openzeppelin-solidity/contracts/ERC20/IERC20.sol";

// Interfaces.
import './interfaces/ICappedPoolNFTFactory.sol';
import './interfaces/ICappedPoolFactory.sol';
import './interfaces/ISettings.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/IPoolManager.sol';
import './interfaces/IPoolManagerLogicFactory.sol';
import './interfaces/IPoolFactory.sol';
import './interfaces/ICappedPool.sol';
import './interfaces/ICappedPoolNFT.sol';
import './interfaces/IPool.sol';
import './interfaces/IAssetHandler.sol';

// Inheritance.
import './interfaces/IRegistry.sol';

contract Registry is IRegistry, Ownable {
    using SafeMath for uint256;

    IAddressResolver public immutable addressResolver;

    // (capped pool address => capped pool NFT address).
    mapping (address => address) public cappedPoolNFTs;

    // (user address => number of pools the user manages).
    mapping (address => uint256) public userPools;

    // (user address => number of capped pools the user manages).
    mapping (address => uint256) public userCappedPools;

    constructor(address _addressResolver) Ownable() {
        addressResolver = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the number of tokens available for each class.
    * @param _cappedPool Address of the CappedPool contract.
    * @return (uint256, uint256, uint256, uint256) Number of available C1, C2, C3, and C4 tokens.
    */
    function getAvailableTokensPerClass(address _cappedPool) external view override returns (uint256, uint256, uint256, uint256) {
        return ICappedPoolNFT(cappedPoolNFTs[_cappedPool]).getAvailableTokensPerClass();
    }

    /**
    * @notice Given the address of a user, returns the number of tokens the user has for each class.
    * @param _cappedPool Address of the CappedPool contract.
    * @param _user Address of the user.
    * @return (uint256, uint256, uint256, uint256) Number of available C1, C2, C3, and C4 tokens.
    */
    function getTokenBalancePerClass(address _cappedPool, address _user) external view override returns (uint256, uint256, uint256, uint256) {
        return ICappedPoolNFT(cappedPoolNFTs[_cappedPool]).getTokenBalancePerClass(_user);
    }

    /**
    * @notice Returns the amount of stablecoin the pool, or capped pool, has to invest.
    */
    function getAvailableFunds(address _pool) external view override returns (uint256) {
        address assetHandlerAddress = addressResolver.getContractAddress("AssetHandler");
        address stableCoinAddress = IAssetHandler(assetHandlerAddress).getStableCoinAddress();

        return IERC20(stableCoinAddress).balanceOf(_pool);
    }

    /**
    * @notice Returns the balance of the user in USD.
    */
    function getUSDBalance(address _user, address _pool, bool _isCappedPool) external view override returns (uint256) {
        if (_isCappedPool) {
            return (ICappedPoolNFT(cappedPoolNFTs[_pool]).totalSupply() == 0) ? 0 : ICappedPool(_pool).getPoolValue().mul(ICappedPoolNFT(cappedPoolNFTs[_pool]).balance(_user)).div(ICappedPoolNFT(cappedPoolNFTs[_pool]).totalSupply());
        }
        
        return (IERC20(_pool).totalSupply() == 0) ? 0 : IPool(_pool).getPoolValue().mul(IERC20(_pool).balanceOf(_user)).div(IERC20(_pool).totalSupply());
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
        address settingsAddress = addressResolver.getContractAddress("Settings");

        require(userCappedPools[msg.sender] < ISettings(settingsAddress).getParameterValue("MaximumNumberOfPoolsPerUser"), "Registry: User has too many capped pools.");
        require(bytes(_name).length < 50, "Registry: Pool name must have less than 50 characters.");
        require(_supplyCap <= ISettings(settingsAddress).getParameterValue("MaximumNumberOfCappedPoolTokens"), "Registry: Cannot exceed max supply cap.");
        require(_supplyCap >= ISettings(settingsAddress).getParameterValue("MinimumNumberOfCappedPoolTokens"), "Registry: Cannot have less than min supply cap.");
        require(_seedPrice >= ISettings(settingsAddress).getParameterValue("MinimumCappedPoolSeedPrice"), "Registry: Seed price must be greater than min seed price.");
        require(_seedPrice <= ISettings(settingsAddress).getParameterValue("MaximumCappedPoolSeedPrice"), "Registry: Seed price must be less than max seed price.");
        require(_performanceFee <= ISettings(settingsAddress).getParameterValue("MaximumPerformanceFee"), "Registry: Cannot exceed maximum performance fee.");
        require(_performanceFee >= 0, "Registry: Performance fee must be positive.");

        address poolAddress = ICappedPoolFactory(addressResolver.getContractAddress("CappedPoolFactory")).createCappedPool(msg.sender, _name, _supplyCap, _seedPrice);

        {
        address NFTAddress = ICappedPoolNFTFactory(addressResolver.getContractAddress("CappedPoolNFTFactory")).createCappedPoolNFT(poolAddress, _supplyCap);
        address poolManagerLogicAddress = IPoolManagerLogicFactory(addressResolver.getContractAddress("PoolManagerLogicFactory")).createPoolManagerLogic(poolAddress, msg.sender, _performanceFee);
        ICappedPool(poolAddress).initializeContracts(NFTAddress, poolManagerLogicAddress);
        cappedPoolNFTs[poolAddress] = NFTAddress;
        userCappedPools[msg.sender] = userCappedPools[msg.sender].add(1);
        }

        {
        address poolManagerAddress = addressResolver.getContractAddress("PoolManager");
        IPoolManager(poolManagerAddress).registerPool(poolAddress, _seedPrice);
        }

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
        address settingsAddress = addressResolver.getContractAddress("Settings");

        require(userPools[msg.sender] < ISettings(settingsAddress).getParameterValue("MaximumNumberOfPoolsPerUser"), "Registry: User has too many pools.");
        require(bytes(_poolName).length < 50, "Registry: Pool name must have less than 50 characters.");
        require(_performanceFee <= ISettings(settingsAddress).getParameterValue("MaximumPerformanceFee"), "Registry: Cannot exceed maximum performance fee.");
        require(_performanceFee >= 0, "Registry: Performance fee must be positive.");

        userPools[msg.sender] = userPools[msg.sender].add(1);

        address poolAddress = IPoolFactory(poolFactoryAddress).createPool(_poolName);
        address poolManagerLogicAddress = IPoolManagerLogicFactory(poolManagerLogicFactoryAddress).createPoolManagerLogic(poolAddress, msg.sender, _performanceFee);

        IPool(poolAddress).setPoolManagerLogic(poolManagerLogicAddress);

        emit CreatedPool(poolAddress, msg.sender, _poolName, _performanceFee);
    }

    /* ========== EVENTS ========== */

    event CreatedCappedPool(address poolAddress, address manager, string name, uint256 seedprice, uint256 supplyCap, uint256 performanceFee);
    event CreatedPool(address poolAddress, address manager, string name, uint256 performanceFee);
}