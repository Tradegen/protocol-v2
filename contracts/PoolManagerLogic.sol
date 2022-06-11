// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import './openzeppelin-solidity/contracts/SafeMath.sol';

// Interfaces.
import './interfaces/IAddressResolver.sol';
import './interfaces/ISettings.sol';
import './interfaces/IAssetHandler.sol';

// Inheritance.
import './interfaces/IPoolManagerLogic.sol';

contract PoolManagerLogic is IPoolManagerLogic {
    using SafeMath for uint256;

    address public immutable manager;
    IAddressResolver public immutable addressResolver;

    address[] public availableAssets;
    address[] public depositAssets;

    // (asset address => asset info).
    mapping(address => AssetInfo) public assets;

    uint256 public override performanceFee;
    uint256 public lastFeeUpdate;

    constructor(address _manager, uint256 _performanceFee, address _addressResolver) {
        manager = _manager;
        performanceFee = _performanceFee;
        addressResolver = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Returns whether this pool can hold the given asset.
    * @param _asset Address of the asset.
    * @return bool Whether this pool can hold the asset.
    */
    function isAvailableAsset(address _asset) external view override returns (bool) {
        return assets[_asset].isAvailable;
    }

    /**
    * @notice Returns whether the pool accepts the given asset for deposits.
    * @param _asset Address of the asset.
    * @return bool Whether this pool can accept the asset for deposits.
    */
    function isDepositAsset(address _asset) external view override returns (bool) {
        return assets[_asset].useForDeposits;
    }

    /**
    * @notice Returns a list of assets that can be deposited into the pool.
    */
    function getDepositAssets() external view override returns (address[] memory) {
        address[] memory ret = new address[](depositAssets.length);

        for (uint256 i = 0; i < ret.length; i++) {
            ret[i] = depositAssets[i];
        }

        return ret;
    }

    /**
    * @notice Returns a list of assets that the pool can hold.
    */
    function getAvailableAssets() external view override returns (address[] memory) {
        address[] memory ret = new address[](availableAssets.length);

        for (uint256 i = 0; i < ret.length; i++) {
            ret[i] = availableAssets[i];
        }

        return ret;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Adds a new asset to the list of acceptable assets for deposits.
    * @param _asset Address of the asset.
    */
    function addDepositAsset(address _asset) external override onlyManager {
        address assetHandlerAddress = addressResolver.getContractAddress("AssetHandler");

        require(IAssetHandler(assetHandlerAddress).isValidAsset(_asset), "PoolManagerLogic: Asset is not supported.");
        require(assets[_asset].isAvailable, "PoolManagerLogic: Asset is not available.");
        require(!assets[_asset].useForDeposits, "PoolManagerLogic: Already used for deposits.");
        
        assets[_asset].useForDeposits = true;
        depositAssets.push(_asset);

        emit AddedDepositAsset(_asset);
    }

    /**
    * @notice Removes an asset from the list of acceptable assets for deposits.
    * @param _asset Address of the asset.
    */
    function removeDepositAsset(address _asset) external override onlyManager {
        require(assets[_asset].isAvailable, "PoolManagerLogic: Asset is not available.");
        require(assets[_asset].useForDeposits, "PoolManagerLogic: Asset is not used for deposits.");

        _removeDepositAsset(_asset);
    }

    /**
    * @notice Updates the pool's performance fee.
    * @param _performanceFee The new performance fee.
    */
    function setPerformanceFee(uint256 _performanceFee) external override onlyManager {
        require(_performanceFee >= 0, "PoolManagerLogic: Performance fee must be positive.");
        require(_performanceFee <= ISettings(addressResolver.getContractAddress("Settings")).getParameterValue("MaximumPerformanceFee"), "PoolManagerLogic: Performance fee is too high.");
        require(block.timestamp.sub(lastFeeUpdate) >= ISettings(addressResolver.getContractAddress("Settings")).getParameterValue("MinimumTimeBetweenPerformanceFeeUpdates"), "PoolManagerLogic: Not enough time between fee updates.");

        performanceFee = _performanceFee;
        lastFeeUpdate = block.timestamp;

        emit UpdatedPerformanceFee(_performanceFee);
    }

    /**
    * @notice Adds a new asset to the list of assets the pool can hold.
    * @param _asset Address of the asset.
    */
    function addAvailableAsset(address _asset) external override onlyManager {
        address assetHandlerAddress = addressResolver.getContractAddress("AssetHandler");

        require(IAssetHandler(assetHandlerAddress).isValidAsset(_asset), "PoolManagerLogic: Asset is not supported.");
        require(availableAssets.length < ISettings(addressResolver.getContractAddress("Settings")).getParameterValue("MaximumNumberOfPositionsInPool"), "PoolManagerLogic: Pool has too many positions.");

        for (uint256 i = 0; i < availableAssets.length; i++) {
            require(availableAssets[i] != _asset, "PoolManagerLogic: Asset already added.");
        }

        availableAssets.push(_asset);
        assets[_asset].isAvailable = true;

        emit AddedAvailableAsset(_asset);
    }

    /**
    * @notice Removes an asset from the list of assets the pool can hold.
    * @param _asset Address of the asset.
    */
    function removeAvailableAsset(address _asset) external override onlyManager {
        require(assets[_asset].isAvailable, "PoolManagerLogic: asset is not available.");

        uint256 index;
        for (index = 0; index < availableAssets.length; index++) {
            if (availableAssets[index] == _asset) {
                break;
            }
        }

        require(index < availableAssets.length, "PoolManagerLogic: Asset not found.");

        assets[_asset].isAvailable = false;
        availableAssets[index] = availableAssets[availableAssets.length.sub(1)];
        availableAssets.pop();

        _removeDepositAsset(_asset);

        emit RemovedAvailableAsset(_asset);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
    * @notice Removes the given asset from the array of deposit assets.
    * @dev Transaction will revert if the asset is not found.
    * @param _asset Address of the asset.
    */
    function _removeDepositAsset(address _asset) internal {
        uint256 index;
        for (index = 0; index < depositAssets.length; index++) {
            if (depositAssets[index] == _asset) {
                break;
            }
        }

        if (index == depositAssets.length) {
            return;
        }

        assets[_asset].useForDeposits = false;
        depositAssets[index] = depositAssets[depositAssets.length.sub(1)];
        depositAssets.pop();

        emit RemovedDepositAsset(_asset);
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
    event UpdatedPerformanceFee(uint256 newFee);
}