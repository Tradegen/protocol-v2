// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Libraries
import "../libraries/TxDataUtils.sol";
import "../openzeppelin-solidity/contracts/SafeMath.sol";

//Inheritance
import "../interfaces/IVerifier.sol";

//Interfaces
import "../interfaces/IAddressResolver.sol";
import "../interfaces/IAssetHandler.sol";
import "../interfaces/IUbeswapLPVerifier.sol";
import "../interfaces/Ubeswap/IStakingRewards.sol";

contract UbeswapFarmVerifier is TxDataUtils, IVerifier {
    using SafeMath for uint;

    /**
    * @dev Parses the transaction data to make sure the transaction is valid
    * @param addressResolver Address of AddressResolver contract
    * @param pool Address of the pool
    * @param to External contract address
    * @param data Transaction call data
    * @return (bool, address, uint) Whether the transaction is valid, the received asset, and the transaction type.
    */
    function verify(address addressResolver, address pool, address to, bytes calldata data) external override returns (bool, address, uint) {
        bytes4 method = getMethod(data);

        address assetHandlerAddress = IAddressResolver(addressResolver).getContractAddress("AssetHandler");
        address ubeswapLPVerifierAddress = IAddressResolver(addressResolver).assetVerifiers(2);

        //Get assets 
        (address pair, address rewardToken) = IUbeswapLPVerifier(ubeswapLPVerifierAddress).getFarmTokens(to);

        if (method == bytes4(keccak256("stake(uint256)")))
        {
            //Parse transaction data
            uint numberOfLPTokens = uint(getInput(data, 0));

            //Check if assets are supported
            require(IAssetHandler(assetHandlerAddress).isValidAsset(rewardToken), "UbeswapFarmVerifier: unsupported reward token");
            require(IAssetHandler(assetHandlerAddress).isValidAsset(pair), "UbeswapFarmVerifier: unsupported liquidity pair");

            emit Staked(pool, to, numberOfLPTokens);

            return (true, rewardToken, 8);
        }
        else if (method == bytes4(keccak256("withdraw(uint256)")))
        {
            //Parse transaction data
            uint numberOfLPTokens = uint(getInput(data, 0));

            //Check if assets are supported
            require(IAssetHandler(assetHandlerAddress).isValidAsset(pair), "UbeswapFarmVerifier: unsupported liquidity pair");

            emit Unstaked(pool, to, numberOfLPTokens);

            return (true, pair, 9);
        }
        else if (method == bytes4(keccak256("getReward()")))
        {
            //Check if assets are supported
            require(IAssetHandler(assetHandlerAddress).isValidAsset(rewardToken), "UbeswapFarmVerifier: unsupported reward token");

            emit ClaimedReward(pool, to);

            return (true, rewardToken, 10);
        }
        else if (method == bytes4(keccak256("exit()")))
        {
            uint numberOfLPTokens = IStakingRewards(to).balanceOf(pool);

            //Check if assets are supported
            require(IAssetHandler(assetHandlerAddress).isValidAsset(rewardToken), "UbeswapFarmVerifier: unsupported reward token");
            require(IAssetHandler(assetHandlerAddress).isValidAsset(pair), "UbeswapFarmVerifier: unsupported liquidity pair");

            emit Unstaked(pool, to, numberOfLPTokens);
            emit ClaimedReward(pool, to);

            return (true, rewardToken, 11);
        }

        return (false, address(0), 0);
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed pool, address indexed farm, uint numberOfLPTokens);
    event Unstaked(address indexed pool, address indexed farm, uint numberOfLPTokens);
    event ClaimedReward(address indexed pool, address indexed farm);
}