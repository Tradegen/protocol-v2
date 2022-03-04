// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Libraries
import "../libraries/TxDataUtils.sol";

//Inheritance
import "../interfaces/IVerifier.sol";

//Interfaces
import "../interfaces/IAddressResolver.sol";
import "../interfaces/IAssetHandler.sol";
import "../interfaces/IMoolaAdapter.sol";

contract MoolaLendingPoolVerifier is TxDataUtils, IVerifier {
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
        address moolaAdapterAddress = IAddressResolver(addressResolver).getContractAddress("MoolaAdapter");

        //Get assets 
        (address interestBearingToken, address underlyingAsset) = IMoolaAdapter(moolaAdapterAddress).getAssetsForLendingPool(to);

        //Check if assets are supported
        require(IAssetHandler(assetHandlerAddress).isValidAsset(interestBearingToken), "MoolaLendingPoolVerifier: unsupported interest-bearing token.");
        require(IAssetHandler(assetHandlerAddress).isValidAsset(underlyingAsset), "MoolaLendingPoolVerifier: unsupported underlying asset.");

        if (method == bytes4(keccak256("deposit(address,uint256,uint16)")))
        {
            //Parse transaction data
            address reserveAsset = convert32toAddress(getInput(data, 0));
            uint amount = uint(getInput(data, 1));

            require(reserveAsset == underlyingAsset, "MoolaLendingPoolVerifier: reserve asset is not the underlying asset.");

            emit Deposit(pool, to, amount);

            return (true, interestBearingToken, 5);
        }
        else if (method == bytes4(keccak256("borrow(address,uint256,uint256,uint16)")))
        {
            //Parse transaction data
            address reserveAsset = convert32toAddress(getInput(data, 0));
            uint amount = uint(getInput(data, 1));

            require(reserveAsset == underlyingAsset, "MoolaLendingPoolVerifier: reserve asset is not the underlying asset.");

            emit Borrow(pool, to, amount);

            return (true, underlyingAsset, 6);
        }
        else if (method == bytes4(keccak256("repay(address,uint256,address)")))
        {
            //Parse transaction data
            address reserveAsset = convert32toAddress(getInput(data, 0));
            uint amount = uint(getInput(data, 1));
            address onBehalfOf = convert32toAddress(getInput(data, 2));

            require(reserveAsset == underlyingAsset, "MoolaLendingPoolVerifier: reserve asset is not the underlying asset.");
            require(onBehalfOf == pool, "MoolaLendingPoolVerifier: must repay on behalf of pool.");

            emit Repay(pool, to, amount);

            return (true, address(0), 7);
        }

        return (false, address(0), 0);
    }

    /* ========== EVENTS ========== */

    event Deposit(address indexed pool, address indexed lendingPool, uint amount);
    event Borrow(address indexed pool, address indexed lendingPool, uint amount);
    event Repay(address indexed pool, address indexed lendingPool, uint amount);
}