// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Libraries
import "../libraries/TxDataUtils.sol";

//Inheritance
import "../interfaces/IVerifier.sol";

//Interfaces
import "../interfaces/IAddressResolver.sol";
import "../interfaces/IAssetHandler.sol";
import "../interfaces/IMobiusLPVerifier.sol";

contract MobiusFarmVerifier is TxDataUtils, IVerifier {
    /**
    * @dev Parses the transaction data to make sure the transaction is valid
    * @param addressResolver Address of AddressResolver contract
    * @param pool Address of the pool
    * @param to External contract address; use staking token address for Mobius farms, since all farms are stored in one MasterMind contract
    * @param data Transaction call data
    * @return (uint, address) Whether the transaction is valid and the received asset
    */
    function verify(address addressResolver, address pool, address to, bytes calldata data) external override returns (bool, address) {
        bytes4 method = getMethod(data);

        address assetHandlerAddress = IAddressResolver(addressResolver).getContractAddress("AssetHandler");
        address mobiusLPVerifierAddress = IAddressResolver(addressResolver).assetVerifiers(3);

        //Get assets 
        (, address rewardToken) = IMobiusLPVerifier(mobiusLPVerifierAddress).getFarmID(to);

        //Check if assets are supported
        require(IAssetHandler(assetHandlerAddress).isValidAsset(rewardToken), "MobiusFarmVerifier: unsupported reward token");
        require(IAssetHandler(assetHandlerAddress).isValidAsset(to), "MobiusFarmVerifier: unsupported liquidity pair");

        if (method == bytes4(keccak256("deposit(uint256,uint256)")))
        {
            //Parse transaction data
            uint numberOfLPTokens = uint(getInput(data, 0));

            emit Staked(pool, to, numberOfLPTokens);

            return (true, rewardToken);
        }
        else if (method == bytes4(keccak256("withdraw(uint256,uint256)")))
        {
            //Parse transaction data
            uint numberOfLPTokens = uint(getInput(data, 0));

            emit Unstaked(pool, to, numberOfLPTokens);

            return (true, to);
        }

        return (false, address(0));
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed pool, address indexed stakingToken, uint numberOfLPTokens);
    event Unstaked(address indexed pool, address indexed stakingToken, uint numberOfLPTokens);
}