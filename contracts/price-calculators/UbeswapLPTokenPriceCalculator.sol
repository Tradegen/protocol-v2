// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Inheritance.
import '../interfaces/IPriceCalculator.sol';

// Interfaces.
import '../interfaces/IUbeswapAdapter.sol';
import '../interfaces/IAddressResolver.sol';
import '../interfaces/IERC20.sol';

// Ubeswap interfaces.
import '../interfaces/Ubeswap/IUniswapV2Pair.sol';

// Libraries.
import "../libraries/TradegenMath.sol";
import "../openzeppelin-solidity/contracts/SafeMath.sol";

contract UbeswapLPTokenPriceCalculator is IPriceCalculator {
    using SafeMath for uint256;

    IAddressResolver public ADDRESS_RESOLVER;

    constructor(address _addressResolver) {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the USD price of the given LP token.
    * @param _pair Address of the LP token.
    * @return uint256 USD price of the LP token.
    */
    function getUSDPrice(address _pair) external view override returns (uint256) {
        require(_pair != address(0), "UbeswapLPTokenPriceCalculator: Invalid LP token address.");

        // Define 'r' here so 'reserve0' and 'reserve1' can be scoped.
        // This prevents 'stack-too-deep' error.
        uint256 r;

        address token0 = IUniswapV2Pair(_pair).token0();
        address token1 = IUniswapV2Pair(_pair).token1();
        
        {
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_pair).getReserves();

        reserve0 = uint256(reserve0).mul(10**18).div(10**uint256(IERC20(token0).decimals()));
        reserve1 = uint256(reserve1).mul(10**18).div(10**uint256(IERC20(token1).decimals()));

        r = TradegenMath.sqrt(reserve0.mul(reserve1));
        }

        address ubeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapAdapter");
        uint256 price0 = IUbeswapAdapter(ubeswapAdapterAddress).getPrice(token0);
        uint256 price1 = IUbeswapAdapter(ubeswapAdapterAddress).getPrice(token1);

        return r.mul(TradegenMath.sqrt(price0.mul(price1))).mul(2).div(IUniswapV2Pair(_pair).totalSupply());
    }
}