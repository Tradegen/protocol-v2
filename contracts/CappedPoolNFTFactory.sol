// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Interfaces.
import './interfaces/IAddressResolver.sol';

// Internal references.
import './CappedPoolNFT.sol';

// Inheritance.
import './interfaces/ICappedPoolNFTFactory.sol';

contract CappedPoolNFTFactory is ICappedPoolNFTFactory {
    IAddressResolver public immutable addressResolver;

    constructor(address _addressResolver) {
        addressResolver = IAddressResolver(_addressResolver)
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Deploys a CappedPoolNFT contract and returns the contract's address.
    * @dev This function can only be called by the Registry contract.
    * @param _pool Address of the CappedPool contract.
    * @return address Address of the deployed CappedPoolNFT contract.
    */
    function createCappedPoolNFT(address _pool, uint256 _supplyCap) external override onlyRegistry returns (address) {
        address cappedPoolNFTContract = address(new CappedPoolNFT(_pool, _supplyCap));

        emit CreatedCappedPoolNFT(_pool, _supplyCap);

        return cappedPoolNFTContract;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyRegistry() {
        require(msg.sender == addressResolver.getContractAddress("Registry"),
                "CappedPoolNFTFactory: Only the Registry contract can call this function.");
        _;
    }

    /* ========== EVENTS ========== */

    event CreatedCappedPoolNFT(address pool, uint256 supplyCap);
}