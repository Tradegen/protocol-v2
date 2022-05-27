// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IVerifier {
    /**
    * @notice Parses the transaction data to make sure the transaction is valid.
    * @param _pool Address of the pool
    * @param _to Address of the external contract being called.
    * @param _data Transaction call data
    * @return (bool, address, uint) Whether the transaction is valid, the received asset, and the transaction type.
    */
    function verify(address _pool, address _to, bytes calldata _data) external returns (bool, address, uint256);

    event ExchangeFrom(address fundAddress, address sourceAsset, uint256 sourceAmount, address destinationAsset);
}