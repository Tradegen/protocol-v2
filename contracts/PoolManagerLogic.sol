// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import './openzeppelin-solidity/contracts/SafeMath.sol';

//Interfaces
import './interfaces/IAddressResolver.sol';
import './interfaces/ISettings.sol';

//Inheritance
import './interfaces/IPoolManagerLogic.sol';

contract PoolManagerLogic is IPoolManagerLogic {
    using SafeMath for uint256;

    address public immutable pool;
    address public immutable manager;
    IAddressResolver public immutable addressResolver;

    uint numberOfAssets;
    address[] public availableAssets;
    address[] public depositAssets;
    mapping(address => AssetInfo) public assets;
    uint public override performanceFee;
    uint public lastFeeUpdate;

    constructor(address _manager, address _pool, address _addressResolver) {
        manager = _manager;
        pool = _pool;
        addressResolver = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Given the address of an asset, returns whether this pool can hold the asset.
    * @param _asset Address of the asset.
    * @return bool Whether this pool can hold the asset.
    */
    function isAvailableAsset(address _asset) external view override returns (bool) {
        require(_asset != address(0), "PoolManagerLogic: invalid address.");

        return assets[_asset].isAvailable;
    }

    /**
    * @dev Given the address of an asset, returns whether the pool accepts the asset for deposits.
    * @param _asset Address of the asset.
    * @return bool Whether this pool can accept the asset for deposits.
    */
    function isDepositAsset(address _asset) external view override returns (bool) {
        require(_asset != address(0), "PoolManagerLogic: invalid address.");

        return assets[_asset].useForDeposits;
    }

    /**
    * @dev Returns a list of assets that can be deposited into the pool.
    */
    function getDepositAssets() external view override returns (address[] memory) {
        return depositAssets;
    }

    /**
    * @dev Returns a list of assets that the pool can hold.
    */
    function getAvailableAssets() external view override returns (address[] memory) {
        return availableAssets;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @dev Adds a new asset to the list of acceptable assets for deposits.
    * @param _asset Address of the asset.
    */
    function addDepositAsset(address _asset) external override onlyManager {
        require(_asset != address(0), "PoolManagerLogic: invalid address.");
        require(assets[_asset].isAvailable, "PoolManagerLogic: asset is not available.");
        require(!assets[_asset].useForDeposits, "PoolManagerLogic: already used for deposits.");
        
        assets[_asset].useForDeposits = true;
        depositAssets.push(_asset);

        emit AddedDepositAsset(_asset);
    }

    /**
    * @dev Removes an asset from the list of acceptable assets for deposits.
    * @param _asset Address of the asset.
    */
    function removeDepositAsset(address _asset) external override onlyManager {
        require(_asset != address(0), "PoolManagerLogic: invalid address.");
        require(assets[_asset].isAvailable, "PoolManagerLogic: asset is not available.");
        require(assets[_asset].useForDeposits, "PoolManagerLogic: asset is not used for deposits.");

        _removeDepositAsset(_asset);
    }

    /**
    * @dev Updates the pool's performance fee.
    * @param _performanceFee The new performance fee.
    */
    function setPerformanceFee(uint _performanceFee) external override onlyManager {
        require(_performanceFee >= 0, "PoolManagerLogic: performance fee must be positive.");
        require(_performanceFee <= ISettings(addressResolver.getContractAddress("Settings")).getParameterValue("MaximumPerformanceFee"), "PoolManagerLogic: performance fee is too high.");
        require(block.timestamp.sub(lastFeeUpdate) >= ISettings(addressResolver.getContractAddress("Settings")).getParameterValue("MinimumTimeBetweenPerformanceFeeUpdates"), "PoolManagerLogic: not enough time between fee updates.");

        performanceFee = _performanceFee;

        emit UpdatedPerformanceFee(_performanceFee);
    }

    /**
    * @dev Adds a new asset to the list of assets the pool can hold.
    * @param _asset Address of the asset.
    */
    function addAvailableAsset(address _asset) external override onlyManager {
        require(_asset != address(0), "PoolManagerLogic: invalid address.");
        require(availableAssets.length >= ISettings(addressResolver.getContractAddress("Settings")).getParameterValue("MaximumNumberOfPositionsInPool"), "PoolManagerLogic: pool has too many positions.");

        for (uint i = 0; i < availableAssets.length; i++) {
            require(availableAssets[i] != _asset, "PoolManagerLogic: asset already added.");
        }

        availableAssets.push(_asset);
        assets[_asset].isAvailable = true;

        emit AddedAvailableAsset(_asset);
    }

    /**
    * @dev Removes an asset from the list of assets the pool can hold.
    * @param _asset Address of the asset.
    */
    function removeAvailableAsset(address _asset) external override onlyManager {
        require(_asset != address(0), "PoolManagerLogic: invalid address.");
        require(assets[_asset].isAvailable, "PoolManagerLogic: asset is not available.");

        uint index;
        for (index = 0; index < availableAssets.length; index++) {
            if (availableAssets[index] == _asset) {
                break;
            }
        }

        require(index < availableAssets.length, "PoolManagerLogic: asset not found.");

        assets[_asset].isAvailable = false;
        availableAssets[index] = availableAssets[availableAssets.length.sub(1)];
        delete availableAssets[availableAssets.length.sub(1)];

        _removeDepositAsset(_asset);

        emit RemovedAvailableAsset(_asset);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _removeDepositAsset(address _asset) internal {
        uint index;
        for (index = 0; index < depositAssets.length; index++) {
            if (depositAssets[index] == _asset) {
                break;
            }
        }

        require(index < depositAssets.length, "PoolManagerLogic: asset not found.");

        if (index < depositAssets.length) {
            assets[_asset].useForDeposits = false;
            depositAssets[index] = depositAssets[depositAssets.length.sub(1)];
            delete depositAssets[depositAssets.length.sub(1)];

            emit RemovedDepositAsset(_asset);
        }
        
    }

    /* ========== MODIFIERS ========== */

    modifier onlyManager() {
        require(msg.sender == manager, "PoolManagerLogic: only the pool manager can call this function.");
        _;
    }

    /* ========== EVENTS ========== */

    event AddedDepositAsset(address asset);
    event RemovedDepositAsset(address asset);
    event AddedAvailableAsset(address asset);
    event RemovedAvailableAsset(address asset);
    event UpdatedPerformanceFee(uint newFee);
}