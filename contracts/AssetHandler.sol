// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Inheritance.
import "./interfaces/IAssetHandler.sol";
import './openzeppelin-solidity/contracts/Ownable.sol';

// Interfaces.
import './interfaces/IPriceCalculator.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/IAssetVerifier.sol';

// Libraries.
import './openzeppelin-solidity/contracts/SafeMath.sol';

contract AssetHandler is IAssetHandler, Ownable {
    using SafeMath for uint256;

    IAddressResolver public ADDRESS_RESOLVER;

    // Main stablecoin used by the platform.
    address public stableCoinAddress;

    // (asset address => asset type).
    mapping (address => uint256) public assetTypes;

    // (asset type => price calculator contract address).
    mapping (uint256 => address) public assetTypeToPriceCalculator;

    // (asset type => number of assets available).
    mapping (uint256 => uint256) public numberOfAvailableAssetsForType;

    // (asset type => index => asset address).
    mapping (uint256 => mapping (uint256 => address)) public availableAssetsForType;

    constructor(address _addressResolver) Ownable() {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Given the address of an asset, returns the asset's price in USD.
    * @param _asset Address of the asset.
    * @return uint256 Price of the asset in USD.
    */
    function getUSDPrice(address _asset) external view override isValidAddress(_asset) returns (uint256) {
        require(assetTypes[_asset] > 0, "AssetHandler: asset not supported.");
        
        return IPriceCalculator(assetTypeToPriceCalculator[assetTypes[_asset]]).getUSDPrice(_asset);
    }

    /**
    * @notice Given the address of an asset, returns whether the asset is supported on Tradegen.
    * @param _asset Address of the asset.
    * @return bool Whether the asset is supported.
    */
    function isValidAsset(address _asset) external view override isValidAddress(_asset) returns (bool) {
        return (assetTypes[_asset] > 0 || _asset == stableCoinAddress);
    }

    /**
    * @notice Given an asset type, returns the address of each supported asset for the type.
    * @param _assetType Type of asset.
    * @return address[] Address of each supported asset for the type.
    */
    function getAvailableAssetsForType(uint256 _assetType) external view override returns (address[] memory) {
        require(_assetType > 0, "AssetHandler: assetType must be greater than 0.");

        uint256 numberOfAssets = numberOfAvailableAssetsForType[assetType];
        address[] memory assets = new address[](numberOfAssets);

        for (uint256 i = 0; i < numberOfAssets; i++)
        {
            assets[i] = availableAssetsForType[assetType][i];
        }

        return assets;
    }

    /**
    * @notice Returns the address of the stablecoin.
    * @return address The stable coin address.
    */
    function getStableCoinAddress() external view override returns(address) {
        return stableCoinAddress;
    }

    /**
    * @notice Given the address of an asset, returns the asset's type.
    * @param _addressToCheck Address of the asset.
    * @return uint256 Type of the asset.
    */
    function getAssetType(address _addressToCheck) external view override isValidAddress(_addressToCheck) returns (uint256) {
        return assetTypes[_addressToCheck];
    }

    /**
    * @notice Returns the pool's balance of the given asset.
    * @param _pool Address of the pool.
    * @param _asset Address of the asset.
    * @return uint256 Pool's balance of the asset.
    */
    function getBalance(address _pool, address _asset) external view override isValidAddress(_pool) isValidAddress(_asset) returns (uint256) {
        address verifier = getVerifier(_asset);

        return IAssetVerifier(verifier).getBalance(_pool, _asset);
    }

    /**
    * @notice Returns the asset's number of decimals.
    * @param _asset Address of the asset.
    * @return uint256 Number of decimals.
    */
    function getDecimals(address _asset) external view override isValidAddress(_asset) returns (uint256) {
        uint assetType = assetTypes[_asset];
        address verifier = ADDRESS_RESOLVER.assetVerifiers(assetType);

        return IAssetVerifier(verifier).getDecimals(_asset);
    }

    /**
    * @notice Given the address of an asset, returns the address of the asset's verifier.
    * @param _asset Address of the asset.
    * @return address Address of the asset's verifier.
    */
    function getVerifier(address _asset) public view override isValidAddress(_asset) returns (address) {
        uint assetType = assetTypes[_asset];

        return ADDRESS_RESOLVER.assetVerifiers(assetType);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Sets the address of the stablecoin.
    * @dev Only the owner of the AssetHandler contract can call this function.
    * @param _stableCoinAddress The address of the stablecoin.
    */
    function setStableCoinAddress(address _stableCoinAddress) external onlyOwner isValidAddress(_stableCoinAddress) {
        address oldAddress = stableCoinAddress;
        stableCoinAddress = _stableCoinAddress;
        assetTypes[_stableCoinAddress] = 1;

        emit UpdatedStableCoinAddress(oldAddress, _stableCoinAddress);
    }

    /**
    * @notice Adds a new tradable currency to the platform.
    * @dev Only the owner of the AssetHandler contract can call this function.
    * @param _assetType Type of the asset.
    * @param _currencyKey The address of the asset to add.
    */
    function addCurrencyKey(uint256 _assetType, address _currencyKey) external onlyOwner isValidAddress(_currencyKey) {
        require(_assetType > 0, "AssetHandler: assetType must be greater than 0.");
        require(_currencyKey != stableCoinAddress, "AssetHandler: Cannot equal stablecoin address.");
        require(assetTypes[_currencyKey] == 0, "AssetHandler: Asset already exists.");

        assetTypes[_currencyKey] = _assetType;
        availableAssetsForType[_assetType][numberOfAvailableAssetsForType[_assetType]] = _currencyKey;
        numberOfAvailableAssetsForType[_assetType] = numberOfAvailableAssetsForType[_assetType].add(1);

        emit AddedAsset(_assetType, _currencyKey);
    }

    /**
    * @notice Removes support for a currency.
    * @dev Only the owner of the AssetHandler contract can call this function.
    * @param _assetType Type of the asset.
    * @param _currencyKey The address of the asset to remove.
    */
    function removeCurrencyKey(uint256 _assetType, address _currencyKey) external onlyOwner isValidAddress(_currencyKey) {
        require(_assetType > 0, "AssetHandler: assetType must be greater than 0.");
        require(_currencyKey != stableCoinAddress, "AssetHandler: Cannot equal stablecoin address.");
        require(assetTypes[_currencyKey] > 0, "AssetHandler: Asset not found.");

        // Gas savings.
        uint256 numberOfAssets = numberOfAvailableAssetsForType[_assetType];
        uint256 index;

        // Search for index of currency key.
        for (index = 0; index < numberOfAssets; index++)
        {
            if (availableAssetsForType[_assetType][index] == _currencyKey) break;
        }

        require(index < numberOfAssets, "AssetHandler: Index out of bounds.");

        // Move the last element to the index of currency being removed.
        if (index < numberOfAssets)
        {
            availableAssetsForType[_assetType][index] = availableAssetsForType[_assetType][numberOfAssets.sub(1)];
        }

        delete availableAssetsForType[_assetType][numberOfAssets.sub(1)];
        delete assetTypes[_currencyKey];
        numberOfAvailableAssetsForType[_assetType] = numberOfAvailableAssetsForType[_assetType].sub(1);

        emit RemovedAsset(_assetType, _currencyKey);
    }

    /**
    * @notice Adds a new asset type.
    * @dev Only the owner of the AssetHandler contract can call this function.
    * @param _assetType Type of the asset.
    * @param _priceCalculator Address of the asset's price calculator.
    */
    function addAssetType(uint256 _assetType, address _priceCalculator) external onlyOwner isValidAddress(_priceCalculator) {
        require(_assetType > 0, "AssetHandler: assetType must be greater than 0.");
        require(assetTypeToPriceCalculator[_assetType] == address(0), "AssetHandler: asset type already exists.");

        assetTypeToPriceCalculator[_assetType] = _priceCalculator;

        emit AddedAssetType(_assetType, _priceCalculator);
    }

    /* ========== MODIFIERS ========== */

    modifier isValidAddress(address _addressToCheck) {
        require(_addressToCheck != address(0), "AssetHandler: Address is not valid.");
        _;
    }

    /* ========== EVENTS ========== */

    event AddedAsset(uint256 assetType, address currencyKey);
    event RemovedAsset(uint256 assetType, address currencyKey);
    event UpdatedStableCoinAddress(address oldAddress, address stableCurrencyAddress);
    event AddedAssetType(uint256 assetType, address priceCalculator); 
}