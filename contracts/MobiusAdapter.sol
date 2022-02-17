// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

//Interfaces
import './interfaces/IERC20.sol';
import './interfaces/IAssetHandler.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/Mobius/ISwap.sol';
import './interfaces/Mobius/IMasterMind.sol';
import './interfaces/IBaseUbeswapAdapter.sol';

//Inheritance
import './interfaces/IMobiusAdapter.sol';

//Libraries
import './openzeppelin-solidity/contracts/SafeMath.sol';
import './openzeppelin-solidity/contracts/Ownable.sol';

contract MobiusAdapter is IMobiusAdapter, Ownable {
    using SafeMath for uint;

    struct MobiusAsset {
        address stakingToken;
        address denominationAsset;
        address swapAddress;
        uint pid;
    }

    IAddressResolver public immutable ADDRESS_RESOLVER;

    mapping (address => MobiusAsset) public mobiusAssets;
    mapping (address => address) public equivalentUbeswapAsset; //denomination asset => similar asset on Ubeswap
    mapping (address => mapping(address => address)) public swapAddresses; //(asset, asset) LP pair => address of Swap contract

    constructor(address _addressResolver) Ownable() {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Returns the address of the LP token's Swap contract
    * @param pair Address of the liquidity pair
    * @return address Address of the LP token's Swap contract
    */
    function getSwapAddress(address pair) external view override returns (address) {
        require(pair != address(0), "MobiusAdapter: invalid pair address");

        return mobiusAssets[pair].swapAddress;
    }

    /**
    * @dev Given an input asset address, returns the price of the asset in USD
    * @param currencyKey Address of the asset
    * @return price Price of the asset
    */
    function getPrice(address currencyKey) external view override returns(uint price) {
        require(currencyKey != address(0), "Invalid currency key");

        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address ubeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("BaseUbeswapAdapter");

        require(IAssetHandler(assetHandlerAddress).isValidAsset(currencyKey), "MobiusAdapter: Currency is not available");

        price = IBaseUbeswapAdapter(ubeswapAdapterAddress).getPrice(equivalentUbeswapAsset[mobiusAssets[currencyKey].denominationAsset]);

        if (mobiusAssets[currencyKey].denominationAsset != currencyKey) {
            uint mobiusPrice = ISwap(mobiusAssets[currencyKey].swapAddress).getVirtualPrice();
            price = price.mul(mobiusPrice).div(10 ** 18);
        }
    }

    /**
    * @dev Returns the staking token address for each available farm on Mobius
    * @return (address[], uint[]) The staking token address and farm ID for each available farm
    */
    function getAvailableMobiusFarms() external view override returns (address[] memory, uint[] memory) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address[] memory assetAddresses = IAssetHandler(assetHandlerAddress).getAvailableAssetsForType(3);
        address[] memory stakingTokenAddresses = new address[](assetAddresses.length);
        uint[] memory farmIDs = new uint[](assetAddresses.length);

        //Get farm IDs
        for (uint i = 0; i < assetAddresses.length; i++)
        {
            stakingTokenAddresses[i] = mobiusAssets[assetAddresses[i]].stakingToken;
            farmIDs[i] = mobiusAssets[assetAddresses[i]].pid;
        }

        return (stakingTokenAddresses, farmIDs);
    }

    /**
    * @dev Checks whether the given liquidity pair has a farm on Mobius
    * @param pair Address of the liquidity pair
    * @return bool Whether the pair has a farm
    */
    function checkIfLPTokenHasFarm(address pair) external view override returns (bool) {
        require(pair != address(0), "MobiusAdapter: invalid pair address");

        return (mobiusAssets[pair].stakingToken != address(0));
    }

    /**
    * @dev Returns the address of a token pair
    * @param tokenA First token in pair
    * @param tokenB Second token in pair
    * @return address The pair's address
    */
    function getPair(address tokenA, address tokenB) public view override returns (address) {
        require(tokenA != address(0), "MobiusAdapter: invalid address for tokenA");
        require(tokenB != address(0), "MobiusAdapter: invalid address for tokenB");

        address swapAddress = swapAddresses[tokenA][tokenB];

        require(swapAddress != address(0), "MobiusAdapter: swap address for token pair not found.");

        return ISwap(swapAddress).getLpToken();
    }

    /**
    * @dev Returns the amount of MOBI rewards available for the pool in the given farm
    * @param poolAddress Address of the pool
    * @param pid ID of the farm on Mobius
    * @return uint Amount of MOBI available
    */
    function getAvailableRewards(address poolAddress, uint pid) external view override returns (uint) {
        require(poolAddress != address(0), "MobiusAdapter: invalid pool address");
        require(pid >= 0, "MobiusAdapter: pid must be positive.");

        address masterMindAddress = ADDRESS_RESOLVER.getContractAddress("MobiusMasterMind");

        return IMasterMind(masterMindAddress).pendingNerve(pid, poolAddress);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function addMobiusAsset(address _asset, address _stakingToken, address _denominationAsset, address _swapAddress, uint _pid) external onlyOwner {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");

        require(_asset != address(0), "MobiusAdapter: invalid asset address.");
        require(_stakingToken != address(0), "MobiusAdapter: invalid staking token address.");
        require(_denominationAsset != address(0), "MobiusAdapter: invalid denomination asset address.");
        require(_swapAddress != address(0), "MobiusAdapter: invalid swap address.");
        require(_pid >= 0, "MobiusAdapter: pid must be positive.");
        require(mobiusAssets[_asset].stakingToken == address(0), "MobiusAdapter: asset already exists.");
        require(IAssetHandler(assetHandlerAddress).isValidAsset(_denominationAsset), "MobiusAdapter: denomination asset is not available");
        require(IAssetHandler(assetHandlerAddress).isValidAsset(_asset), "MobiusAdapter: asset is not available");

        mobiusAssets[_asset] = MobiusAsset(_stakingToken, _denominationAsset, _swapAddress, _pid);
        swapAddresses[_denominationAsset][_asset] = _swapAddress;
        swapAddresses[_asset][_denominationAsset] = _swapAddress;

        emit AddedMobiusAsset(_asset, _stakingToken, _denominationAsset, _swapAddress, _pid);
    }

    function setEquivalentUbeswapAsset(address _denominationAsset, address _ubeswapAsset) external onlyOwner {
        require(_denominationAsset != address(0), "MobiusAdapter: invalid denomination asset address.");
        require(_ubeswapAsset != address(0), "MobiusAdapter: invalid denomination asset address.");

        equivalentUbeswapAsset[_denominationAsset] = _ubeswapAsset;

        emit SetEquivalentUbeswapAsset(_denominationAsset, _ubeswapAsset);
    }

    /* ========== EVENTS ========== */

    event AddedMobiusAsset(address asset, address stakingToken, address denominationAsset, address swapAddress, uint pid);
    event SetEquivalentUbeswapAsset(address denominationAsset, address ubeswapAsset);
}