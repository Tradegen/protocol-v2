// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

// Interfaces.
import '../interfaces/IERC20.sol';
import '../interfaces/IAssetHandler.sol';
import '../interfaces/IAddressResolver.sol';
import '../interfaces/IUbeswapAdapter.sol';

// Inheritance.
import '../interfaces/IMoolaAdapter.sol';

// OpenZeppelin.
import '../openzeppelin-solidity/contracts/SafeMath.sol';
import '../openzeppelin-solidity/contracts/Ownable.sol';

contract MoolaAdapter is IMoolaAdapter, Ownable {
    using SafeMath for uint256;

    struct MoolaAsset {
        address lendingPool;
        address underlyingAsset;
    }

    IAddressResolver public immutable ADDRESS_RESOLVER;

    // (interest-bearing token address => token info).
    mapping (address => MoolaAsset) public moolaAssets;

    // (underlying asset => asset's interest-bearing token on Moola).
    mapping (address => address) public equivalentMoolaAsset; 

    // (lending pool address => interest-bearing token address).
    mapping (address => address) public lendingPools; 

    constructor(address _addressResolver) Ownable() {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Given an input asset address, returns the price of the asset in USD.
    * @dev Returns 0 if the asset is not supported.
    * @param _currencyKey Address of the asset.
    * @return price Price of the asset.
    */
    function getPrice(address _currencyKey) external view override returns (uint256 price) {
        require(_currencyKey != address(0), "MoolaAdapter: Invalid currency key.");

        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address ubeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapAdapter");

        require(IAssetHandler(assetHandlerAddress).isValidAsset(_currencyKey), "MoolaAdapter: Currency is not available.");

        // Check if [_currencyKey] is a Moola interest-bearing token.
        if (moolaAssets[_currencyKey].lendingPool != address(0)) {
            price = IUbeswapAdapter(ubeswapAdapterAddress).getPrice(_currencyKey);
        }
        // Check if [_currencyKey] is the underlying asset for a Moola token (ex. cUSD).
        else if (equivalentMoolaAsset[_currencyKey] != address(0)) {
            price = IUbeswapAdapter(ubeswapAdapterAddress).getPrice(equivalentMoolaAsset[_currencyKey]);
        }
    }

    /**
    * @notice Returns the address of each lending pool available on Moola.
    * @return address[] The address of each lending pool on Moola.
    */
    function getAvailableMoolaLendingPools() external view override returns (address[] memory) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address[] memory interestBearingTokenAddresses = IAssetHandler(assetHandlerAddress).getAvailableAssetsForType(5);
        address[] memory lendingPoolAddresses = new address[](interestBearingTokenAddresses.length);

        // Get lending pool address of each supported Moola asset.
        for (uint256 i = 0; i < lendingPoolAddresses.length; i++)
        {
            lendingPoolAddresses[i] = moolaAssets[interestBearingTokenAddresses[i]].lendingPool;
        }

        return lendingPoolAddresses;
    }

    /**
    * @notice Checks whether the given token has a lending pool on Moola.
    * @param _token Address of the token.
    * @return bool Whether the token has a lending pool.
    */
    function checkIfTokenHasLendingPool(address _token) external view override returns (bool) {
        return (getLendingPoolAddress(_token) != address(0));
    }

    /**
    * @notice Returns the address of the token's lending pool contract, if it exists.
    * @dev Returns address(0) if the token is not supported.
    * @param _token Address of the token.
    * @return address Address of the token's lending pool contract.
    */
    function getLendingPoolAddress(address _token) public view override returns (address) {
        require(_token != address(0), "MoolaAdapter: Invalid address for token.");

        // Check if token is interest-bearing token.
        if (moolaAssets[_token].lendingPool != address(0)) {
            return moolaAssets[_token].lendingPool;
        }
        // Check if token is underlying token.
        else if (equivalentMoolaAsset[_token] != address(0)) {
            return  moolaAssets[equivalentMoolaAsset[_token]].lendingPool;
        }

        // Token is not supported.
        return address(0);
    }

    /**
    * @notice Given the address of a lending pool, returns the lending pool's interest-bearing token and underlying token.
    * @param _lendingPoolAddress Address of the lending pool.
    * @return (address, address) Address of the lending pool's interest-bearing token and address of the underlying token.
    */
    function getAssetsForLendingPool(address _lendingPoolAddress) external view override returns (address, address) {
        require(_lendingPoolAddress != address(0), "MoolaAdapter: Invalid address for lending pool.");

        return (lendingPools[_lendingPoolAddress], moolaAssets[lendingPools[_lendingPoolAddress]].underlyingAsset);
    }

    /**
    * @notice Given the address of an interest-bearing token, returns the token's underlying asset.
    * @param _interestBearingToken Address of the interest-bearing token.
    * @return address Address of the token's underlying asset.
    */
    function getUnderlyingAsset(address _interestBearingToken) external view override returns (address) {
        require(_interestBearingToken != address(0), "MoolaAdapter: Invalid address for interest-bearing token.");

        return moolaAssets[_interestBearingToken].underlyingAsset;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Adds support for a new Moola asset to the platform.
    * @dev Only the contract owner can call this function.
    * @param _underlyingAsset Address of the underlying asset.
    *                         Ex) CELO.
    * @param _interestBearingToken Address of the interest-bearing token associated with the underlying asset.
    *                              Ex) mCELO.
    * @param _lendingPool Address of the lending pool for the given asset.
    */
    function addMoolaAsset(address _underlyingAsset, address _interestBearingToken, address _lendingPool) external onlyOwner {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");

        require(_underlyingAsset != address(0), "MoolaAdapter: Invalid underlying asset address.");
        require(_interestBearingToken != address(0), "MoolaAdapter: Invalid interest-bearing token address.");
        require(_lendingPool != address(0), "MoolaAdapter: Invalid lending pool address.");
        require(moolaAssets[_interestBearingToken].underlyingAsset == address(0), "MoolaAdapter: Asset already exists.");
        require(IAssetHandler(assetHandlerAddress).isValidAsset(_underlyingAsset), "MoolaAdapter: Underlying asset is not available.");
        require(IAssetHandler(assetHandlerAddress).isValidAsset(_interestBearingToken), "MoolaAdapter: Interest bearing token is not available.");

        moolaAssets[_interestBearingToken] = MoolaAsset(_lendingPool, _underlyingAsset);
        equivalentMoolaAsset[_underlyingAsset] = _interestBearingToken;
        lendingPools[_lendingPool] = _interestBearingToken; 

        emit AddedMoolaAsset(_underlyingAsset, _interestBearingToken, _lendingPool);
    }

    /* ========== EVENTS ========== */

    event AddedMoolaAsset(address underlyingAsset, address interestBearingToken, address lendingPool);
}