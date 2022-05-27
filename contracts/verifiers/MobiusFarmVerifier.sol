// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Libraries.
import "../libraries/TxDataUtils.sol";

// Inheritance.
import "../interfaces/IVerifier.sol";

// Interfaces.
import "../interfaces/IAddressResolver.sol";
import "../interfaces/IAssetHandler.sol";
import "../interfaces/IMobiusLPVerifier.sol";

contract MobiusFarmVerifier is TxDataUtils, IVerifier {
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
        address mobiusLPVerifierAddress = ADDRESS_RESOLVER.assetVerifiers(3);

        // Get assets.
        (, address rewardToken) = IMobiusLPVerifier(mobiusLPVerifierAddress).getFarmID(_to);

        // Check if assets are supported.
        require(IAssetHandler(assetHandlerAddress).isValidAsset(rewardToken), "MobiusFarmVerifier: Unsupported reward token.");
        require(IAssetHandler(assetHandlerAddress).isValidAsset(_to), "MobiusFarmVerifier: Unsupported liquidity pair.");

        if (method == bytes4(keccak256("deposit(uint256,uint256)")))
        {
            // Parse transaction data.
            uint256 numberOfLPTokens = uint256(getInput(_data, 0));

            emit Staked(_pool, _to, numberOfLPTokens);

            return (true, rewardToken, 3);
        }
        else if (method == bytes4(keccak256("withdraw(uint256,uint256)")))
        {
            // Parse transaction data.
            uint256 numberOfLPTokens = uint256(getInput(_data, 0));

            emit Unstaked(pool, _to, numberOfLPTokens);

            return (true, _to, 4);
        }

        return (false, address(0), 0);
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed pool, address indexed stakingToken, uint256 numberOfLPTokens);
    event Unstaked(address indexed pool, address indexed stakingToken, uint256 numberOfLPTokens);
}