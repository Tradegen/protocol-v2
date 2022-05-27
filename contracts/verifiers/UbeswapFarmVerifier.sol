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
import "../interfaces/IUbeswapLPVerifier.sol";
import "../interfaces/Ubeswap/IStakingRewards.sol";

contract UbeswapFarmVerifier is Bytes, IVerifier {
    using SafeMath for uint256;

    IAddressResolver public immutable ADDRESS_RESOLVER;

    constructor(address _addressResolver) {
        ADDRESS_RESOLVER = IAddressResolver(_addressResolver);
    }

    /**
    * @notice Parses the transaction data to make sure the transaction is valid.
    * @param _pool Address of the pool
    * @param _to Address of the external contract being called.
    * @param _data Transaction call data
    * @return (bool, address, uint256) Whether the transaction is valid, the received asset, and the transaction type.
    */
    function verify(address _pool, address _to, bytes calldata _data) external override returns (bool, address, uint256) {
        bytes4 method = getMethod(_data);

        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address ubeswapLPVerifierAddress = ADDRESS_RESOLVER.assetVerifiers(2);

        // Get assets. 
        (address pair, address rewardToken) = IUbeswapLPVerifier(ubeswapLPVerifierAddress).getFarmTokens(_to);

        if (method == bytes4(keccak256("stake(uint256)")))
        {
            // Parse transaction data.
            uint256 numberOfLPTokens = uint256(getInput(_data, 0));

            // Check if assets are supported.
            require(IAssetHandler(assetHandlerAddress).isValidAsset(rewardToken), "UbeswapFarmVerifier: Unsupported reward token.");
            require(IAssetHandler(assetHandlerAddress).isValidAsset(pair), "UbeswapFarmVerifier: Unsupported liquidity pair.");

            emit Staked(_pool, _to, numberOfLPTokens);

            return (true, rewardToken, 8);
        }
        else if (method == bytes4(keccak256("withdraw(uint256)")))
        {
            // Parse transaction data.
            uint256 numberOfLPTokens = uint256(getInput(_data, 0));

            // Check if assets are supported.
            require(IAssetHandler(assetHandlerAddress).isValidAsset(pair), "UbeswapFarmVerifier: Unsupported liquidity pair.");

            emit Unstaked(_pool, _to, numberOfLPTokens);

            return (true, pair, 9);
        }
        else if (method == bytes4(keccak256("getReward()")))
        {
            // Check if assets are supported.
            require(IAssetHandler(assetHandlerAddress).isValidAsset(rewardToken), "UbeswapFarmVerifier: Unsupported reward token.");

            emit ClaimedReward(_pool, _to);

            return (true, rewardToken, 10);
        }
        else if (method == bytes4(keccak256("exit()")))
        {
            uint256 numberOfLPTokens = IStakingRewards(_to).balanceOf(_pool);

            // Check if assets are supported.
            require(IAssetHandler(assetHandlerAddress).isValidAsset(rewardToken), "UbeswapFarmVerifier: Unsupported reward token.");
            require(IAssetHandler(assetHandlerAddress).isValidAsset(pair), "UbeswapFarmVerifier: Unsupported liquidity pair.");

            emit Unstaked(_pool, _to, numberOfLPTokens);
            emit ClaimedReward(_pool, _to);

            return (true, rewardToken, 11);
        }

        return (false, address(0), 0);
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed pool, address indexed farm, uint256 numberOfLPTokens);
    event Unstaked(address indexed pool, address indexed farm, uint256 numberOfLPTokens);
    event ClaimedReward(address indexed pool, address indexed farm);
}