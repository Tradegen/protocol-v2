// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

//Interfaces
import '../interfaces/IERC20.sol';
import '../interfaces/IAssetHandler.sol';
import '../interfaces/IAddressResolver.sol';
import '../interfaces/Mobius/ISwap.sol';
import '../interfaces/Mobius/IMasterMind.sol';
import '../interfaces/IUbeswapAdapter.sol';

//Inheritance
import '../interfaces/IMoolaAdapter.sol';

//Libraries
import '../openzeppelin-solidity/contracts/SafeMath.sol';
import '../openzeppelin-solidity/contracts/Ownable.sol';

contract MoolaAdapter is IMoolaAdapter, Ownable {
    using SafeMath for uint;

    struct MoolaAsset {
        address lendingPool;
        address underlyingAsset;
    }

    IAddressResolver public immutable ADDRESS_RESOLVER;

    mapping (address => MoolaAsset) public moolaAssets; // interest-bearing token address => token info
    mapping (address => address) public equivalentMoolaAsset; //underlying asset => asset's interest-bearing token on Moola
    mapping (address => address) public lendingPools; // lending pool address => interest-bearing token address

    constructor(address _addressResolver) Ownable() {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Given an input asset address, returns the price of the asset in USD
    * @notice Returns 0 if the asset is not supported
    * @param currencyKey Address of the asset
    * @return price Price of the asset
    */
    function getPrice(address currencyKey) external view override returns (uint price) {
        require(currencyKey != address(0), "Invalid currency key");

        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address ubeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapAdapter");

        require(IAssetHandler(assetHandlerAddress).isValidAsset(currencyKey), "MoolaAdapter: Currency is not available");

        if (moolaAssets[currencyKey].lendingPool != address(0)) {
            price = IUbeswapAdapter(ubeswapAdapterAddress).getPrice(currencyKey);
        }
        else if (equivalentMoolaAsset[currencyKey] != address(0)) {
            price = IUbeswapAdapter(ubeswapAdapterAddress).getPrice(equivalentMoolaAsset[currencyKey]);
        }
        
        price = 0;
    }

    /**
    * @dev Returns the address of each lending pool available on Moola
    * @return address[] The address of each lending pool on Moola
    */
    function getAvailableMoolaLendingPools() external view override returns (address[] memory) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address[] memory interestBearingTokenAddresses = IAssetHandler(assetHandlerAddress).getAvailableAssetsForType(5);
        address[] memory lendingPoolAddresses = new address[](interestBearingTokenAddresses.length);

        //Get farm IDs
        for (uint i = 0; i < lendingPoolAddresses.length; i++)
        {
            lendingPoolAddresses[i] = moolaAssets[interestBearingTokenAddresses[i]].lendingPool;
        }

        return lendingPoolAddresses;
    }

    /**
    * @dev Checks whether the given token has a lending pool on Moola
    * @param token Address of the token
    * @return bool Whether the token has a lending pool
    */
    function checkIfTokenHasLendingPool(address token) external view override returns (bool) {
        return (getLendingPoolAddress(token) != address(0));
    }

    /**
    * @dev Returns the address of the token's lending pool contract, if it exists
    * @param token Address of the token
    * @return address Address of the token's lending pool contract
    */
    function getLendingPoolAddress(address token) public view override returns (address) {
        require(token != address(0), "MoolaAdapter: invalid address for token.");

        // Check if token is interest-bearing token
        if (moolaAssets[token].lendingPool != address(0)) {
            return moolaAssets[token].lendingPool;
        }
        // Check if token is underlying token
        else if (equivalentMoolaAsset[token] != address(0)) {
            return  moolaAssets[equivalentMoolaAsset[token]].lendingPool;
        }

        // Token is not supported
        return address(0);
    }

    /**
    * @dev Given the address of a lending pool, returns the lending pool's interest-bearing token and underlying token
    * @param lendingPoolAddress Address of the lending pool.
    * @return (address, address) Address of the lending pool's interest-bearing token and address of the underlying token
    */
    function getAssetsForLendingPool(address lendingPoolAddress) external view override returns (address, address) {
        require(lendingPoolAddress != address(0), "MoolaAdapter: invalid address for lending pool.");

        return (lendingPools[lendingPoolAddress], moolaAssets[lendingPools[lendingPoolAddress]].underlyingAsset);
    }

    /**
    * @dev Given the address of an interest-bearing token, returns the token's underlying asset
    * @param interestBearingToken Address of the interest-bearing token
    * @return address Address of the token's underlying asset
    */
    function getUnderlyingAsset(address interestBearingToken) external view override returns (address) {
        require(interestBearingToken != address(0), "MoolaAdapter: invalid address for interest-bearing token.");

        return moolaAssets[interestBearingToken].underlyingAsset;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function addMoolaAsset(address _underlyingAsset, address _interestBearingToken, address _lendingPool) external onlyOwner {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");

        require(_underlyingAsset != address(0), "MoolaAdapter: invalid underlying asset address.");
        require(_interestBearingToken != address(0), "MoolaAdapter: invalid interest-bearing token address.");
        require(_lendingPool != address(0), "MoolaAdapter: invalid lending pool address.");
        require(moolaAssets[_interestBearingToken].underlyingAsset == address(0), "MoolaAdapter: asset already exists.");
        require(IAssetHandler(assetHandlerAddress).isValidAsset(_underlyingAsset), "MoolaAdapter: underlying asset is not available");
        require(IAssetHandler(assetHandlerAddress).isValidAsset(_interestBearingToken), "MoolaAdapter: interest bearing token is not available");

        moolaAssets[_interestBearingToken] = MoolaAsset(_lendingPool, _underlyingAsset);
        equivalentMoolaAsset[_underlyingAsset] = _interestBearingToken;
        lendingPools[_lendingPool] = _interestBearingToken; 

        emit AddedMoolaAsset(_underlyingAsset, _interestBearingToken, _lendingPool);
    }

    /* ========== EVENTS ========== */

    event AddedMoolaAsset(address underlyingAsset, address interestBearingToken, address lendingPool);
}