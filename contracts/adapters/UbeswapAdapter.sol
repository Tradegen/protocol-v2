// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

// Interfaces.
import '../interfaces/Ubeswap/IUniswapV2Router02.sol';
import '../interfaces/IERC20.sol';
import '../interfaces/IAssetHandler.sol';
import '../interfaces/IAddressResolver.sol';
import '../interfaces/IUbeswapPathManager.sol';
import '../interfaces/Ubeswap/IUbeswapPoolManager.sol';
import '../interfaces/Ubeswap/IStakingRewards.sol';
import '../interfaces/Ubeswap/IUniswapV2Factory.sol';
import '../interfaces/Ubeswap/IStakingRewards.sol';

// Inheritance.
import '../interfaces/IUbeswapAdapter.sol';

// OpenZeppelin.
import '../openzeppelin-solidity/contracts/SafeMath.sol';

contract UbeswapAdapter is IUbeswapAdapter {
    using SafeMath for uint256;

    // Max slippage percent allowed.
    // 10% slippage.
    uint256 public constant override MAX_SLIPPAGE_PERCENT = 10;

    IAddressResolver public immutable ADDRESS_RESOLVER;

    constructor(address _addressResolver) {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Given an input asset address, returns the price of the asset in USD.
    * @param _currencyKey Address of the asset.
    * @return uint Price of the asset.
    */
    function getPrice(address _currencyKey) external view override returns (uint256) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address ubeswapRouterAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapRouter");
        address stableCoinAddress = IAssetHandler(assetHandlerAddress).getStableCoinAddress();

        // Check if currency key is a stablecoin.
        // If so, return $1 as the price.
        if (_currencyKey == stableCoinAddress) {
            return 10 ** _getDecimals(_currencyKey);
        }

        require(IAssetHandler(assetHandlerAddress).isValidAsset(_currencyKey), "UbeswapAdapter: Currency is not available.");

        address ubeswapPathManagerAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapPathManager");
        address[] memory path = IUbeswapPathManager(ubeswapPathManagerAddress).getPath(_currencyKey, stableCoinAddress);
        // 1 token -> USD.
        uint256[] memory amounts = IUniswapV2Router02(ubeswapRouterAddress).getAmountsOut(10 ** _getDecimals(_currencyKey), path);

        return amounts[amounts.length - 1];
    }

    /**
    * @notice Given an input asset amount, returns the maximum output amount of the other asset.
    * @dev Assumes numberOfTokens is multiplied by currency's decimals before function call.
    * @param _numberOfTokens Number of tokens.
    * @param _currencyKeyIn Address of the asset to be swap from.
    * @param _currencyKeyOut Address of the asset to be swap to.
    * @return uint Amount out of the asset.
    */
    function getAmountsOut(uint256 _numberOfTokens, address _currencyKeyIn, address _currencyKeyOut) external view override returns (uint256) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address ubeswapRouterAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapRouter");

        require(IAssetHandler(assetHandlerAddress).isValidAsset(_currencyKeyIn), "UbeswapAdapter: CurrencyKeyIn is not available.");
        require(IAssetHandler(assetHandlerAddress).isValidAsset(_currencyKeyOut), "UbeswapAdapter: CurrencyKeyOut is not available.");
        require(_numberOfTokens > 0, "UbeswapAdapter: Number of tokens must be greater than 0.");

        address ubeswapPathManagerAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapPathManager");
        address[] memory path = IUbeswapPathManager(ubeswapPathManagerAddress).getPath(_currencyKeyIn, _currencyKeyOut);
        uint256[] memory amounts = IUniswapV2Router02(ubeswapRouterAddress).getAmountsOut(_numberOfTokens, path);

        return amounts[1];
    }

    /**
    * @notice Given the target output asset amount, returns the amount of input asset needed.
    * @param _numberOfTokens Target amount of output asset.
    * @param _currencyKeyIn Address of the asset to be swap from.
    * @param _currencyKeyOut Address of the asset to be swap to.
    * @return uint Amount out input asset needed.
    */
    function getAmountsIn(uint _numberOfTokens, address _currencyKeyIn, address _currencyKeyOut) external view override returns (uint256) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address ubeswapRouterAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapRouter");

        require(IAssetHandler(assetHandlerAddress).isValidAsset(_currencyKeyIn), "UbeswapAdapter: CurrencyKeyIn is not available.");
        require(IAssetHandler(assetHandlerAddress).isValidAsset(_currencyKeyOut), "UbeswapAdapter: CurrencyKeyOut is not available.");
        require(_numberOfTokens > 0, "UbeswapAdapter: Number of tokens must be greater than 0.");

        address ubeswapPathManagerAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapPathManager");
        address[] memory path = IUbeswapPathManager(ubeswapPathManagerAddress).getPath(_currencyKeyIn, _currencyKeyOut);
        uint256[] memory amounts = IUniswapV2Router02(ubeswapRouterAddress).getAmountsIn(_numberOfTokens, path);

        return amounts[0];
    }

    /**
    * @notice Returns the address of each available farm on Ubeswap.
    * @return address[] memory The farm address for each available farm.
    */
    function getAvailableUbeswapFarms() external view override returns (address[] memory) {
        address ubeswapPoolManagerAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapPoolManager");

        uint numberOfAvailableFarms = IUbeswapPoolManager(ubeswapPoolManagerAddress).poolsCount();
        address[] memory poolAddresses = new address[](numberOfAvailableFarms);
        address[] memory farmAddresses = new address[](numberOfAvailableFarms);

        //Get supported LP tokens
        for (uint256 i = 0; i < numberOfAvailableFarms; i++)
        {
            poolAddresses[i] = IUbeswapPoolManager(ubeswapPoolManagerAddress).poolsByIndex(i);
        }

        //Get supported farms
        for (uint256 i = 0; i < numberOfAvailableFarms; i++)
        {
            IUbeswapPoolManager.PoolInfo memory farm = IUbeswapPoolManager(ubeswapPoolManagerAddress).pools(poolAddresses[i]);
            farmAddresses[i] = farm.poolAddress;
        }

        return farmAddresses;
    }

    /**
    * @notice Returns the address of a token pair.
    * @param _tokenA First token in pair.
    * @param _tokenB Second token in pair.
    * @return address The pair's address.
    */
    function getPair(address _tokenA, address _tokenB) public view override returns (address) {
        require(_tokenA != address(0), "UbeswapAdapter: invalid address for tokenA.");
        require(_tokenB != address(0), "UbeswapAdapter: invalid address for tokenB.");

        address uniswapV2FactoryAddress = ADDRESS_RESOLVER.getContractAddress("UniswapV2Factory");

        return IUniswapV2Factory(uniswapV2FactoryAddress).getPair(_tokenA, _tokenB);
    }

    /**
    * @notice Returns the amount of UBE rewards available for the pool in the given farm.
    * @param _poolAddress Address of the pool.
    * @param _farmAddress Address of the farm on Ubeswap.
    * @return uint Amount of UBE available.
    */
    function getAvailableRewards(address _poolAddress, address _farmAddress) external view override returns (uint256) {
        require(_poolAddress != address(0), "UbeswapAdapter: invalid pool address.");

        return IStakingRewards(_farmAddress).earned(_poolAddress);
    }

    /**
    * @notice Calculates the amount of tokens in a pair.
    * @param _tokenA First token in pair.
    * @param _tokenB Second token in pair.
    * @param _numberOfLPTokens Number of LP tokens for the given pair.
    * @return (uint256, uint256) The number of tokens for _tokenA and _tokenB.
    */
    function getTokenAmountsFromPair(address _tokenA, address _tokenB, uint256 _numberOfLPTokens) external view override returns (uint256, uint256) {
        address pair = getPair(_tokenA, _tokenB);
        require(pair != address(0), "UbeswapAdapter: invalid address for pair.");

        uint256 pairBalanceTokenA = IERC20(_tokenA).balanceOf(pair);
        uint256 pairBalanceTokenB = IERC20(_tokenB).balanceOf(pair);
        uint256 totalSupply = IERC20(pair).totalSupply();

        uint256 amountA = pairBalanceTokenA.mul(_numberOfLPTokens).div(totalSupply);
        uint256 amountB = pairBalanceTokenB.mul(_numberOfLPTokens).div(totalSupply);

        return (amountA, amountB);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
    * @notice Get the decimals of an asset.
    * @dev Assumes that the given asset follows ERC20 standard.
    * @param _asset Address of the asset.
    * @return uint256 Number of decimals of the asset.
    */
    function _getDecimals(address _asset) internal view returns (uint256) {
        return IERC20(_asset).decimals();
    }
}