// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface ICappedPoolNFTFactory {

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Deploys a CappedPoolNFT contract and returns the contract's address.
    * @dev This function can only be called by the Registry contract.
    * @param _pool Address of the CappedPool contract.
    * @return address Address of the deployed CappedPoolNFT contract.
    */
    function createCappedPoolNFT(address _pool, uint256 _supplyCap) external returns (address);
}