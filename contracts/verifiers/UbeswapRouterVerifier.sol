// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Libraries.
import "../libraries/Bytes.sol";
import "../openzeppelin-solidity/contracts/SafeMath.sol";

// Inheritance.
import "../interfaces/IVerifier.sol";

// Interfaces.
import "../interfaces/IAddressResolver.sol";
import "../interfaces/IAssetHandler.sol";
import "../interfaces/IUbeswapAdapter.sol";

contract UbeswapRouterVerifier is Bytes, IVerifier {
    using SafeMath for uint256;

    IAddressResolver public immutable ADDRESS_RESOLVER;

    constructor(address _addressResolver) {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /**
    * @notice Parses the transaction data to make sure the transaction is valid.
    * @param _pool Address of the pool
    * @param _data Transaction call data
    * @return (bool, address, uint256) Whether the transaction is valid, the received asset, and the transaction type.
    */
    function verify(address _pool, address, bytes calldata _data) external override returns (bool, address, uint256) {
        bytes4 method = getMethod(_data);

        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address ubeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapAdapter");

        if (method == bytes4(keccak256("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)")))
        {
            // Parse transaction data.
            // Gets the second input (path), first item (token to swap from).
            address srcAsset = convert32toAddress(getArrayIndex(_data, 2, 0));
            // Gets second input (path), last item (token to swap to).
            address dstAsset = convert32toAddress(getArrayLast(_data, 2));
            uint256 srcAmount = uint256(getInput(_data, 0));
            address toAddress = convert32toAddress(getInput(_data, 3));

            // Check if assets are supported.
            require(IAssetHandler(assetHandlerAddress).isValidAsset(srcAsset), "UbeswapRouterVerifier: Unsupported source asset.");
            require(IAssetHandler(assetHandlerAddress).isValidAsset(dstAsset), "UbeswapRouterVerifier: Unsupported destination asset.");

            // Check if recipient is a pool.
            require(_pool == toAddress, "UbeswapRouterVerifier: Recipient is not pool.");

            emit Swap(_pool, srcAsset, dstAsset, srcAmount);

            return (true, dstAsset, 12);
        }
        else if (method == bytes4(keccak256("addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)")))
        {
            address tokenA = convert32toAddress(getInput(_data, 0));
            address tokenB = convert32toAddress(getInput(_data, 1));

            uint256 amountADesired = uint256(getInput(_data, 2));
            uint256 amountBDesired = uint256(getInput(_data, 3));

            // Check if assets are supported.
            address pair = IUbeswapAdapter(ubeswapAdapterAddress).getPair(tokenA, tokenB);
            require(IAssetHandler(assetHandlerAddress).isValidAsset(tokenA), "UbeswapRouterVerifier: Unsupported tokenA.");
            require(IAssetHandler(assetHandlerAddress).isValidAsset(tokenB), "UbeswapRouterVerifier: Unsupported tokenB.");
            require(IAssetHandler(assetHandlerAddress).isValidAsset(pair), "UbeswapRouterVerifier: Unsupported LP token.");

            address recipient = convert32toAddress(getInput(_data, 6));

            // Check if recipient is a pool.
            require(_pool == recipient, "UbeswapRouterVerifier: Recipient is not pool.");

            emit AddedLiquidity(_pool, tokenA, tokenB, pair, amountADesired, amountBDesired);

            return (true, pair, 13);
        }
        else if (method == bytes4(keccak256("removeLiquidity(address,address,uint256,uint256,uint256,address,uint256)")))
        {
            address tokenA = convert32toAddress(getInput(_data, 0));
            address tokenB = convert32toAddress(getInput(_data, 1));

            uint256 numberOfLPTokens = uint256(getInput(_data, 2));

            // Check if assets are supported.
            address pair = IUbeswapAdapter(ubeswapAdapterAddress).getPair(tokenA, tokenB);
            require(IAssetHandler(assetHandlerAddress).isValidAsset(tokenA), "UbeswapRouterVerifier: Unsupported tokenA.");
            require(IAssetHandler(assetHandlerAddress).isValidAsset(tokenB), "UbeswapRouterVerifier: Unsupported tokenB.");
            require(IAssetHandler(assetHandlerAddress).isValidAsset(pair), "UbeswapRouterVerifier: Unsupported LP token.");

            // Check if recipient is a pool.
            require(_pool == convert32toAddress(getInput(_data, 5)), "UbeswapRouterVerifier: Recipient is not pool.");

            emit RemovedLiquidity(_pool, tokenA, tokenB, pair, numberOfLPTokens);

            return (true, pair, 14);
        }

        return (false, address(0), 0);
    }

    /* ========== EVENTS ========== */

    event Swap(address pool, address srcAsset, address dstAsset, uint256 srcAmount);
    event AddedLiquidity(address pool, address tokenA, address tokenB, address pair, uint256 amountADesired, uint256 amountBDesired);
    event RemovedLiquidity(address pool, address tokenA, address tokenB, address pair, uint256 numberOfLPTokens);
}