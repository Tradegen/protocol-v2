// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

// Interfaces.
import '../interfaces/IERC20.sol';
import '../interfaces/IAssetHandler.sol';
import '../interfaces/IAddressResolver.sol';
import '../interfaces/Mobius/ISwap.sol';
import '../interfaces/Mobius/IMasterMind.sol';
import '../interfaces/IUbeswapAdapter.sol';

// Inheritance.
import '../interfaces/IMobiusAdapter.sol';

// OpenZeppelin.
import '../openzeppelin-solidity/contracts/SafeMath.sol';
import '../openzeppelin-solidity/contracts/Ownable.sol';

contract MobiusAdapter is IMobiusAdapter, Ownable {
    using SafeMath for uint256;

    struct MobiusAsset {
        address stakingToken;
        address denominationAsset;
        address swapAddress;
        uint256 pid;
    }

    IAddressResolver public immutable ADDRESS_RESOLVER;

    // (address of Mobius asset => Mobius asset info).
    mapping (address => MobiusAsset) public mobiusAssets;

    // (denomination asset => similar asset on Ubeswap).
    // Ex) USDC => cUSD.
    // This mapping is used for calculating the price of an asset on Mobius.
    mapping (address => address) public equivalentUbeswapAsset;

    // (asset, asset) LP pair => address of Swap contract.
    mapping (address => mapping(address => address)) public swapAddresses;

    // (Mobius pair => Mobius asset).
    mapping (address => address) public pairToAsset;

    constructor(address _addressResolver) Ownable() {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the address of the LP token's Swap contract.
    * @param _pair Address of the liquidity pair.
    * @return address Address of the LP token's Swap contract.
    */
    function getSwapAddress(address _pair) external view override returns (address) {
        return mobiusAssets[pairToAsset[_pair]].swapAddress;
    }

    /**
    * @notice Given an input asset address, returns the price of the asset in USD.
    * @param _currencyKey Address of the asset.
    * @return price Price of the asset.
    */
    function getPrice(address _currencyKey) external view override returns(uint256 price) {
        require(_currencyKey != address(0), "MobiusAdapter: Invalid currency key.");

        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address ubeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapAdapter");

        require(IAssetHandler(assetHandlerAddress).isValidAsset(_currencyKey), "MobiusAdapter: Currency is not available.");

        // Get the price of the denomination asset on Ubeswap.
        // This assumes that the denomination asset is pegged to the equivalent Ubeswap asset.
        price = IUbeswapAdapter(ubeswapAdapterAddress).getPrice(equivalentUbeswapAsset[mobiusAssets[_currencyKey].denominationAsset]);

        // Get the (asset/denomination) price on Mobius and divide by
        // the price of the denomination asset.
        uint256 mobiusPrice = ISwap(mobiusAssets[_currencyKey].swapAddress).getVirtualPrice();
        price = price.mul(mobiusPrice).div(10 ** 18);
    }

    /**
    * @notice Returns the staking token address for each available farm on Mobius.
    * @return (address[], uint256[]) The staking token address and farm ID for each available farm.
    */
    function getAvailableMobiusFarms() external view override returns (address[] memory, uint256[] memory) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address[] memory assetAddresses = IAssetHandler(assetHandlerAddress).getAvailableAssetsForType(3);
        address[] memory stakingTokenAddresses = new address[](assetAddresses.length);
        uint256[] memory farmIDs = new uint256[](assetAddresses.length);

        //Get farm IDs.
        for (uint256 i = 0; i < assetAddresses.length; i++) {
            stakingTokenAddresses[i] = mobiusAssets[assetAddresses[i]].stakingToken;
            farmIDs[i] = mobiusAssets[assetAddresses[i]].pid;
        }

        return (stakingTokenAddresses, farmIDs);
    }

    /**
    * @notice Checks whether the given liquidity pair has a farm on Mobius.
    * @param _pair Address of the liquidity pair.
    * @return bool Whether the pair has a farm.
    */
    function checkIfLPTokenHasFarm(address _pair) external view override returns (bool) {
        return (mobiusAssets[pairToAsset[_pair]].stakingToken != address(0));
    }

    /**
    * @notice Returns the address of a token pair.
    * @param _tokenA First token in pair.
    * @param _tokenB Second token in pair.
    * @return address The pair's address.
    */
    function getPair(address _tokenA, address _tokenB) public view override returns (address) {
        address swapAddress = swapAddresses[_tokenA][_tokenB];

        require(swapAddress != address(0), "MobiusAdapter: Swap address for token pair not found.");

        return ISwap(swapAddress).getLpToken();
    }

    /**
    * @notice Returns the amount of MOBI rewards available for the pool in the given farm.
    * @param _poolAddress Address of the pool.
    * @param _pid ID of the farm on Mobius.
    * @return uint256 Amount of MOBI available.
    */
    function getAvailableRewards(address _poolAddress, uint256 _pid) external view override returns (uint256) {
        require(_poolAddress != address(0), "MobiusAdapter: Invalid pool address.");
        require(_pid >= 0, "MobiusAdapter: _pid must be positive.");

        address masterMindAddress = ADDRESS_RESOLVER.getContractAddress("MobiusMasterMind");

        return IMasterMind(masterMindAddress).pendingNerve(_pid, _poolAddress);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Adds support for a new Mobius asset to the platform.
    * @dev Only the contract owner can call this function.
    * @param _asset Address of the asset.
    * @param _stakingToken Address of the asset's LP token.
    * @param _denominationAsset Address of the asset the Mobius asset is priced in.
    * @param _swapAddress Address of the Mobius Swap contract for the given asset.
    * @param _pid The pool ID assigned to the given asset.
    */
    function addMobiusAsset(address _asset, address _stakingToken, address _denominationAsset, address _swapAddress, uint256 _pid) external onlyOwner {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");

        require(_asset != address(0), "MobiusAdapter: Invalid asset address.");
        require(_stakingToken != address(0), "MobiusAdapter: Invalid staking token address.");
        require(_denominationAsset != address(0), "MobiusAdapter: Invalid denomination asset address.");
        require(_swapAddress != address(0), "MobiusAdapter: Invalid swap address.");
        require(_pid >= 0, "MobiusAdapter: _pid must be positive.");
        require(mobiusAssets[_asset].stakingToken == address(0), "MobiusAdapter: Asset already exists.");
        require(IAssetHandler(assetHandlerAddress).isValidAsset(_denominationAsset), "MobiusAdapter: Denomination asset is not available.");
        require(IAssetHandler(assetHandlerAddress).isValidAsset(_asset), "MobiusAdapter: Asset is not available.");

        mobiusAssets[_asset] = MobiusAsset({
            stakingToken: _stakingToken,
            denominationAsset: _denominationAsset,
            swapAddress: _swapAddress,
            pid: _pid
        });

        swapAddresses[_denominationAsset][_asset] = _swapAddress;
        swapAddresses[_asset][_denominationAsset] = _swapAddress;
        pairToAsset[_stakingToken] = _asset;

        emit AddedMobiusAsset(_asset, _stakingToken, _denominationAsset, _swapAddress, _pid);
    }

    /**
    * @notice Sets the equivalent Ubeswap asset for the given asset.
    * @dev Using an equivalent asset helps to calculate the price of the Mobius asset
    *      by assuming the denomination asset is pegged to the Ubeswap asset.
    * @dev Only the contract owner can call this function.
    * @param _denominationAsset Address of the asset the Mobius asset is priced in.
    * @param _ubeswapAsset Address of a similar asset on Ubeswap.
    *                           Ex) Ubeswap asset for USDC would be cUSD.
    */
    function setEquivalentUbeswapAsset(address _denominationAsset, address _ubeswapAsset) external onlyOwner {
        require(_denominationAsset != address(0), "MobiusAdapter: Invalid denomination asset address.");
        require(_ubeswapAsset != address(0), "MobiusAdapter: Invalid Ubeswap asset address.");

        equivalentUbeswapAsset[_denominationAsset] = _ubeswapAsset;

        emit SetEquivalentUbeswapAsset(_denominationAsset, _ubeswapAsset);
    }

    /* ========== EVENTS ========== */

    event AddedMobiusAsset(address asset, address stakingToken, address denominationAsset, address swapAddress, uint256 pid);
    event SetEquivalentUbeswapAsset(address denominationAsset, address ubeswapAsset);
}