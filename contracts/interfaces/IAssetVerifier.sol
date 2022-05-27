// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

interface IAssetVerifier {
    struct WithdrawalData {
        address withdrawalAsset;
        uint256 withdrawalAmount;
        address[] externalAddresses;
        bytes[] transactionDatas;
    }

    /**
    * @notice Creates transaction data for withdrawing tokens.
    * @param _pool Address of the pool.
    * @param _asset Address of the asset.
    * @param _portion Portion of the pool's balance in the asset.
    * @return (WithdrawalData) A struct containing the asset withdrawn, amount of asset withdrawn, and the transactions used to execute the withdrawal.
    */
    function prepareWithdrawal(address _pool, address _asset, uint256 _portion) external view returns (WithdrawalData memory);

    /**
    * @notice Returns the pool's balance in the asset.
    * @param _pool Address of the pool.
    * @param _asset Address of the asset.
    * @return uint256 Pool's balance in the asset.
    */
    function getBalance(address _pool, address _asset) external view returns (uint256);

    /**
    * @notice Returns the decimals of the asset.
    * @param _asset Address of the asset.
    * @return uint256 Asset's number of decimals.
    */
    function getDecimals(address _asset) external view returns (uint256);
}