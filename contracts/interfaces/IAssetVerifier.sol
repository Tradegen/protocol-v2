// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

interface IAssetVerifier {
    struct WithdrawalData {
        address withdrawalAsset;
        uint256 withdrawalAmount;
        address[] externalAddresses;
        bytes[] transactionDatas;
    }

    /**
    * @dev Creates transaction data for withdrawing tokens
    * @param pool Address of the pool
    * @param asset Address of the asset
    * @param portion Portion of the pool's balance in the asset
    * @return (WithdrawalData) A struct containing the asset withdrawn, amount of asset withdrawn, and the transactions used to execute the withdrawal.
    */
    function prepareWithdrawal(address pool, address asset, uint portion) external view returns (WithdrawalData memory);

    /**
    * @dev Returns the pool's balance in the asset
    * @param pool Address of the pool
    * @param asset Address of the asset
    * @return uint Pool's balance in the asset
    */
    function getBalance(address pool, address asset) external view returns (uint);

    /**
    * @dev Returns the decimals of the asset
    * @param asset Address of the asset
    * @return uint Asset's number of decimals
    */
    function getDecimals(address asset) external view returns (uint);
}