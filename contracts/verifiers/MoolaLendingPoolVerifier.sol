// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Libraries.
import "../libraries/Bytes.sol";

// Inheritance.
import "../interfaces/IVerifier.sol";

// Interfaces.
import "../interfaces/IAddressResolver.sol";
import "../interfaces/IAssetHandler.sol";
import "../interfaces/IMoolaAdapter.sol";

contract MoolaLendingPoolVerifier is IVerifier {
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
        bytes4 method = Bytes.getMethod(_data);

        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address moolaAdapterAddress = ADDRESS_RESOLVER.getContractAddress("MoolaAdapter");

        // Get assets.
        (address interestBearingToken, address underlyingAsset) = IMoolaAdapter(moolaAdapterAddress).getAssetsForLendingPool(_to);

        // Check if assets are supported.
        require(IAssetHandler(assetHandlerAddress).isValidAsset(interestBearingToken), "MoolaLendingPoolVerifier: Unsupported interest-bearing token.");
        require(IAssetHandler(assetHandlerAddress).isValidAsset(underlyingAsset), "MoolaLendingPoolVerifier: Unsupported underlying asset.");

        if (method == bytes4(keccak256("deposit(address,uint256,uint16)")))
        {
            // Parse transaction data.
            address reserveAsset = Bytes.convert32toAddress(Bytes.getInput(_data, 0));
            uint256 amount = uint256(Bytes.getInput(_data, 1));

            require(reserveAsset == underlyingAsset, "MoolaLendingPoolVerifier: Reserve asset is not the underlying asset.");

            emit Deposit(_pool, _to, amount);

            return (true, interestBearingToken, 5);
        }
        else if (method == bytes4(keccak256("borrow(address,uint256,uint256,uint16)")))
        {
            // Parse transaction data.
            address reserveAsset = Bytes.convert32toAddress(Bytes.getInput(_data, 0));
            uint256 amount = uint256(Bytes.getInput(_data, 1));

            require(reserveAsset == underlyingAsset, "MoolaLendingPoolVerifier: Reserve asset is not the underlying asset.");

            emit Borrow(_pool, _to, amount);

            return (true, underlyingAsset, 6);
        }
        else if (method == bytes4(keccak256("repay(address,uint256,address)")))
        {
            {
            // Parse transaction data.
            address reserveAsset = Bytes.convert32toAddress(Bytes.getInput(_data, 0));
            address onBehalfOf = Bytes.convert32toAddress(Bytes.getInput(_data, 2));

            require(reserveAsset == underlyingAsset, "MoolaLendingPoolVerifier: Reserve asset is not the underlying asset.");
            require(onBehalfOf == _pool, "MoolaLendingPoolVerifier: Must repay on behalf of pool.");
            }

            emit Repay(_pool, _to, uint256(Bytes.getInput(_data, 1)));

            return (true, address(0), 7);
        }

        return (false, address(0), 0);
    }

    /* ========== EVENTS ========== */

    event Deposit(address pool, address lendingPool, uint256 amount);
    event Borrow(address pool, address lendingPool, uint256 amount);
    event Repay(address pool, address lendingPool, uint256 amount);
}