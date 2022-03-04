// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IVerifier {
    /**
    * @dev Parses the transaction data to make sure the transaction is valid
    * @param addressResolver Address of AddressResolver contract
    * @param pool Address of the pool
    * @param to External contract address
    * @param data Transaction call data
    * @return (bool, address, uint) Whether the transaction is valid, the received asset, and the transaction type.
    */
    function verify(address addressResolver, address pool, address to, bytes calldata data) external returns (bool, address, uint);

    event ExchangeFrom(address fundAddress, address sourceAsset, uint sourceAmount, address destinationAsset);
}